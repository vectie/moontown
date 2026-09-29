///|
/// MoonTown may schedule Code work, but MoonClaw owns the turn and execution.
/// The private control credential is read only by the daemon and never enters
/// a schedule record or desktop response.
priv struct CodeControlConfig {
  protocol_version : Int
  instance_id : String
  auth_token : String
  workspace_id : String
  workspace_root : String
} derive(FromJson)

///|
fn code_control_hex(value : String, length : Int) -> Bool {
  value.length() == length &&
  value.all(ch => ch.is_ascii_digit() || (ch >= 'a' && ch <= 'f'))
}

///|
async fn load_code_control_config() -> CodeControlConfig? {
  guard @env.get_env_var("HOME") is Some(home) && home != "" else {
    return None
  }
  let root = @pathx.normalize(
    @pathx.join(
      home, "Library/Application Support/app.vectie.moondesk/control/execution-sandbox",
    ),
  )
  let expected = @pathx.join(root, "moonclaw.json")
  let configured = match @env.get_env_var("MOONTOWN_MOONCODE_CONTROL_CONFIG") {
    Some(value) => value
    None =>
      @env.get_env_var("MOONDESK_EXECUTION_SANDBOX_CONFIG").unwrap_or(expected)
  }
  let path = @pathx.normalize(configured)
  guard path == expected &&
    @fs.kind(root, follow_symlink=false) is Directory &&
    @fs.realpath(root) == root &&
    @fs.kind(path, follow_symlink=false) is Regular &&
    @fs.realpath(path) == path else {
    return None
  }
  let file = @fs.open(path, mode=ReadOnly)
  defer file.close()
  guard file.size() >= 0L && file.size() <= 65536L else { return None }
  let value : CodeControlConfig = @json.from_json(
    @json.parse(file.read_all().text()),
  ) catch {
    _ => return None
  }
  guard value.protocol_version == 1 &&
    code_control_hex(value.instance_id, 32) &&
    code_control_hex(value.auth_token, 64) &&
    value.workspace_id != "" &&
    value.workspace_root == @storage.moontown_active_workspace_root() &&
    @fs.kind(value.workspace_root, follow_symlink=false) is Directory &&
    @fs.realpath(value.workspace_root) == value.workspace_root else {
    return None
  }
  Some(value)
}

///|
async fn code_control_port(config : CodeControlConfig) -> Int? {
  let path = @moonsuite.product_artifact_for_workspace_root(
    config.workspace_root,
    "moonclaw",
    "daemon.json",
  )
  guard @fs.kind(path, follow_symlink=false) is Regular else { return None }
  let info = @json.parse(@fs.read_file(path).text()) catch { _ => return None }
  guard info is Object(fields) && fields.get("port") is Some(Number(port, ..)) else {
    return None
  }
  let value = port.to_int()
  if value > 0 && value <= 65535 {
    Some(value)
  } else {
    None
  }
}

///|
fn code_url_component(value : String) -> String {
  let result : Array[String] = []
  let digits = "0123456789ABCDEF"
  for byte in @utf8.encode(value) {
    if (byte >= b'a' && byte <= b'z') ||
      (byte >= b'A' && byte <= b'Z') ||
      (byte >= b'0' && byte <= b'9') ||
      byte == b'-' ||
      byte == b'_' ||
      byte == b'.' ||
      byte == b'~' {
      result.push(byte.to_char().to_string())
    } else {
      let number = byte.to_int()
      result.push(
        "%" +
        digits[number / 16:number / 16 + 1].to_owned() +
        digits[number % 16:number % 16 + 1].to_owned(),
      )
    }
  }
  result.join("")
}

///|
fn code_control_headers(config : CodeControlConfig) -> Map[String, String] {
  {
    "X-MoonClaw-Execution-Token": config.auth_token,
    "X-MoonClaw-Instance-ID": config.instance_id,
  }
}

///|
async fn code_control_get(
  port : Int,
  path : String,
  config : CodeControlConfig,
) -> Json? {
  let (response, data) = @async.with_timeout(10000, () => {
    @http.get(
      "http://127.0.0.1:\{port}\{path}",
      headers=code_control_headers(config),
    )
  }) catch {
    _ => return None
  }
  guard response.code == 200 &&
    response.headers.get("x-moonclaw-instance-id") == Some(config.instance_id) else {
    return None
  }
  let text = data.text() catch { _ => return None }
  guard text.length() <= 2_000_000 && !text.contains(config.auth_token) else {
    return None
  }
  Some(@json.parse(text) catch { _ => return None })
}

///|
async fn code_control_submit(
  port : Int,
  intent : CodeDispatchIntent,
  config : CodeControlConfig,
) -> Bool {
  let body : Json = {
    "protocol": "mooncode.v1",
    "session_id": intent.session_id,
    "book_root": intent.book_root,
    "command": "prompt",
    "model": intent.model,
    "text": intent.prompt,
    "packet": { "command_id": intent.command_id },
  }
  let headers = code_control_headers(config)
  headers["Content-Type"] = "application/json"
  let (response, data) = @async.with_timeout(10000, () => {
    @http.post(
      "http://127.0.0.1:\{port}/v1/code/sessions/\{code_url_component(intent.session_id)}/turns",
      body,
      headers~,
    )
  }) catch {
    _ => return false
  }
  guard response.code == 202 &&
    response.headers.get("x-moonclaw-instance-id") == Some(config.instance_id) else {
    return false
  }
  let text = data.text() catch { _ => return false }
  guard text.length() <= 2_000_000 && !text.contains(config.auth_token) else {
    return false
  }
  let reply = @json.parse(text) catch { _ => return false }
  reply
  is {
    "accepted": true,
    "session_id": String(session_id),
    "command_id": String(command_id),
    ..
  } &&
  session_id == intent.session_id &&
  command_id == intent.command_id
}

///|
fn code_receipt_status(claim : Json, command_id : String) -> String? {
  guard claim is Object(fields) &&
    fields.get("delivered_commands") is Some(Array(rows)) else {
    return None
  }
  for row in rows {
    guard row is Object(item) &&
      item.get("command_id") == Some(command_id.to_json()) &&
      item.get("receipt") is Some(Object(receipt)) &&
      receipt.get("status") is Some(String(status)) else {
      continue
    }
    return match status {
      "runtime-failed" | "runtime-rejected" => Some("failed")
      "runtime-cancelled" => Some("cancelled")
      "runtime-delivered"
      | "runtime-completed"
      | "runtime-succeeded"
      | "runtime-finished" => Some("done")
      _ => None
    }
  }
  None
}

///|
async fn code_schedule_terminal_receipt(
  port : Int,
  intent : CodeDispatchIntent,
  config : CodeControlConfig,
) -> String? {
  let claim_path = "/v1/code/sessions/\{code_url_component(intent.session_id)}/runtime-claim?book_root=\{code_url_component(intent.book_root)}"
  match code_control_get(port, claim_path, config) {
    Some(claim) if claim
      is {
        "owner": "moonclaw",
        "session_id": String(session_id),
        "book_root": String(book_root),
        ..
      } &&
      session_id == intent.session_id &&
      book_root == intent.book_root =>
      code_receipt_status(claim, intent.command_id)
    _ => None
  }
}

///|
async fn code_schedule_book_still_registered(
  intent : CodeDispatchIntent,
  catalog_path : String,
) -> Bool {
  let catalog = @moonbook.load_or_create_catalog(path=catalog_path)
  match @moonbook.find_catalog_entry(catalog, intent.book_id) {
    Some(entry) =>
      entry.workspace_root == intent.book_root &&
      @fs.kind(entry.workspace_root, follow_symlink=false) is Directory &&
      @fs.realpath(entry.workspace_root) == entry.workspace_root
    None => false
  }
}

///|
/// Reconcile a pending reservation before retrying it with the same command ID.
/// MoonClaw handles exact duplicate submissions and starts an interrupted
/// service for that command, so an uncertain response cannot create a second turn.
pub async fn run_due_code_schedules(
  now : Int64,
  catalog_path : String,
  path? : String = default_code_schedule_path(),
) -> String {
  let initial = load_code_schedule_state(path~)
  if initial.schedules.length() == 0 {
    return "No Code schedules"
  }
  for _ in 0..<4 {
    if reserve_due_code_schedule(now, path~) is None {
      break
    }
  }
  let intents = pending_code_schedule_intents(path~)
  if intents.length() == 0 {
    return "No due Code schedules"
  }
  // Rotate a bounded batch before touching the network. A stuck first run
  // cannot starve later schedules or hold up unrelated MoonTown jobs forever.
  for intent in intents {
    ignore(
      record_code_schedule_attempt(
        intent.schedule_id,
        intent.command_id,
        now,
        path~,
      ),
    )
  }
  let config = load_code_control_config() catch { _ => None }
  guard config is Some(config) && code_control_port(config) is Some(port) else {
    for intent in intents {
      ignore(
        record_code_schedule_waiting(
          intent.schedule_id,
          intent.command_id,
          "waiting-control",
          path~,
        ),
      )
    }
    return "Code schedules awaiting MoonClaw private control"
  }
  let mut accepted = 0
  let mut completed = 0
  let mut awaiting = 0
  for intent in intents {
    if !code_schedule_book_still_registered(intent, catalog_path) {
      ignore(
        record_code_schedule_waiting(
          intent.schedule_id,
          intent.command_id,
          "book-unavailable",
          path~,
        ),
      )
      awaiting += 1
      continue
    }
    if code_schedule_terminal_receipt(port, intent, config) is Some(status) {
      ignore(
        record_code_schedule_terminal(
          intent.schedule_id,
          intent.command_id,
          status,
          now,
          path~,
        ),
      )
      completed += 1
      continue
    }
    if code_control_submit(port, intent, config) {
      ignore(
        record_code_schedule_acceptance(
          intent.schedule_id,
          intent.command_id,
          path~,
        ),
      )
      accepted += 1
    } else {
      ignore(
        record_code_schedule_uncertain(
          intent.schedule_id,
          intent.command_id,
          path~,
        ),
      )
      awaiting += 1
      continue
    }
    if code_schedule_terminal_receipt(port, intent, config) is Some(status) {
      ignore(
        record_code_schedule_terminal(
          intent.schedule_id,
          intent.command_id,
          status,
          now,
          path~,
        ),
      )
      completed += 1
    }
  }
  "Code schedules accepted=\{accepted} completed=\{completed} awaiting=\{awaiting}"
}
