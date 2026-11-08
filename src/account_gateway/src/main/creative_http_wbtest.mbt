///|
extern "C" fn creative_fixture_png() -> Bytes = "moontown_preview_test_png"

///|
async test "creative HTTP isolates two accounts and publishes only the approved version" {
  let rehearsal = @env.get_env_var("MOONTOWN_CREATIVE_UI_REHEARSAL_DIST")
  let static_image = if rehearsal is Some(_) {
    @env.get_env_var("MOONTOWN_CREATIVE_UI_FIXTURE_B64_FILE")
  } else {
    None
  }
  let fixture_image = if static_image is Some(path) {
    guard path.has_prefix("/") else {
      fail("UI sample must be an explicit local file")
    }
    let encoded = @fs.read_file(path).text().trim().to_owned()
    guard encoded.length() < 12000000 else { fail("UI sample is too large") }
    encoded
  } else {
    @base64.encode(creative_fixture_png())
  }
  let real_provider = if rehearsal is Some(_) {
    @env.get_env_var("MOONTOWN_CREATIVE_UI_PROVIDER_ORIGIN")
  } else {
    None
  }
  if real_provider is Some(value) {
    guard value.has_prefix("http://127.0.0.1:") &&
      @env.get_env_var("MOONTOWN_CREATIVE_UI_PROVIDER_KEY_FILE") is Some(path) &&
      path.has_prefix("/") else {
      fail(
        "Real UI rehearsal requires a loopback provider and private key file",
      )
    }
  }
  let upstream = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
  defer upstream.close()
  let provider = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
  defer provider.close()
  let app = @http.Server(
    @socket.Addr::parse(
      if rehearsal is Some(_) {
        "127.0.0.1:" +
        @env.get_env_var("MOONTOWN_CREATIVE_UI_REHEARSAL_PORT").unwrap_or(
          "4393",
        )
      } else {
        "127.0.0.1:0"
      },
    ),
  )
  defer app.close()
  let origin = "http://\{app.addr}"
  let identity_origin = "http://\{upstream.addr}"
  let identity = @account_identity.Client::new(
    endpoint=identity_origin,
    host=upstream.addr.to_string(),
    origin=identity_origin,
    prefix="/user",
  ).unwrap()
  let retained = @env.get_env_var("MOONTOWN_CREATIVE_UI_STATE_ROOT")
  let root = match retained {
    Some(path) => {
      guard path.has_prefix("/private/tmp/coffee-participation-") else {
        fail("Private fixture state only")
      }
      if !@fs.exists(path) {
        @fs.mkdir(path, permission=0o700)
      }
      path
    }
    None => @fs.tmpdir(prefix="creative-http-")
  }
  defer (if retained is None { @fs.rmdir(root, recursive=true) })
  let path = root + "/state.json"
  let config_path = root + "/event.json"
  let now = @async.now()
  if !@fs.exists(root + "/fixture-key") {
    @fs.write_file(
      root + "/fixture-key",
      "local-interface-fixture-not-a-production-key",
      create_mode=CreateNew,
      permission=0o600,
    )
  }
  let config : Json = {
    "brief": {
      "id": "creative-http-fixture",
      "name": "接口测试 · 半醒咖啡",
      "topic": "一杯想象",
      "scope": if real_provider is Some(_) {
        "私有联调：177 真实出图，测试身份，不是正式参赛"
      } else {
        "本地接口与界面测试，不是真实模型出图"
      },
      "possibility_wiki": "",
      "first_person_solution": "",
      "deadline_ms": (now + 3600000L).to_string(),
      "benchmark_version": 1,
      "benchmark_materials": [],
      "evaluation_materials": [],
      "rubric": [],
      "published": true,
    },
    "opens_ms": (now - 10000L).to_string(),
    "voting_opens_ms": (now + 3700000L).to_string(),
    "voting_closes_ms": (now + 3800000L).to_string(),
    "awards_ms": (now + 3900000L).to_string(),
    "participant_quota": 10,
    "event_quota": 50,
    "guest_generation": true,
    "manager_account_ids": [
      "lunanexa:" +
      @account_system.account_token_digest(
        (["isolated-creative-fixture", "mayor"] : Array[String])
        .to_json()
        .stringify(),
      ),
    ],
    "provider_origin": real_provider.unwrap_or("http://\{provider.addr}"),
    "provider_key_file": if real_provider is Some(_) {
      @env.get_env_var("MOONTOWN_CREATIVE_UI_PROVIDER_KEY_FILE").unwrap()
    } else {
      root + "/fixture-key"
    },
    "model": if real_provider is Some(_) {
      "z-image-turbo"
    } else {
      "interface-fixture"
    },
  }
  let config = if retained is Some(_) && @fs.exists(config_path) {
    guard @json.parse(@fs.read_file(config_path).text()) is Object(previous) &&
      config is Object(current) else {
      fail("Invalid retained fixture")
    }
    for
      key in [
        "provider_origin", "provider_key_file", "model", "guest_generation",
      ] {
      previous[key] = current[key]
    }
    Json::object(previous)
  } else {
    config
  }
  @fs.write_file(
    config_path,
    config.stringify(),
    create_mode=if retained is Some(_) { CreateOrTruncate } else { CreateNew },
  )
  let unavailable = Ref(false)
  let identity_reads = Ref(0)
  let platform : PublicPlatform = {
    identity: {
      flights: {},
      resolve: cookie => {
        identity_reads.val += 1
        identity.resolve(identity_cookies(cookie))
      },
    },
    assets: rehearsal.unwrap_or(root),
    controller: identity_origin,
    controller_ca: "",
    public_origin: origin,
    neighborhood_path: None,
    creative_path: Some(path),
    creative_config: Some(config_path),
    program_root: None,
    program_template_config: None,
    program_approver_ids: [],
  }
  @async.with_task_group(group => {
    group.spawn_bg(no_wait=true, allow_failure=true, () => {
      upstream.run_forever((request, _, conn) => {
        if unavailable.val {
          return reply_json(conn, 503, {})
        }
        let cookie = request.headers.get("cookie").unwrap_or("")
        let principal = if cookie.contains("=a") {
          "a"
        } else if cookie.contains("=b") {
          "b"
        } else if cookie.contains("=mayor") {
          "mayor"
        } else {
          return reply_json(conn, 401, {})
        }
        match request.path {
          "/user/auth/session" =>
            reply_json(conn, 200, {
              "session_token": "lnxs_fixture_" + principal,
            })
          "/user/v1/auth/self" =>
            reply_json(conn, 200, {
              "account_id": principal,
              "subject_ref": principal,
              "identity_issuer": "isolated-creative-fixture",
              "display_name": principal,
              "state": "Active",
              "roles": ["EnterpriseUser"],
            })
          _ => reply_json(conn, 404, {})
        }
      })
    })
    group.spawn_bg(no_wait=true, allow_failure=true, () => {
      provider.run_forever((request, _, conn) => {
        assert_eq(
          request.headers.get("authorization"),
          Some("Bearer local-interface-fixture-not-a-production-key"),
        )
        reply_json(conn, 200, {
          "id": "fixture-output",
          "data": [{ "b64_json": fixture_image }],
        })
      })
    })
    group.spawn_bg(no_wait=true, allow_failure=true, () => {
      app.run_forever((request, body, conn) => {
        if rehearsal is Some(_) && request.path == "/test/logout" {
          conn.send_response(
            303,
            "See Other",
            extra_headers={ "location": "/moontown/coffee-contest.html" },
            cookies=[
              @http.Cookie(
                "lunanexa_http_enterprise_oidc_8443",
                "",
                path="/",
                max_age=0L,
                http_only=true,
              ),
            ],
          )
          conn.end_response()
          return
        }
        if rehearsal is Some(_) && request.path == "/user/auth/password" {
          guard neighborhood_body(body) is Some(text) &&
            @json.parse(text) is { "username": String(username), .. } else {
            return reply_json(conn, 400, {})
          }
          let who = if username == "a@fixture.test" {
            "a"
          } else if username == "b@fixture.test" {
            "b"
          } else if username == "mayor@fixture.test" {
            "mayor"
          } else {
            return reply_json(conn, 401, {})
          }
          return reply_json(
            conn,
            200,
            { "ok": true },
            cookie=Some(
              @http.Cookie(
                "lunanexa_http_enterprise_oidc_8443",
                who,
                path="/",
                http_only=true,
                extensions=["SameSite=Lax"],
              ),
            ),
          )
        }
        // These login routes exist only in this test binary on a loopback socket.
        if rehearsal is Some(_) && request.path.has_prefix("/test/login/") {
          let who = request.path["/test/login/".length():].to_owned()
          guard ["a", "b", "mayor"].contains(who) else {
            return reply_json(conn, 404, {})
          }
          conn.send_response(303, "See Other", extra_headers={
            "location": "/moontown/coffee-contest.html",
            "set-cookie": "lunanexa_http_enterprise_oidc_8443=" +
            who +
            "; Path=/; HttpOnly; SameSite=Strict",
            "cache-control": "no-store",
          })
          conn.end_response()
          return
        }
        if rehearsal is Some(_) && request.path == "/user/" {
          conn.send_response(200, "OK", extra_headers={
            "content-type": "text/html; charset=utf-8",
          })
          conn.write(
            "<h1>私有联调测试账户</h1><p>只使用隔离测试身份，不连接生产账户；出图模式以创作页提示为准。</p><a href='/test/logout'>访客</a><br><a href='/test/login/a'>创作者 A</a><br><a href='/test/login/b'>创作者 B</a><br><a href='/test/login/mayor'>主办</a>",
          )
          conn.end_response()
          return
        }
        if rehearsal is Some(dist) &&
          request.path == "/moontown/coffee-contest.html" {
          let html = @fs.read_file(dist + "/coffee-contest.html")
            .text()
            .replace(
              old="<body>",
              new=if static_image is Some(_) {
                "<body><div class='rehearsal-notice' style='padding:8px;background:#ffe7a1;text-align:center;font-size:12px'>私有界面验收 · 静态样图，不请求 GPU · <a href='/user/'>切换测试账户</a></div>"
              } else if real_provider is Some(_) {
                "<body><div style='padding:12px;background:#ffe7a1;text-align:center'>私有联调 · 177 真实 AI 出图 · 测试身份，不是正式参赛 · <a href='/user/'>切换测试账户</a></div>"
              } else {
                "<body><div style='padding:12px;background:#ffe7a1;text-align:center'>本地接口测试 · 返回 1 像素测试图，非真实 AI 出图 · <a href='/user/'>切换测试账户</a></div>"
              },
            )
          conn.send_response(200, "OK", extra_headers={
            "content-type": "text/html; charset=utf-8",
            "cache-control": "no-store",
          })
          conn.write(html)
          conn.end_response()
          return
        }
        platform.handle(request, body, conn)
      })
    })
    if rehearsal is Some(_) {
      group.spawn_bg(() => {
        while true {
          let _ = @creative_contest.process_next(path, config_path) catch {
            _ => false
          }
          @async.sleep(1000)
        }
      })
      println("Isolated UI rehearsal: " + origin + "/user/")
      while true {
        @async.sleep(1000)
      }
    }
    let base = origin + "/moontown/api/creative/"
    let read = async fn(who : String, route : String) {
      @http.get(base + route, headers={
        "cookie": "lunanexa_http_enterprise_oidc_8443=" + who,
      })
    }
    let write = async fn(who : String, action : String, payload : Json) {
      let mine = @json.parse(read(who, "mine").1.text())
      guard mine is { "viewer": { "account_id": String(actor), .. }, .. } else {
        fail("missing verified actor")
      }
      @http.post(
        base + "actions",
        (
          { "expected_actor_id": actor, "action": action, "payload": payload } :
          Json).stringify(),
        headers={
          "cookie": "lunanexa_http_enterprise_oidc_8443=" + who,
          "origin": origin,
          "content-type": "application/json",
        },
      )
    }
    assert_eq(read("", "mine").0.code, 401)
    assert_eq(read("", "public").0.code, 200)
    assert_eq(
      @http.post(base + "actions", "{}", headers={
        "origin": "https://untrusted.invalid",
        "content-type": "application/json",
      }).0.code,
      403,
    )
    assert_eq(
      write("a", "generate", { "prompt": "private-a-prompt", "intent": "once" }).0.code,
      200,
    )
    assert_true(@creative_contest.process_next(path, config_path))
    let mine = @json.parse(read("a", "mine").1.text())
    guard mine
      is {
        "generations": [{ "id": String(id), "state": String("completed"), .. }],
        ..
      } else {
      fail("fixture worker did not complete")
    }
    assert_false(read("b", "mine").1.text().contains("private-a-prompt"))
    assert_eq(read("b", "images/" + id).0.code, 404)
    assert_eq(read("b", "images/" + id + "/thumb").0.code, 404)
    let thumbnail = read("a", "images/" + id + "/thumb")
    assert_eq(thumbnail.0.code, 200)
    assert_eq(thumbnail.0.headers.get("content-type"), Some("image/webp"))
    assert_eq(
      thumbnail.0.headers.get("content-length"),
      Some(thumbnail.1.binary().length().to_string()),
    )
    assert_eq(read("a", "images/" + id + "/preview").0.code, 200)
    unavailable.val = true
    assert_eq(read("a", "images/" + id + "/thumb").0.code, 503)
    unavailable.val = false
    assert_eq(read("mayor", "images/" + id).0.code, 404)
    // Anonymous generation has a separate opaque capability, never an account.
    let visitor = @http.get(base + "guest")
    assert_eq(visitor.0.code, 200)
    let visitor_cookie = visitor.0.cookies[0].name +
      "=" +
      visitor.0.cookies[0].value
    assert_true(visitor.0.cookies[0].http_only)
    let other = @http.get(base + "guest").0.cookies[0]
    let other_visitor = other.name + "=" + other.value
    let anonymous_write = async fn(action : String, payload : Json) {
      @http.post(
        base + "actions",
        (
          { "action": action, "payload": payload, "expected_actor_id": "" } :
          Json).stringify(),
        headers={
          "cookie": visitor_cookie,
          "origin": origin,
          "content-type": "application/json",
        },
      )
    }
    assert_eq(
      anonymous_write("generate", {
        "prompt": "anonymous-private",
        "intent": "stable-retry",
      }).0.code,
      200,
    )
    assert_eq(
      anonymous_write("generate", {
        "prompt": "anonymous-private",
        "intent": "stable-retry",
      }).0.code,
      200,
    )
    assert_eq(anonymous_write("submit", { "consent": true }).0.code, 401)
    assert_true(@creative_contest.process_next(path, config_path))
    let visitor_mine = @http.get(base + "guest", headers={
      "cookie": visitor_cookie,
    })
    guard @json.parse(visitor_mine.1.text())
      is {
        "viewer": { "account_id": String(""), .. },
        "generations": [{ "id": String(visitor_id), .. }],
        ..
      } else {
      fail("Anonymous job was lost or duplicated")
    }
    assert_eq(
      @http.get(base + "images/" + visitor_id, headers={
        "cookie": other_visitor,
      }).0.code,
      404,
    )
    let claimed = @http.get(base + "mine", headers={
      "cookie": "lunanexa_http_enterprise_oidc_8443=a; " + visitor_cookie,
    })
    assert_eq(claimed.0.code, 200)
    assert_eq(claimed.0.cookies[0].max_age, Some(0L))
    assert_true(claimed.1.text().contains(visitor_id))
    let recovered = write("a", "generate", {
      "prompt": "anonymous-private",
      "intent": "stable-retry",
    })
    assert_eq(recovered.0.code, 200)
    guard @json.parse(recovered.1.text())
      is { "generations": Array(recovered_jobs), .. } else {
      fail("Missing recovered jobs")
    }
    assert_eq(recovered_jobs.length(), 2)
    assert_false(
      @http.get(base + "guest", headers={ "cookie": visitor_cookie }).1
      .text()
      .contains(visitor_id),
    )
    assert_eq(
      @http.get(base + "images/" + visitor_id, headers={
        "cookie": visitor_cookie,
      }).0.code,
      404,
    )
    assert_false(read("b", "mine").1.text().contains(visitor_id))
    assert_eq(
      @http.post(base + "uploads", "{}", headers={
        "cookie": visitor_cookie,
        "origin": origin,
        "content-type": "application/json",
      }).0.code,
      401,
    )
    guard @json.parse(read("a", "mine").1.text())
      is { "viewer": { "account_id": String(account_a), .. }, .. } else {
      fail("Missing account")
    }
    let upload = @http.post(
      base + "uploads",
      (
        {
          "expected_actor_id": account_a,
          "filename": "outside.png",
          "content_type": "image/png",
          "intent": "upload-retry",
          "data_base64": fixture_image,
        } : Json).stringify(),
      headers={
        "cookie": "lunanexa_http_enterprise_oidc_8443=a",
        "origin": origin,
        "content-type": "application/json",
      },
    )
    assert_eq(upload.0.code, 200)
    assert_true(upload.1.text().contains("\"source\":\"upload\""))
    assert_false(read("b", "mine").1.text().contains("upload-retry"))
    assert_eq(
      @http.post(
        base + "uploads",
        (
          {
            "expected_actor_id": account_a,
            "filename": "script.png",
            "content_type": "image/png",
            "intent": "bad-upload",
            "data_base64": @base64.encode(
              b"<svg xmlns='http://www.w3.org/2000/svg'><script>bad()</script></svg>",
            ),
          } : Json).stringify(),
        headers={
          "cookie": "lunanexa_http_enterprise_oidc_8443=a",
          "origin": origin,
          "content-type": "application/json",
        },
      ).0.code,
      400,
    )
    assert_eq(
      write("a", "submit", {
        "generation_id": id,
        "title": "接口测试作品",
        "display_name": "A",
        "consent": true,
      }).0.code,
      200,
    )
    guard @json.parse(read("a", "mine").1.text())
      is { "entries": [{ "id": String(entry), .. }], .. } else {
      fail("missing entry")
    }
    assert_eq(write("b", "approve", { "entry_id": entry }).0.code, 403)
    assert_eq(read("mayor", "images/" + id).0.code, 200)
    match identity.resolve("lunanexa_http_enterprise_oidc_8443=mayor") {
      Authenticated(session) => assert_false(session.is_platform_operator())
      _ => fail("delegated host must have an ordinary verified session")
    }
    assert_false(read("", "public").1.text().contains("接口测试作品"))
    assert_eq(write("mayor", "approve", { "entry_id": entry }).0.code, 200)
    assert_true(read("", "public").1.text().contains("接口测试作品"))
    assert_false(read("", "public").1.text().contains("private-a-prompt"))
    assert_eq(read("b", "images/" + id).0.code, 200)
    unavailable.val = true
    let before = identity_reads.val
    assert_eq(read("b", "images/" + id + "/thumb").0.code, 200)
    assert_eq(read("b", "images/" + id + "/preview").0.code, 200)
    assert_eq(identity_reads.val, before)
    assert_eq(read("b", "mine").0.code, 503)
    unavailable.val = false
    assert_eq(write("a", "withdraw", { "entry_id": entry }).0.code, 200)
    assert_eq(read("b", "images/" + id).0.code, 404)
    assert_eq(read("b", "images/" + id + "/thumb").0.code, 404)
    assert_eq(read("mayor", "images/" + id).0.code, 404)
    guard config is Object(config_fields) else {
      fail("invalid fixture config")
    }
    config_fields["manager_account_ids"] = Json::array([])
    @fs.write_file(config_path, config.stringify())
    assert_true(
      @json.parse(read("mayor", "mine").1.text())
      is { "viewer": { "operator": False, .. }, .. },
    )
    assert_eq(write("mayor", "approve", { "entry_id": entry }).0.code, 403)
  })
}

///|
test "creator capabilities are event scoped and do not enter account identity cookies" {
  let a = guest_cookie_name("https://town.example", "event-a")
  let b = guest_cookie_name("https://town.example", "event-b")
  assert_true(a != b && a.has_prefix("__Host-"))
  let token = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
  assert_eq(
    guest_token(a + "=" + token, "https://town.example", "event-a"),
    Some(token),
  )
  assert_eq(
    guest_token(a + "=" + token, "https://town.example", "event-b"),
    None,
  )
  assert_eq(
    guest_token(
      a + "=" + token + "; " + a + "=" + token,
      "https://town.example",
      "event-a",
    ),
    None,
  )
  assert_eq(identity_cookies(a + "=" + token), "")
}
