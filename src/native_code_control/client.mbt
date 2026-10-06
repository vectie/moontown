///|
/// Existing operator-owned control. The credential never leaves this package.
priv struct Config {
  protocol_version : Int
  instance_id : String
  auth_token : String
  workspace_id : String
  workspace_root : String
} derive(FromJson)

///|
pub struct Client {
  owner_workspace : String
  instance_id : String
  config_path : String
  request : async (String, String, String) -> Result[Json, String]
}

///|
/// An injected, already authenticated transport is also used by socket-free tests.
pub fn Client::new(
  owner_workspace~ : String,
  instance_id~ : String,
  config_path~ : String,
  request~ : async (String, String, String) -> Result[Json, String],
) -> Client {
  { owner_workspace, instance_id, config_path, request, }
}

///|
pub async fn Client::request(
  self : Client,
  method : String,
  path : String,
  body : String,
) -> Result[Json, String] {
  (self.request)(method, path, body)
}

///|
fn hex(value : String, length : Int) -> Bool {
  value.length() == length &&
  value.all(ch => ch.is_ascii_digit() || (ch >= 'a' && ch <= 'f'))
}

///|
pub fn configured_path() -> String {
  let fallback = @pathx.join(
    @env.get_env_var("HOME").unwrap_or(""),
    "Library/Application Support/app.vectie.moondesk/control/execution-sandbox/moonclaw.json",
  )
  @env.get_env_var("MOONTOWN_MOONCODE_CONTROL_CONFIG").unwrap_or(
    @env.get_env_var("MOONDESK_EXECUTION_SANDBOX_CONFIG").unwrap_or(fallback),
  )
}

///|
pub async fn load(
  path? : String = configured_path(),
  owner_workspace? : String = @storage.moontown_active_workspace_root(),
  exchange? : async (String, String, String, Map[String, String]) -> (
    Int,
    String,
    String,
  ),
) -> Result[Client, String] {
  load_existing(path, owner_workspace, exchange?) catch {
    _ => Err("control_unavailable: " + path)
  }
}

///|
async fn load_existing(
  path : String,
  owner_workspace : String,
  exchange? : async (String, String, String, Map[String, String]) -> (
    Int,
    String,
    String,
  ),
) -> Result[Client, String] {
  let normalized = @pathx.normalize(path)
  guard path.has_prefix("/") &&
    normalized == path &&
    path.has_suffix("/control/execution-sandbox/moonclaw.json") else {
    return Err(
      "control_path_invalid: use an existing canonical control/execution-sandbox/moonclaw.json",
    )
  }
  let root = path[:path.length() - "/moonclaw.json".length()].to_owned()
  guard @fs.kind(root, follow_symlink=false) is Directory &&
    @fs.realpath(root) == root &&
    @fs.kind(path, follow_symlink=false) is Regular &&
    @fs.realpath(path) == path else {
    return Err("control_unavailable: " + path)
  }
  let file = @fs.open(path, mode=ReadOnly)
  defer file.close()
  guard file.size() >= 0L && file.size() <= 65536L else {
    return Err("control_config_invalid")
  }
  let config : Config = @json.from_json(@json.parse(file.read_all().text())) catch {
    _ => return Err("control_config_invalid")
  }
  guard config.protocol_version == 1 &&
    hex(config.instance_id, 32) &&
    hex(config.auth_token, 64) &&
    config.workspace_id != "" else {
    return Err("control_config_invalid")
  }
  guard config.workspace_root == owner_workspace &&
    @fs.kind(owner_workspace, follow_symlink=false) is Directory &&
    @fs.realpath(owner_workspace) == owner_workspace else {
    return Err("control_owner_mismatch")
  }
  let daemon_path = @moonsuite.product_artifact_for_workspace_root(
    owner_workspace, "moonclaw", "daemon.json",
  )
  guard @fs.kind(daemon_path, follow_symlink=false) is Regular else {
    return Err("runtime_unavailable: " + daemon_path)
  }
  let info = @json.parse(@fs.read_file(daemon_path).text()) catch {
    _ => return Err("runtime_port_invalid")
  }
  guard info is { "port": Number(port, ..), .. } &&
    port == port.to_int().to_double() &&
    port > 0 &&
    port <= 65535 else {
    return Err("runtime_port_invalid")
  }
  let uri = "http://127.0.0.1:" + port.to_int().to_string()
  Ok(
    Client::new(
      owner_workspace~,
      instance_id=config.instance_id,
      config_path=path,
      request=async fn(method, path, body) {
        request_existing(config, uri, method, path, body, exchange?)
      },
    ),
  )
}

///|
fn catalog_only_route_response(route : Json) -> Bool {
  route
  is {
    "contract": "moonclaw.moongate-route.v1",
    "ready": false,
    "default_ready": false,
    "catalog_ready": true,
    "default_model": "",
    "models": Array(models),
    ..
  } &&
  !models.is_empty() &&
  models.all(model => {
    model is { "name": String(name), .. } &&
    name.has_prefix("moongate/") &&
    name.length() > 9 &&
    name == name.trim().to_owned()
  })
}

///|
fn validate_response(
  config : Config,
  status : Int,
  instance : String,
  text : String,
  route_catalog? : Bool = false,
) -> Result[Json, String] {
  if status == 401 || status == 403 {
    return Err("control_authority_denied")
  }
  if instance != config.instance_id {
    return Err("runtime_instance_mismatch")
  }
  if status == 404 {
    return Err("native_not_found")
  }
  if status == 409 {
    return Err("native_identity_conflict")
  }
  if (status < 200 || status > 299) && !(route_catalog && status == 503) {
    return Err("native_request_rejected: HTTP " + status.to_string())
  }
  if text.length() > 2_000_000 || text.contains(config.auth_token) {
    return Err("native_response_invalid")
  }
  let response = @json.parse(text) catch {
    _ => return Err("native_response_invalid")
  }
  if status == 503 && !catalog_only_route_response(response) {
    return Err("native_request_rejected: HTTP 503")
  }
  Ok(response)
}

///|
async fn request_existing(
  config : Config,
  uri : String,
  method : String,
  path : String,
  body : String,
  exchange? : async (String, String, String, Map[String, String]) -> (
    Int,
    String,
    String,
  ),
) -> Result[Json, String] {
  @async.with_timeout(10000, async fn() {
    let route_catalog = method == "GET" &&
      path == "/v1/moongate-route" &&
      body == ""
    let headers = {
      "Content-Type": "application/json",
      "X-MoonClaw-Execution-Token": config.auth_token,
      "X-MoonClaw-Instance-ID": config.instance_id,
    }
    if exchange is Some(send) {
      let (status, instance, text) = send(method, uri + path, body, headers)
      if status >= 200 &&
        status < 300 &&
        status != (if method == "POST" { 202 } else { 200 }) {
        return Err("native_response_status_invalid")
      }
      return validate_response(config, status, instance, text, route_catalog~)
    }
    let client = @http.Client(uri)
    defer client.close()
    client.request(
      if method == "POST" {
        @http.Post
      } else {
        @http.Get
      },
      path,
      extra_headers=headers,
    )
    if body != "" {
      client.write(@utf8.encode(body))
    }
    let response = client.end_request()
    if response.code >= 200 &&
      response.code < 300 &&
      response.code != (if method == "POST" { 202 } else { 200 }) {
      return Err("native_response_status_invalid")
    }
    let instance = response.headers.get("x-moonclaw-instance-id").unwrap_or("")
    validate_response(
      config,
      response.code,
      instance,
      client.read_all().text(),
      route_catalog~,
    )
  }) catch {
    _ => Err("runtime_unavailable")
  }
}

///|
pub fn url_component(value : String) -> String {
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
pub fn select_model(route : Json, requested : String) -> Result[String, String] {
  guard route
    is { "contract": "moonclaw.moongate-route.v1", "models": Array(models), .. } else {
    return Err("model_route_unavailable")
  }
  // Legacy payloads expose only ready; an explicit catalog flag is authoritative.
  let ready = route is { "ready": true, .. }
  let catalog_ready = match route {
    Object(fields) =>
      match fields.get("catalog_ready") {
        None => ready
        Some(value) => value == Json::boolean(true)
      }
    _ => false
  }
  if !catalog_ready || (requested == "" && !ready) {
    return Err("model_route_unavailable")
  }
  let selected = if requested == "" {
    guard route is { "default_model": String(default_model), .. } else {
      return Err("model_route_unavailable")
    }
    default_model
  } else {
    requested
  }
  if !selected.has_prefix("moongate/") ||
    selected.length() <= 9 ||
    !models.any(model => {
      model is { "name": String(name), .. } && name == selected
    }) {
    return Err("model_unavailable: " + selected)
  }
  Ok(selected)
}
