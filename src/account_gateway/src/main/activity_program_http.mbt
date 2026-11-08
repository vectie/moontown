///|
fn activity_program_route(relative : String) -> Bool {
  relative.has_prefix("api/program/") || relative.has_prefix("api/activities/")
}

///|
fn program_approvers() -> Array[String] raise {
  guard @env.get_env_var("MOONTOWN_ACTIVITY_PROGRAM_APPROVER_IDS") is Some(raw) else {
    return []
  }
  guard raw.length() <= 8192 else {
    fail("Program approver configuration is too large")
  }
  let ids : Array[String] = @json.from_json(@json.parse(raw))
  guard ids.length() <= 20 &&
    ids.all(id => {
      !id.trim().is_empty() &&
      id.length() <= 256 &&
      id.all(c => c.is_printable()) &&
      ids.count(id) == 1
    }) else {
    fail("Invalid program approver configuration")
  }
  ids
}

///|
fn PublicPlatform::program_owner(
  self : PublicPlatform,
  session : @account_identity.Session?,
) -> Bool {
  session
  .map(s => {
    s.is_platform_operator() ||
    self.program_approver_ids.contains(s.context().user_id)
  })
  .unwrap_or(false)
}

///|
fn program_error_reply(error : Error) -> (Int32, String) {
  match error {
    @activity_program.ProgramError::Denied =>
      (403, "当前账户没有这项活动权限。")
    @activity_program.ProgramError::Invalid(message) => (400, message)
    @activity_program.ProgramError::Conflict(message) => (409, message)
    _ => (503, "活动服务暂时不可用，请稍后重试。")
  }
}

///|
async fn PublicPlatform::activity_program(
  self : PublicPlatform,
  request : @http.Request,
  body : &@io.Reader,
  conn : @http.ServerConnection,
  relative : String,
) -> Unit {
  let parts = relative.split("/").map(part => part.to_owned()).to_array()
  match parts {
    ["api", "activities", id, route] if @activity_program.valid_activity_id(id) &&
      ["public", "mine", "guest", "actions", "uploads"].contains(route) => {
      self.creative(
        request,
        body,
        conn,
        "api/creative/" + route,
        activity_id=Some(id),
      )
      return
    }
    ["api", "activities", id, "images", image_id] if @activity_program.valid_activity_id(
        id,
      ) => {
      self.creative(
        request,
        body,
        conn,
        "api/creative/images/" + image_id,
        activity_id=Some(id),
      )
      return
    }
    ["api", "activities", id, "images", image_id, variant] if @activity_program.valid_activity_id(
        id,
      ) &&
      ["thumb", "preview"].contains(variant) => {
      self.creative(
        request,
        body,
        conn,
        "api/creative/images/" + image_id + "/" + variant,
        activity_id=Some(id),
      )
      return
    }
    _ => ()
  }
  guard parts is ["api", "program", route] &&
    ["public", "mine", "actions"].contains(route) else {
    return reply_json(conn, 404, { "error": "not_found" })
  }
  let write = route == "actions"
  if (write && request.meth != Post) || (!write && request.meth != Get) {
    return reply_json(conn, 405, { "error": "method_not_allowed" })
  }
  if request.headers.get("sec-fetch-site") == Some("cross-site") ||
    (
      write &&
      !creative_origin_allowed(
        request.headers.get("origin").unwrap_or(""),
        self.public_origin,
      )
    ) {
    return reply_json(conn, 403, { "error": "same_origin_required" })
  }
  if write &&
    request.headers
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
  guard self.program_root is Some(root) &&
    self.program_template_config is Some(template_path) else {
    return reply_json(conn, 503, {
      "error": "program_unavailable",
      "message": "活动申请工具正在准备，请稍后再来。",
    })
  }
  let session = if route == "public" {
    None
  } else {
    let resolution = @async.with_timeout(5000, () => {
      self.identity.read(request.headers.get("cookie").unwrap_or(""))
    }) catch {
      _ =>
        return reply_json(conn, 503, {
          "error": "identity_unavailable",
          "message": "登录服务暂时不可用。",
        })
    }
    match resolution {
      Authenticated(session) => Some(session)
      SignedOut =>
        return reply_json(conn, 401, {
          "error": "sign_in_required",
          "message": "登录后可以申请举办活动。",
        })
      Disabled | Unavailable =>
        return reply_json(conn, 503, { "error": "identity_unavailable" })
    }
  }
  let actor = session.map(s => s.context().user_id)
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
  let value = @activity_program.execute(
    action,
    payload,
    @async.now().reinterpret_as_uint64(),
    actor,
    self.program_owner(session),
    root,
    template_path,
  ) catch {
    error => {
      let (status, message) = program_error_reply(error)
      return reply_json(conn, status, {
        "error": "program_request_failed",
        "message": message,
      })
    }
  }
  reply_json(conn, 200, value)
}

///|
fn activity_snapshot(value : Json, binding : @activity_program.Binding) -> Json {
  if value is Object(fields) {
    if !binding.allow_generation &&
      fields.get("generations") is Some(Array(jobs)) {
      for job in jobs {
        if job is { "queue": Object(queue), .. } {
          queue["status"] = "blocked"
          queue["reason"] = "activity"
          queue["estimated_start_ms"] = Json::null()
          queue["estimated_ready_ms"] = Json::null()
        }
      }
    }
    fields["activity"] = {
      "id": binding.id,
      "status": binding.status,
      "generation_allowed": binding.allow_generation,
      "management_allowed": binding.may_manage,
      "message": if binding.status == "paused" {
        "活动已暂停，已有作品和记录仍可查看。"
      } else if binding.status == "revoked" {
        "活动主办授权已撤销，生成和新投稿已停止。"
      } else if !binding.allow_generation && binding.status == "published" {
        "活动生成授权尚未生效或已到期。"
      } else {
        ""
      },
    }
    if fields.get("event") is Some(Object(event)) &&
      binding.public_blueprint is Object(brief) {
      event["prize_plan"] = brief.get("prize_plan").unwrap_or(Json::string(""))
    }
    if !binding.allow_generation && fields.get("voting") is Some(Object(voting)) {
      voting["can_vote"] = Json::boolean(false)
    }
  }
  value
}
