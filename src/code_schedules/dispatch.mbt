///|
fn code_url_component(value : String) -> String {
  @native_code_control.url_component(value)
}

///|
async fn code_control_submit(
  intent : CodeDispatchIntent,
  config : @native_code_control.Client,
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
  match
    config.request(
      "POST",
      "/v1/code/sessions/" + code_url_component(intent.session_id) + "/turns",
      body.stringify(),
    ) {
    Ok(reply) =>
      reply
      is {
        "accepted": true,
        "session_id": String(session_id),
        "command_id": String(command_id),
        ..
      } &&
      session_id == intent.session_id &&
      command_id == intent.command_id
    Err(_) => false
  }
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
  intent : CodeDispatchIntent,
  config : @native_code_control.Client,
) -> String? {
  let claim_path = "/v1/code/sessions/\{code_url_component(intent.session_id)}/runtime-claim?book_root=\{code_url_component(intent.book_root)}"
  match config.request("GET", claim_path, "") {
    Ok(claim) if claim
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
  let config = @native_code_control.load()
  guard config is Ok(config) else {
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
    if code_schedule_terminal_receipt(intent, config) is Some(status) {
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
    if code_control_submit(intent, config) {
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
    if code_schedule_terminal_receipt(intent, config) is Some(status) {
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
