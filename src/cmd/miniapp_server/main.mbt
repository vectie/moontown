///|
fn env_value(name : String) -> String? {
  match @env.get_env_var(name) {
    Some(value) if !value.trim().is_empty() => Some(value.trim().to_owned())
    _ => None
  }
}

///|
fn miniapp_bind() -> String {
  env_value("MOONTOWN_MINIAPP_BIND").unwrap_or("127.0.0.1:18191")
}

///|
fn session_token() -> String {
  env_value("MOONTOWN_MINIAPP_SESSION_TOKEN").unwrap_or("")
}

///|
fn operator_policy_path() -> String {
  env_value("MOONTOWN_OPERATOR_POLICY_PATH").unwrap_or(
    "assets/templates/operator-request-policy.json",
  )
}

///|
fn loopback_bind(bind : String) -> Bool {
  bind.has_prefix("127.0.0.1:") ||
  bind.has_prefix("localhost:") ||
  bind.has_prefix("[::1]:")
}

///|
fn session_authorized(
  bind : String,
  configured_token : String,
  supplied_token : String,
) -> Bool {
  if configured_token.is_empty() {
    loopback_bind(bind)
  } else {
    supplied_token == configured_token
  }
}

///|
fn request_path(request : @http.Request) -> String {
  match request.path.find("?") {
    Some(index) => request.path[:index].to_owned()
    None => request.path
  }
}

///|
fn request_header(request : @http.Request, name : String) -> String {
  request.headers.get(name).unwrap_or("").trim().to_owned()
}

///|
async fn send_text(
  conn : @http.ServerConnection,
  code : Int,
  body : String,
) -> Unit {
  let encoded = @utf8.encode(body)
  conn.send_response(code, if code < 400 { "OK" } else { "Error" }, extra_headers={
    "Content-Type": "application/json; charset=utf-8",
    "Content-Length": encoded.length().to_string(),
    "Cache-Control": "no-store",
  })
  conn.write(encoded)
  conn.end_response()
}

///|
async fn send_json(
  conn : @http.ServerConnection,
  code : Int,
  value : Json,
) -> Unit {
  send_text(conn, code, value.stringify(indent=2))
}

///|
async fn require_session(
  request : @http.Request,
  conn : @http.ServerConnection,
) -> Bool {
  if session_authorized(
      miniapp_bind(),
      session_token(),
      request_header(request, "x-miniapp-session"),
    ) {
    return true
  }
  send_json(conn, 401, { "ok": false, "error": "missing_or_invalid_session" })
  false
}

///|
async fn require_json_write(
  request : @http.Request,
  conn : @http.ServerConnection,
) -> Bool {
  if !(request.meth is Post) {
    send_json(conn, 405, { "ok": false, "error": "POST required" })
    return false
  }
  let content_type = request_header(request, "content-type").to_lower()
  if !content_type.has_prefix("application/json") {
    send_json(conn, 415, { "ok": false, "error": "application/json required" })
    return false
  }
  let content_length = request_header(request, "content-length")
  let transfer_encoding = request_header(request, "transfer-encoding")
  if !transfer_encoding.is_empty() || content_length.is_empty() {
    send_json(conn, 411, {
      "ok": false,
      "error": "bounded content-length required",
    })
    return false
  }
  let size = @string.parse_int(content_length) catch {
    _ => {
      send_json(conn, 400, { "ok": false, "error": "invalid content-length" })
      return false
    }
  }
  if size < 0 || size > 128 * 1024 {
    send_json(conn, 413, { "ok": false, "error": "request body too large" })
    return false
  }
  true
}

///|
async fn handle_request(
  request : @http.Request,
  body : &@io.Reader,
  conn : @http.ServerConnection,
) -> Unit {
  let path = request_path(request)
  if request.meth is Get && path == @town_contract.miniapp_health_path() {
    send_json(conn, 200, {
      "ok": true,
      "service": "moontown-miniapp",
      "schema": @town_contract.schema_version(),
    })
    return
  }
  if request.meth is Get && path == @town_contract.miniapp_contract_path() {
    send_json(conn, 200, @town_contract.miniapp_contract())
    return
  }
  if !require_session(request, conn) {
    return
  }
  if path == @town_contract.miniapp_snapshot_path() {
    if !(request.meth is Get) {
      send_json(conn, 405, { "ok": false, "error": "GET required" })
      return
    }
    send_json(
      conn,
      200,
      @town_projection.default_town_projection().miniapp_snapshot(),
    )
    return
  }
  if path == @town_contract.miniapp_standing_watch_path() {
    if !require_json_write(request, conn) {
      return
    }
    let application = @town_application.default_request_application(
      operator_policy_path(),
    )
    let result = application.submit_standing_watch(body.read_all().text()) catch {
      error => {
        send_json(conn, 400, { "ok": false, "error": "\{error}" })
        return
      }
    }
    send_json(conn, 200, result)
    return
  }
  if path == @town_contract.miniapp_evidence_book_path() {
    if !require_json_write(request, conn) {
      return
    }
    let application = @town_application.default_request_application(
      operator_policy_path(),
    )
    let result = application.queue_evidence_book(body.read_all().text()) catch {
      error => {
        send_json(conn, 400, { "ok": false, "error": "\{error}" })
        return
      }
    }
    send_json(conn, 200, result)
    return
  }
  send_json(conn, 404, { "ok": false, "error": "not found" })
}

///|
async fn main {
  let bind = miniapp_bind()
  if !loopback_bind(bind) && session_token().is_empty() {
    fail(
      "MOONTOWN_MINIAPP_SESSION_TOKEN is required when binding beyond localhost",
    )
  }
  let server = @http.Server(@socket.Addr::parse(bind), reuse_addr=true)
  println(
    "MoonTown mini-app adapter listening at http://\{bind}; suite=\{@storage.moontown_active_workspace_root()}",
  )
  server.run_forever(handle_request, max_connections=32)
}
