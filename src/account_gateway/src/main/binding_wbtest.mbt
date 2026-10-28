///|
fn fixture_grant(
  subject : String,
  organization~ : String = "org-a",
) -> @webide.Grant {
  {
    delivery_id: None,
    client_id: "moontown",
    tenant_ref: "tenant-a",
    subject_ref: subject,
    organization_id: organization,
    project_id: "project-a",
    api_secret: "lnx_fixture_secret_never_in_browser",
    allowed_models: ["model"],
    expires_unix_ms: @async.now() + 60000L,
  }
}

///|
async test "real HTTP adapter binds A and B independently, pins organization and clears expiry" {
  let upstream = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
  defer upstream.close()
  let upstream_origin = "http://\{upstream.addr}"
  let client = @account_identity.Client::new(
    endpoint=upstream_origin,
    host=upstream.addr.to_string(),
    origin=upstream_origin,
    prefix="/user",
  ).unwrap()
  let identity : BrowserIdentity = {
    flights: {},
    resolve: cookie => client.resolve(cookie),
  }
  let expired = Ref(false)
  let identity_calls = Ref(0)
  let machine_calls = Ref(0)
  let app = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
  defer app.close()
  let app_origin = "http://\{app.addr}"
  @async.with_task_group(group => {
    group.spawn_bg(no_wait=true, allow_failure=true, () => {
      upstream.run_forever((request, _, conn) => {
        assert_eq(request.headers.get("host"), Some(upstream.addr.to_string()))
        assert_eq(request.headers.get("origin"), Some(upstream_origin))
        let cookie = request.headers.get("cookie").unwrap_or("")
        let subject = if cookie == "principal=a" {
          "a"
        } else if cookie == "principal=b" {
          "b"
        } else {
          ""
        }
        if subject == "" || (subject == "a" && expired.val) {
          reply_json(conn, 401, { "error": "expired" })
        } else if request.path == "/user/auth/session" {
          identity_calls.val += 1
          @async.sleep(20)
          reply_json(conn, 200, { "session_token": "lnxs_" + subject })
        } else if request.headers.get("authorization") !=
          Some("Bearer lnxs_" + subject) {
          reply_json(conn, 401, { "error": "wrong bearer" })
        } else if request.path == "/user/v1/auth/self" {
          reply_json(conn, 200, {
            "account_id": "account-" + subject,
            "subject_ref": subject,
            "identity_issuer": "https://fixture.identity",
            "display_name": "User " + subject,
            "state": "Active",
          })
        } else if request.path == "/user/v1/machine-access/self" {
          machine_calls.val += 1
          assert_eq(
            request.headers.get("x-lunanexa-organization"),
            Some("org-a"),
          )
          reply_json(conn, 200, [
            {
              "machine_ref": "assigned-machine:" + subject,
              "lease_ref": "lease-" + subject,
              "state": "Active",
              "reachability": "Online",
              "username": "private-login",
              "credential_handoff": { "secret": "never-copy" },
            },
          ])
        } else {
          reply_json(conn, 404, { "error": "unexpected path" })
        }
      })
    })
    group.spawn_bg(no_wait=true, allow_failure=true, () => {
      app.run_forever((request, _, conn) => {
        let grant = fixture_grant(
          request.headers.get("test-workspace-owner").unwrap_or("a"),
        )
        if !identity.handle(grant, request, conn) {
          reply_json(conn, 404, {})
        }
      })
    })
    assert_true(identity.authorize(fixture_grant("a"), "principal=a"))
    assert_false(identity.authorize(fixture_grant("a"), "principal=b"))
    assert_false(identity.authorize(fixture_grant("a"), ""))
    let read = async fn(
      cookie : String,
      owner : String,
      organization : String,
    ) {
      @http.get(app_origin + "/secret-compute-room.json", headers={
        "cookie": cookie,
        "test-workspace-owner": owner,
        "x-lunanexa-organization": organization,
      })
    }
    for subject in ["a", "b"] {
      let (response, body) = read("principal=" + subject, subject, "")
      assert_eq(response.code, 200)
      assert_eq(response.headers.get("cache-control"), Some("no-store"))
      let text = body.text()
      assert_true(text.contains("assigned-machine:" + subject))
      assert_false(
        text.contains(
          "assigned-machine:" + (if subject == "a" { "b" } else { "a" }),
        ),
      )
      for secret in ["lnxs_", "private-login", "never-copy", "lnx_fixture"] {
        assert_false(text.contains(secret))
      }
    }
    let before = machine_calls.val
    assert_eq(read("principal=b", "a", "").0.code, 401)
    assert_eq(read("principal=a", "a", "org-b").0.code, 403)
    assert_eq(machine_calls.val, before)
    let before = identity_calls.val
    @async.with_task_group(readers => {
      for _ in 0..<12 {
        readers.spawn_bg(() => {
          assert_true(identity.authorize(fixture_grant("a"), "principal=a"))
        })
      }
    })
    assert_eq(identity_calls.val, before + 1)
    assert_true(identity.flights.is_empty())
    expired.val = true
    assert_false(identity.authorize(fixture_grant("a"), "principal=a"))
    assert_eq(read("principal=a", "a", "").0.code, 401)
    assert_true(identity.authorize(fixture_grant("b"), "principal=b"))
  })
}

///|
test "legacy account and visitor endpoints cannot bypass the shared identity" {
  assert_true(
    protected_account_route("/miniapp/marketplace/portable-packages/content"),
  )
  assert_true(
    legacy_account_route("/miniapp/marketplace/portable-packages/share-grants"),
  )
  for
    path in [
      "/miniapp/auth/visitor", "/miniapp/auth/logout", "/miniapp/account/admin",
      "/account/self.json", "/secret-compute-room.json", "/miniapp/me",
    ] {
    assert_true(protected_account_route(path))
  }
  assert_false(protected_account_route("/tilemap/actors/avatar.png"))
}

///|
test "only identity audience cookies leave the product gateway" {
  assert_eq(
    identity_cookies("workspace=private; analytics=x; local=secret"),
    "",
  )
  assert_eq(
    identity_cookies(
      "workspace=private; __Host-lunanexa_enterprise_oidc_8443=session; lunanexa_operator_oidc=operator",
    ),
    "__Host-lunanexa_enterprise_oidc_8443=session",
  )
  assert_eq(
    identity_cookies(
      "lunanexa_http_enterprise_oidc=one; lunanexa_http_enterprise_oidc=two",
    ),
    "",
  )
  assert_eq(
    identity_cookies("lunanexa_http_enterprise_oidc=one\r\nInjected: x"),
    "",
  )
}
