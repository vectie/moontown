///|
test "public neighborhood routing is exact and cannot open private trees" {
  for
    path in [
      "api/neighborhood/public", "api/neighborhood/mine", "api/neighborhood/actions",
    ] {
    assert_true(neighborhood_route(path))
  }
  for
    path in [
      "api/neighborhood", "api/neighborhood/state.json", "api/neighborhood/mine/other",
      "api/neighborhood/../workspace", "api/collaboration", "miniapp/account/admin",
    ] {
    assert_false(neighborhood_route(path))
  }
  assert_false(neighborhood_action_allowed("public"))
  assert_false(neighborhood_action_allowed("mine"))
  assert_false(neighborhood_action_allowed("set-role"))
  assert_eq(
    neighborhood_error(@neighborhood.NeighborhoodError::Forbidden).0,
    403,
  )
  assert_eq(
    neighborhood_error(
      @neighborhood.NeighborhoodError::Conflict("private detail"),
    ).0,
    409,
  )
  assert_false(
    neighborhood_error(Failure("/private/path/token")).1
    .stringify()
    .contains("/private"),
  )
}

///|
async test "neighborhood HTTP trusts session roles preserves owner isolation and rejects CSRF" {
  let upstream = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
  defer upstream.close()
  let app = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
  defer app.close()
  let origin = "http://\{app.addr}"
  let identity_origin = "http://\{upstream.addr}"
  let client = @account_identity.Client::new(
    endpoint=identity_origin,
    host=upstream.addr.to_string(),
    origin=identity_origin,
    prefix="/user",
  ).unwrap()
  let directory = "/tmp/moontown-neighborhood-gateway-\{app.addr}-\{@async.now()}"
  @fs.mkdir(directory, permission=0o700)
  let path = directory + "/state.json"
  defer {
    if @fs.exists(path) {
      @fs.remove(path)
    }
    if @fs.exists(path + ".lock") {
      @fs.remove(path + ".lock")
    }
    if @fs.exists(path + ".next") {
      @fs.remove(path + ".next")
    }
    @fs.remove(directory)
  }
  let platform : PublicPlatform = {
    identity: {
      flights: {},
      resolve: cookie => client.resolve(identity_cookies(cookie)),
    },
    assets: directory,
    controller: identity_origin,
    controller_ca: "",
    public_origin: origin,
    neighborhood_path: Some(path),
  }
  let expired = Ref(false)
  let calls = Ref(0)
  @async.with_task_group(group => {
    group.spawn_bg(no_wait=true, allow_failure=true, () => {
      upstream.run_forever((request, _, conn) => {
        calls.val += 1
        let cookie = request.headers.get("cookie").unwrap_or("")
        let principal = match cookie {
          "lunanexa_http_enterprise_oidc_8443=a" => "a"
          "lunanexa_http_enterprise_oidc_8443=b" => "b"
          "lunanexa_http_enterprise_oidc_8443=host" => "host"
          _ => return reply_json(conn, 401, {})
        }
        if principal == "a" && expired.val {
          return reply_json(conn, 401, {})
        }
        match request.path {
          "/user/auth/session" =>
            reply_json(conn, 200, {
              "session_token": "lnxs_fixture_" + principal,
            })
          "/user/v1/auth/self" => {
            assert_eq(
              request.headers.get("authorization"),
              Some("Bearer lnxs_fixture_" + principal),
            )
            reply_json(conn, 200, {
              "account_id": principal,
              "subject_ref": principal,
              "identity_issuer": "fixture-neighborhood",
              "display_name": principal,
              "state": "Active",
              "roles": if principal == "host" {
                ["PlatformOperator"]
              } else {
                ["EnterpriseUser"]
              },
            })
          }
          _ => fail("neighborhood must not call compute or workspace APIs")
        }
      })
    })
    group.spawn_bg(no_wait=true, allow_failure=true, () => {
      app.run_forever((request, body, conn) => {
        platform.handle(request, body, conn)
      })
    })
    let base = origin + "/moontown/api/neighborhood/"
    let read = async fn(principal : String, suffix : String) {
      @http.get(base + suffix, headers={
        "cookie": "lunanexa_http_enterprise_oidc_8443=" + principal,
      })
    }
    let write = async fn(principal : String, action : String, payload : Json) {
      let expected = match @json.parse(read(principal, "mine").1.text()) {
        { "payload": { "mine": { "actor_id": String(id), .. }, .. }, .. } => id
        _ => ""
      }
      let input : Json = {
        "action": action,
        "payload": payload,
        "actor_id": "forged-host",
        "expected_actor_id": expected,
      }
      @http.post(base + "actions", input.stringify(), headers={
        "cookie": "lunanexa_http_enterprise_oidc_8443=" + principal,
        "origin": origin,
        "content-type": "application/json",
        "x-user-id": "forged-host",
      })
    }
    let (anonymous, body) = read("", "public")
    assert_eq(anonymous.code, 200)
    assert_eq(anonymous.headers.get("cache-control"), Some("no-store"))
    assert_true(
      @json.parse(body.text())
      is { "payload": { "mine": Null, "stories": [], "events": [], .. }, .. },
    )
    assert_eq(calls.val, 0)
    assert_eq(read("", "mine").0.code, 401)
    assert_eq(
      write("", "save-story", { "title": "x", "body": "x" }).0.code,
      401,
    )
    let payload : Json = {
      "action": "save-story",
      "payload": { "title": "csrf", "body": "csrf" },
    }
    for supplied_origin in ["", "https://attacker.invalid", "null"] {
      let (response, _) = @http.post(base + "actions", payload.stringify(), headers={
        "cookie": "lunanexa_http_enterprise_oidc_8443=a",
        "origin": supplied_origin,
        "content-type": "application/json",
      })
      assert_eq(response.code, 403)
    }
    assert_eq(
      @http.post(base + "actions", payload.stringify(), headers={
        "cookie": "lunanexa_http_enterprise_oidc_8443=a",
        "origin": origin,
        "content-type": "text/plain",
      }).0.code,
      415,
    )
    assert_eq(
      @http.get(base + "mine", headers={
        "cookie": "lunanexa_http_enterprise_oidc_8443=a",
        "sec-fetch-site": "cross-site",
      }).0.code,
      403,
    )
    assert_eq(write("a", "set-role", {}).0.code, 400)
    assert_eq(read("a", "actions").0.code, 405)
    assert_eq(
      @http.post(base + "public", "{}", headers={ "origin": origin }).0.code,
      405,
    )
    assert_eq(
      write("a", "save-story", {
        "id": "story-a",
        "title": "A draft",
        "body": "private-story-a",
        "owner_id": "forged-host",
      }).0.code,
      200,
    )
    assert_false(read("", "public").1.text().contains("private-story-a"))
    assert_false(
      read("b", "mine?actor_id=a").1.text().contains("private-story-a"),
    )
    assert_true(read("a", "mine").1.text().contains("private-story-a"))
    let actor_a = match @json.parse(read("a", "mine").1.text()) {
      { "payload": { "mine": { "actor_id": String(id), .. }, .. }, .. } => id
      _ => fail("missing trusted actor stamp")
    }
    let before_switch = @fs.read_file(path).text()
    let stale : Json = {
      "action": "save-story",
      "expected_actor_id": actor_a,
      "payload": {
        "id": "stale-a-draft",
        "title": "Old A draft",
        "body": "never save into B",
      },
    }
    let (response, body) = @http.post(base + "actions", stale.stringify(), headers={
      "cookie": "lunanexa_http_enterprise_oidc_8443=b",
      "origin": origin,
      "content-type": "application/json",
    })
    assert_eq(response.code, 409)
    assert_true(
      @json.parse(body.text()) is { "error": String("identity_changed"), .. },
    )
    assert_eq(@fs.read_file(path).text(), before_switch)
    assert_false(read("b", "mine").1.text().contains("stale-a-draft"))
    let (missing_stamp, _) = @http.post(base + "actions", payload.stringify(), headers={
      "cookie": "lunanexa_http_enterprise_oidc_8443=a",
      "origin": origin,
      "content-type": "application/json",
    })
    assert_eq(missing_stamp.code, 409)
    assert_eq(@fs.read_file(path).text(), before_switch)
    assert_eq(
      write("b", "publish-story", { "story_id": "story-a", "consent": true }).0.code,
      403,
    )
    assert_eq(
      write("a", "publish-story", { "story_id": "story-a", "consent": true }).0.code,
      200,
    )
    assert_true(read("", "public").1.text().contains("private-story-a"))
    let event : Json = {
      "id": "event-host",
      "title": "Hosted event",
      "description": "Public event",
      "location": "Meeting room",
      "starts_ms": (@async.now() + 60000L).to_double(),
      "ends_ms": (@async.now() + 120000L).to_double(),
      "capacity": 2,
      "can_host": true,
      "owner_id": "forged-host",
    }
    assert_eq(write("a", "save-event", event).0.code, 403)
    assert_eq(write("host", "save-event", event).0.code, 200)
    assert_eq(
      write("b", "publish-event", { "event_id": "event-host", "consent": true }).0.code,
      403,
    )
    assert_eq(
      write("host", "publish-event", {
        "event_id": "event-host",
        "consent": true,
      }).0.code,
      200,
    )
    assert_eq(
      write("a", "register", {
        "event_id": "event-host",
        "display_name": "Private Alice",
        "contact": "contact-secret-a",
        "participant_id": "b",
      }).0.code,
      200,
    )
    assert_true(read("a", "mine").1.text().contains("contact-secret-a"))
    assert_true(read("host", "mine").1.text().contains("contact-secret-a"))
    for principal in ["", "a", "b", "host"] {
      let text = read(principal, "public").1.text()
      for
        private in [
          "contact-secret-a", "Private Alice", "owner_id", "participant_id", "lnxs_",
          "forged-host",
        ] {
        assert_false(text.contains(private))
      }
    }
    let other = read("b", "mine").1.text()
    assert_false(other.contains("contact-secret-a"))
    assert_true(
      @json.parse(other)
      is {
        "payload": {
          "mine": { "can_host": False, "registrations": [], .. },
          ..
        },
        ..
      },
    )
    assert_true(
      @json.parse(read("host", "mine").1.text())
      is { "payload": { "mine": { "can_host": True, .. }, .. }, .. },
    )
    assert_true(@fs.read_file(path).text().contains("contact-secret-a"))
    expired.val = true
    assert_eq(read("a", "mine").0.code, 401)
    assert_eq(
      write("a", "withdraw-story", { "story_id": "story-a" }).0.code,
      401,
    )
    for private in ["state.json", "mine/other", "../workspace"] {
      assert_eq(read("host", private).0.code, 404)
    }
    let (response, _) = @http.post(origin + "/moontown/api/collaboration", "{}")
    assert_eq(response.code, 405)
  })
}
