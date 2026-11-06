///|
fn creative_route(relative : String) -> Bool {
  ["api/creative/public", "api/creative/mine", "api/creative/actions"].contains(
    relative,
  ) ||
  relative.has_prefix("api/creative/images/")
}

///|
/// Both published ports may be configured explicitly. Neither Host nor
/// forwarded headers can expand the write origins.
fn creative_origin_allowed(origin : String, primary : String) -> Bool {
  if origin == primary && !primary.is_empty() {
    return true
  }
  guard @env.get_env_var("MOONTOWN_CREATIVE_ALLOWED_ORIGINS")
    is Some(configured) &&
    configured.length() <= 4096 else {
    return false
  }
  let allowed : Array[String] = @json.from_json(@json.parse(configured)) catch {
    _ => []
  }
  !origin.is_empty() && allowed.contains(origin)
}

///|
async fn PublicPlatform::creative(
  self : PublicPlatform,
  request : @http.Request,
  body : &@io.Reader,
  conn : @http.ServerConnection,
  relative : String,
) -> Unit {
  let write = relative == "api/creative/actions"
  if (write && request.meth != Post) || (!write && request.meth != Get) {
    return reply_json(conn, 405, { "error": "method_not_allowed" })
  }
  if request.headers.get("sec-fetch-site") == Some("cross-site") {
    return reply_json(conn, 403, { "error": "same_origin_required" })
  }
  if write {
    if !creative_origin_allowed(
        request.headers.get("origin").unwrap_or(""),
        self.public_origin,
      ) {
      return reply_json(conn, 403, { "error": "same_origin_required" })
    }
    if request.headers
      .get("content-type")
      .unwrap_or("")
      .split(";")
      .next()
      .unwrap_or("")
      .trim()
      .to_lower() !=
      "application/json" {
      return reply_json(conn, 415, { "error": "json_required" })
    }
  }
  guard self.creative_path is Some(path) &&
    self.creative_config is Some(config_path) else {
    return reply_json(conn, 503, {
      "error": "creative_unavailable",
      "message": "创作活动正在准备，请稍后再来。",
    })
  }
  let session = if relative == "api/creative/public" {
    None
  } else {
    let resolution = @async.with_timeout(5000, () => {
      self.identity.read(request.headers.get("cookie").unwrap_or(""))
    }) catch {
      _ =>
        return reply_json(conn, 503, {
          "error": "identity_unavailable",
          "message": "登录服务暂时不可用，请稍后重试。",
        })
    }
    match resolution {
      Authenticated(session) => Some(session)
      SignedOut if relative.has_prefix("api/creative/images/") => None
      SignedOut =>
        return reply_json(conn, 401, {
          "error": "sign_in_required",
          "message": "登录后就能开始创作。",
        })
      Disabled | Unavailable =>
        return reply_json(conn, 503, { "error": "identity_unavailable" })
    }
  }
  let actor = session.map(s => s.context().user_id)
  let operator = session.map(s => s.is_platform_operator()).unwrap_or(false)
  if relative.has_prefix("api/creative/images/") {
    let id = relative["api/creative/images/".length():].to_owned()
    let bytes = @creative_contest.image(id, actor, path, config_path, operator~) catch {
      _ => return reply_json(conn, 404, { "error": "image_not_available" })
    }
    conn.send_response(200, "OK", extra_headers={
      "content-type": "image/png",
      "cache-control": "private, no-store",
      "x-content-type-options": "nosniff",
      "cross-origin-resource-policy": "same-origin",
      "content-disposition": "inline; filename=AI-generated.png",
    })
    conn.write(bytes)
    conn.end_response()
    return
  }
  let (action, payload) = if write {
    guard neighborhood_body(body) is Some(text) else {
      return reply_json(conn, 413, { "error": "body_too_large" })
    }
    let input = @json.parse(text) catch { _ => Json::null() }
    guard input is { "action": String(action), "payload": Object(payload), .. } else {
      return reply_json(conn, 400, { "error": "invalid_request" })
    }
    if !neighborhood_actor_matches(input, actor.unwrap_or("")) {
      return reply_json(conn, 409, {
        "error": "identity_changed",
        "message": "登录账户已变化，请刷新后重试。",
      })
    }
    (action, Json::object(payload))
  } else {
    ("snapshot", Json::object({}))
  }
  let value = @creative_contest.execute(
    action,
    payload,
    @async.now().reinterpret_as_uint64(),
    actor,
    operator,
    path,
    config_path,
  ) catch {
    error => {
      let (status, message) = match error {
        @creative_contest.CreativeError::Denied =>
          (403, "当前账户不能进行这项操作。")
        @creative_contest.CreativeError::Invalid(message) => (400, message)
        @creative_contest.CreativeError::Conflict(message) => (409, message)
        _ => (503, "创作服务暂时不可用，请稍后重试。")
      }
      return reply_json(conn, status, {
        "error": "creative_request_failed",
        "message": message,
      })
    }
  }
  reply_json(conn, 200, value)
}
