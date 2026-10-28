///|
fn neighborhood_route(relative : String) -> Bool {
  [
    "api/neighborhood/public", "api/neighborhood/mine", "api/neighborhood/actions",
  ].contains(relative)
}

///|
fn neighborhood_action_allowed(action : String) -> Bool {
  [
    "save-story", "publish-story", "withdraw-story", "save-event", "publish-event",
    "cancel-event", "end-event", "register", "cancel-registration", "check-in", "request-follow-up",
    "resolve-follow-up",
  ].contains(action)
}

///|
/// Compare the UI account stamp with the verified session, never adopt it.
fn neighborhood_actor_matches(input : Json, actor : String) -> Bool {
  input is { "expected_actor_id": String(expected), .. } &&
  !actor.is_empty() &&
  expected == actor
}

///|
async fn neighborhood_body(reader : &@io.Reader) -> String? {
  let limit = 131072
  let bytes = FixedArray::make(limit + 1, b'\x00')
  let mut length = 0
  while length <= limit {
    let count = reader.read(bytes, offset=length, max_len=limit + 1 - length)
    if count == 0 {
      return Some(@utf8.decode(bytes.unsafe_reinterpret_as_bytes()[:length]))
    }
    length += count
  }
  None
}

///|
fn neighborhood_error(error : Error) -> (Int32, Json) {
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
/// Only this narrow public-business API may write in public mode. It shares
/// neither tenant workspace storage nor the private workspace proxy.
async fn PublicPlatform::neighborhood(
  self : PublicPlatform,
  request : @http.Request,
  body : &@io.Reader,
  conn : @http.ServerConnection,
  relative : String,
) -> Unit {
  let write = relative == "api/neighborhood/actions"
  if (write && request.meth != Post) || (!write && request.meth != Get) {
    return reply_json(conn, 405, { "ok": false, "error": "method_not_allowed" })
  }
  if relative != "api/neighborhood/public" &&
    request.headers.get("sec-fetch-site") == Some("cross-site") {
    return reply_json(conn, 403, {
      "ok": false,
      "error": "same_origin_required",
    })
  }
  if write {
    // Compare against deployment configuration, never a caller-selected Host
    // or forwarded header. JSON + a mandatory exact Origin closes CSRF writes.
    if self.public_origin.is_empty() ||
      request.headers.get("origin") != Some(self.public_origin) {
      return reply_json(conn, 403, {
        "ok": false,
        "error": "same_origin_required",
      })
    }
    let kind = request.headers
      .get("content-type")
      .unwrap_or("")
      .split(";")
      .next()
      .unwrap_or("")
      .trim()
      .to_lower()
    if kind != "application/json" {
      return reply_json(conn, 415, { "ok": false, "error": "json_required" })
    }
  }
  guard self.neighborhood_path is Some(path) else {
    return reply_json(conn, 503, {
      "ok": false,
      "error": "neighborhood_unavailable",
    })
  }
  let session = if relative == "api/neighborhood/public" {
    None
  } else {
    let resolution = @async.with_timeout(5000, () => {
      self.identity.read(request.headers.get("cookie").unwrap_or(""))
    }) catch {
      _ =>
        return reply_json(conn, 503, {
          "ok": false,
          "error": "identity_unavailable",
        })
    }
    match resolution {
      Authenticated(session) => Some(session)
      SignedOut =>
        return reply_json(conn, 401, {
          "ok": false,
          "error": "sign_in_required",
        })
      Disabled | Unavailable =>
        return reply_json(conn, 503, {
          "ok": false,
          "error": "identity_unavailable",
        })
    }
  }
  let (operation, payload) = if write {
    guard neighborhood_body(body) is Some(text) else {
      return reply_json(conn, 413, { "ok": false, "error": "body_too_large" })
    }
    let input = @json.parse(text) catch { _ => Json::null() }
    guard input is { "action": String(action), "payload": Object(fields), .. } &&
      neighborhood_action_allowed(action) else {
      return reply_json(conn, 400, { "ok": false, "error": "invalid_action" })
    }
    if !neighborhood_actor_matches(
        input,
        session.map(s => s.context().user_id).unwrap_or(""),
      ) {
      return reply_json(conn, 409, {
        "ok": false,
        "error": "identity_changed",
        "message": "登录账户已变化，请刷新后重试。",
      })
    }
    (action, Json::object(fields))
  } else {
    (
      if relative == "api/neighborhood/public" {
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
    @async.now().reinterpret_as_uint64(),
    session.map(s => s.context().user_id),
    can_host=session.map(s => s.is_platform_operator()).unwrap_or(false),
    path~,
  ) catch {
    error => {
      let (status, value) = neighborhood_error(error)
      return reply_json(conn, status, value)
    }
  }
  reply_json(conn, 200, result)
}
