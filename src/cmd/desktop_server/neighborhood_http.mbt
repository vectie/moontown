///|
/// Exact public-business allowlist; it does not include workspace APIs.
fn neighborhood_http_path(path : String) -> Bool {
  [
    "/api/neighborhood/public", "/api/neighborhood/mine", "/api/neighborhood/actions",
  ].contains(path)
}

///|
fn neighborhood_http_action(action : String) -> Bool {
  [
    "save-story", "publish-story", "withdraw-story", "save-event", "publish-event",
    "cancel-event", "end-event", "register", "cancel-registration", "check-in", "request-follow-up",
    "resolve-follow-up",
  ].contains(action)
}

///|
/// A client-side account stamp is only a consistency fence, never authority.
fn neighborhood_actor_matches(input : Json, actor : String) -> Bool {
  input is { "expected_actor_id": String(expected), .. } &&
  !actor.is_empty() &&
  expected == actor
}

///|
fn neighborhood_http_error(error : Error) -> (Int32, Json) {
  let (status, code, message) = match error {
    @neighborhood.NeighborhoodError::Unauthenticated =>
      (401, "sign_in_required", "请先登录统一账户。")
    @neighborhood.NeighborhoodError::Forbidden =>
      (403, "forbidden", "当前账户不能操作此内容。")
    @neighborhood.NeighborhoodError::NotFound =>
      (404, "not_found", "内容不存在或已不可用。")
    @neighborhood.NeighborhoodError::InvalidRequest(_) =>
      (400, "invalid_request", "请检查填写内容和操作。")
    @neighborhood.NeighborhoodError::Conflict(_) =>
      (409, "conflict", "状态已变化，请刷新后重试。")
    _ =>
      (503, "unavailable", "街区服务暂时不可用，请稍后重试。")
  }
  (status, { "ok": false, "error": code, "message": message })
}

///|
async fn handle_neighborhood_request(
  request : @http.Request,
  body : &@io.Reader,
  conn : @http.ServerConnection,
) -> Bool {
  let path = request_path(request)
  guard neighborhood_http_path(path) else { return false }
  // Run before the legacy operator gate, but preserve its trusted host check.
  if !local_service_host(request_header(request, "host")) {
    send_json(conn, 403, { "ok": false, "error": "unexpected_host" })
    return true
  }
  let write = path == "/api/neighborhood/actions"
  if (write && request.meth != Post) || (!write && request.meth != Get) {
    send_json(conn, 405, { "ok": false, "error": "method_not_allowed" })
    return true
  }
  if path != "/api/neighborhood/public" &&
    request_header(request, "sec-fetch-site") == "cross-site" {
    send_json(conn, 403, { "ok": false, "error": "same_origin_required" })
    return true
  }
  if write {
    if reject_unsafe_operator_write(request, conn) {
      return true
    }
    // Unlike CLI-oriented operator routes, cookie-authorized business writes
    // always require Origin. A missing header is not an authentication bypass.
    if request_header(request, "origin") !=
      "http://" + request_header(request, "host") {
      send_json(conn, 403, { "ok": false, "error": "same_origin_required" })
      return true
    }
    let kind = request_header(request, "content-type")
      .split(";")
      .next()
      .unwrap_or("")
      .trim()
      .to_lower()
    if kind != "application/json" {
      send_json(conn, 415, { "ok": false, "error": "json_required" })
      return true
    }
  }
  let session = if path == "/api/neighborhood/public" {
    None
  } else {
    match @account_identity.resolve(request_header(request, "cookie")) {
      Authenticated(session) => Some(session)
      SignedOut => {
        send_json(conn, 401, { "ok": false, "error": "sign_in_required" })
        return true
      }
      Disabled | Unavailable => {
        send_json(conn, 503, { "ok": false, "error": "identity_unavailable" })
        return true
      }
    }
  }
  let (operation, payload) = if write {
    guard bounded_identity_text(body, 131072) is Some(text) else {
      send_json(conn, 413, { "ok": false, "error": "body_too_large" })
      return true
    }
    let input = @json.parse(text) catch { _ => Json::null() }
    guard input is { "action": String(action), "payload": Object(fields), .. } &&
      neighborhood_http_action(action) else {
      send_json(conn, 400, { "ok": false, "error": "invalid_action" })
      return true
    }
    if !neighborhood_actor_matches(
        input,
        session.map(s => s.context().user_id).unwrap_or(""),
      ) {
      send_json(conn, 409, {
        "ok": false,
        "error": "identity_changed",
        "message": "登录账户已变化，请刷新后重试。",
      })
      return true
    }
    (action, Json::object(fields))
  } else {
    (
      if path == "/api/neighborhood/public" {
        "public"
      } else {
        "mine"
      },
      Json::object({}),
    )
  }
  let result = @neighborhood.execute(
    operation,
    payload,
    @env.now(),
    session.map(s => s.context().user_id),
    can_host=session.map(s => s.is_platform_operator()).unwrap_or(false),
    path=env_value("MOONTOWN_NEIGHBORHOOD_STATE_FILE").unwrap_or(
      @neighborhood.default_neighborhood_path(),
    ),
  ) catch {
    error => {
      let (status, value) = neighborhood_http_error(error)
      send_json(conn, status, value)
      return true
    }
  }
  send_json(conn, 200, result)
  true
}
