///|
fn creative_route(relative : String) -> Bool {
  [
    "api/creative/public", "api/creative/mine", "api/creative/guest", "api/creative/actions",
    "api/creative/uploads",
  ].contains(relative) ||
  relative.has_prefix("api/creative/images/")
}

///|
/// Both published ports are explicit; request headers cannot expand origins.
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
fn creative_error_reply(error : Error) -> (Int32, String) {
  match error {
    @creative_contest.CreativeError::Denied =>
      (403, "当前账户不能进行这项操作。")
    @creative_contest.CreativeError::Invalid(message) => (400, message)
    @creative_contest.CreativeError::Conflict(message) => (409, message)
    @activity_program.ProgramError::Denied =>
      (403, "当前活动权限不允许这项操作。")
    @activity_program.ProgramError::Invalid(message) => (400, message)
    @activity_program.ProgramError::Conflict(message) => (409, message)
    _ => (503, "创作服务暂时不可用，请稍后重试。")
  }
}

///|
async fn PublicPlatform::creative_image(
  self : PublicPlatform,
  id : String,
  variant : @creative_contest.ImageVariant,
  actor : String?,
  operator : Bool,
  owner : Bool,
  activity_id : String?,
) -> Bytes {
  match activity_id {
    Some(activity) =>
      @activity_program.with_activity(
        activity,
        @async.now().reinterpret_as_uint64(),
        actor,
        owner,
        "image",
        self.program_root.unwrap(),
        binding => {
          @creative_contest.image(
            id,
            actor,
            binding.state_path,
            binding.config_path,
            operator~,
            manager=binding.may_manage,
            variant~,
          )
        },
      )
    None =>
      @creative_contest.image(
        id,
        actor,
        self.creative_path.unwrap(),
        self.creative_config.unwrap(),
        operator~,
        variant~,
      )
  }
}

///|
async fn reply_creative_image(
  conn : @http.ServerConnection,
  bytes : Bytes,
  variant : @creative_contest.ImageVariant,
) -> Unit {
  let original = variant is Original
  conn.send_response(200, "OK", extra_headers={
    "content-type": if original {
      "image/png"
    } else {
      "image/webp"
    },
    "content-length": bytes.length().to_string(),
    "cache-control": "private, no-store",
    "x-content-type-options": "nosniff",
    "cross-origin-resource-policy": "same-origin",
    "content-disposition": if original {
      "inline; filename=AI-generated.png"
    } else {
      "inline; filename=AI-generated.webp"
    },
  })
  conn.write(bytes)
  conn.end_response()
}

///|
async fn PublicPlatform::creative(
  self : PublicPlatform,
  request : @http.Request,
  body : &@io.Reader,
  conn : @http.ServerConnection,
  relative : String,
  activity_id~ : String? = None,
) -> Unit {
  let upload = relative == "api/creative/uploads"
  let visitor = relative == "api/creative/guest"
  let write = relative == "api/creative/actions" || upload
  let image_request = relative.has_prefix("api/creative/images/")
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
  if (activity_id is Some(_) && self.program_root is None) ||
    (
      activity_id is None &&
      (self.creative_path is None || self.creative_config is None)
    ) {
    return reply_json(conn, 503, {
      "error": "creative_unavailable",
      "message": "创作活动正在准备，请稍后再来。",
    })
  }
  let requested_image = if image_request {
    let parts = relative["api/creative/images/".length():]
      .split("/")
      .map(p => p.to_owned())
      .to_array()
    let variant : @creative_contest.ImageVariant = match parts {
      [_] => Original
      [_, "thumb"] => Thumbnail
      [_, "preview"] => Preview
      _ => return reply_json(conn, 404, { "error": "image_not_available" })
    }
    guard parts[0].length() == 64 &&
      parts[0].all(c => c is ('0'..<='9' | 'a'..<='f')) else {
      return reply_json(conn, 404, { "error": "image_not_available" })
    }
    Some((parts[0], variant))
  } else {
    None
  }
  if requested_image is Some((id, variant)) {
    // Published media is public already. Check the live approval on every read
    // without repeating browser authentication for every thumbnail in a grid.
    let public_image = Some(
      self.creative_image(id, variant, None, false, false, activity_id),
    ) catch {
      @creative_contest.CreativeError::Unavailable =>
        return reply_json(conn, 503, { "error": "preview_unavailable" })
      _ => None
    }
    if public_image is Some(bytes) {
      return reply_creative_image(conn, bytes, variant)
    }
  }
  let cookie_header = request.headers.get("cookie").unwrap_or("")
  let visitor_scope = match activity_id {
    Some(id) => id
    None =>
      @creative_contest.load_config(self.creative_config.unwrap()).brief.id
  }
  let token = if visitor {
    match guest_token(cookie_header, self.public_origin, visitor_scope) {
      Some(token) => Some(token)
      None => Some(issue_guest())
    }
  } else {
    guest_token(cookie_header, self.public_origin, visitor_scope)
  }
  let session = if relative == "api/creative/public" || visitor {
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
      SignedOut if image_request || (write && !upload && token is Some(_)) =>
        None
      SignedOut =>
        return reply_json(conn, 401, {
          "error": "sign_in_required",
          "message": "请先登录，再上传或提交参赛作品。",
        })
      Disabled | Unavailable =>
        return reply_json(conn, 503, { "error": "identity_unavailable" })
    }
  }
  let actor = session.map(s => s.context().user_id)
  let creator = if relative == "api/creative/public" {
    actor
  } else {
    match actor {
      Some(_) => actor
      None => token.map(guest_actor)
    }
  }
  let operator = session.map(s => s.is_platform_operator()).unwrap_or(false)
  if upload {
    if creative_upload_readers.val >= 2 {
      return reply_json(conn, 429, {
        "error": "upload_busy",
        "message": "图片检查较忙，已选图片会保留，请稍后继续上传。",
      })
    }
    creative_upload_readers.val += 1
  }
  defer (if upload { creative_upload_readers.val -= 1 })
  if requested_image is Some((id, variant)) {
    let bytes = self.creative_image(
      id,
      variant,
      creator,
      operator,
      self.program_owner(session),
      activity_id,
    ) catch {
      _ => return reply_json(conn, 404, { "error": "image_not_available" })
    }
    reply_creative_image(conn, bytes, variant)
    return
  }
  let (action, payload) = if write {
    let text = if upload {
      creative_upload_body(body)
    } else {
      neighborhood_body(body)
    }
    guard text is Some(text) else {
      return reply_json(conn, 413, { "error": "body_too_large" })
    }
    let input = @json.parse(text) catch { _ => Json::null() }
    let (action, payload) = if upload {
      ("upload", input)
    } else {
      guard input
        is { "action": String(action), "payload": Object(payload), .. } else {
        return reply_json(conn, 400, { "error": "invalid_request" })
      }
      (action, Json::object(payload))
    }
    if actor is None && (action != "generate" || creator is None) {
      return reply_json(conn, 401, {
        "error": "sign_in_required",
        "message": "登录后才能上传、参赛或投票。",
      })
    }
    let stamp_matches = if actor is None {
      input is { "expected_actor_id": String(""), .. }
    } else {
      neighborhood_actor_matches(input, actor.unwrap())
    }
    if !stamp_matches {
      return reply_json(conn, 409, {
        "error": "identity_changed",
        "message": "登录账户已变化，请刷新后重试。",
      })
    }
    (action, payload)
  } else {
    ("snapshot", Json::object({}))
  }
  let value = try {
    match activity_id {
      Some(activity) =>
        @activity_program.with_activity(
          activity,
          @async.now().reinterpret_as_uint64(),
          creator,
          self.program_owner(session),
          if relative == "api/creative/public" {
            "public"
          } else if upload {
            "submit"
          } else {
            action
          },
          self.program_root.unwrap(),
          binding => {
            let value = if upload {
              @creative_contest.import_image(
                payload,
                @async.now().reinterpret_as_uint64(),
                actor.unwrap(),
                operator || binding.may_manage,
                binding.state_path,
                binding.config_path,
              )
            } else {
              @creative_contest.execute(
                action,
                payload,
                @async.now().reinterpret_as_uint64(),
                creator,
                operator || binding.may_manage,
                binding.state_path,
                binding.config_path,
                guest_actor=if actor is Some(_) {
                  token.map(guest_actor)
                } else {
                  None
                },
              )
            }
            activity_snapshot(value, binding)
          },
        )
      None =>
        if upload {
          @creative_contest.import_image(
            payload,
            @async.now().reinterpret_as_uint64(),
            actor.unwrap(),
            operator,
            self.creative_path.unwrap(),
            self.creative_config.unwrap(),
          )
        } else {
          @creative_contest.execute(
            action,
            payload,
            @async.now().reinterpret_as_uint64(),
            creator,
            operator,
            self.creative_path.unwrap(),
            self.creative_config.unwrap(),
            guest_actor=if actor is Some(_) {
              token.map(guest_actor)
            } else {
              None
            },
          )
        }
    }
  } catch {
    error => {
      let (status, message) = creative_error_reply(error)
      return reply_json(conn, status, {
        "error": "creative_request_failed",
        "message": message,
      })
    }
  }
  if actor is None && value is Object(fields) {
    fields["viewer"] = {
      "account_id": "",
      "operator": false,
      "guest_id": creator.unwrap_or(""),
    }
  }
  reply_json(
    conn,
    200,
    value,
    cookie=if visitor {
      token.map(t => guest_cookie(t, self.public_origin, visitor_scope))
    } else if actor is Some(_) && !upload {
      token.map(t => {
        guest_cookie(t, self.public_origin, visitor_scope, claimed=true)
      })
    } else {
      None
    },
  )
}
