///|
test "public asset boundary excludes workspace state and traversal" {
  for
    path in [
      "/account/self.json", "/moontown/../secret", "/moontown/%2e%2e/secret", "/moontown//secret",
      "/moontown/a\\b", "/moontown/.env",
    ] {
    assert_true(
      public_relative_path(path) is None ||
      !public_asset_allowed(public_relative_path(path).unwrap_or("")),
    )
  }
  for
    relative in [
      "town.json", "operator-requests.json", "book/private.html", "miniapp/account/admin",
      "tilemap/modules/moondesk-handoff.json", "index.html.gz",
    ] {
    assert_false(public_asset_allowed(relative))
  }
  for
    relative in [
      "index.html", "tilemap/wenyu_reference_roads.json", "landmark-studio/datacenter.html",
      "landmark-studio/vendor/three.module.js",
    ] {
    assert_true(public_asset_allowed(relative))
  }
}

///|
async test "public shell separates anonymous, customers, admin and expiry without any workspace" {
  let upstream = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
  defer upstream.close()
  let origin = "http://\{upstream.addr}"
  let client = @account_identity.Client::new(
    endpoint=origin,
    host=upstream.addr.to_string(),
    origin~,
    prefix="/user",
  ).unwrap()
  let platform : PublicPlatform = {
    identity: { flights: {}, resolve: cookie => client.resolve(cookie), },
    assets: "/nonexistent-public-fixture",
    controller: origin,
    controller_ca: "",
    public_origin: origin,
    neighborhood_path: None,
  }
  let app = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
  defer app.close()
  let url = "http://\{app.addr}/moontown/"
  let expired = Ref(false)
  let role_revoked = Ref(false)
  let fleet_reads = Ref(0)
  @async.with_task_group(group => {
    group.spawn_bg(no_wait=true, allow_failure=true, () => {
      upstream.run_forever((request, _, conn) => {
        if request.path == "/v1/nodes" {
          fleet_reads.val += 1
          assert_eq(request.headers.get("cookie"), None)
          assert_eq(
            request.headers.get("authorization"),
            Some("Bearer lnxs_admin"),
          )
          if role_revoked.val {
            return reply_json(conn, 403, {})
          }
          return reply_json(conn, 200, [
            {
              "node_id": "spark-25e2-3d35c8fd",
              "state": "Ready",
              "timestamp_unix_ms": @async.now(),
              "inventory": {
                "accelerators": [
                  {
                    "architecture": "test",
                    "memory_total_mib": 1024,
                    "memory_free_mib": 512,
                    "healthy": true,
                  },
                ],
              },
              "running_deployments": ["private-task"],
              "signature": "private-signature",
            },
            { "node_id": "other-unapproved-node" },
          ])
        }
        let principal = request.headers.get("cookie").unwrap_or("")
        if !["a", "b", "admin"].contains(principal) ||
          (principal == "a" && expired.val) {
          return reply_json(conn, 401, {})
        }
        match request.path {
          "/user/auth/session" =>
            reply_json(conn, 200, { "session_token": "lnxs_" + principal })
          "/user/v1/auth/self" =>
            reply_json(conn, 200, {
              "account_id": principal,
              "subject_ref": principal,
              "identity_issuer": "fixture",
              "display_name": principal,
              "state": "Active",
              "roles": if principal == "admin" {
                ["PlatformOperator"]
              } else {
                ["EnterpriseUser"]
              },
            })
          "/user/v1/machine-access/self" => {
            assert_eq(
              request.headers.get("authorization"),
              Some("Bearer lnxs_" + principal),
            )
            if request.headers.get("x-lunanexa-organization") == Some("foreign") {
              reply_json(conn, 403, {})
            } else {
              reply_json(conn, 200, [
                {
                  "machine_ref": "owned-" + principal,
                  "lease_ref": "lease-" + principal,
                  "state": "Active",
                  "reachability": "Online",
                },
              ])
            }
          }
          _ =>
            fail(
              "Unexpected request: no models, workspace or mutation calls allowed",
            )
        }
      })
    })
    group.spawn_bg(no_wait=true, allow_failure=true, () => {
      app.run_forever((request, body, conn) => {
        platform.handle(request, body, conn)
      })
    })
    let read = async fn(principal : String, suffix : String) {
      @http.get(url + suffix, headers={ "cookie": principal })
    }
    let (response, body) = read("", "secret-compute-room.json")
    assert_eq(response.code, 200)
    assert_eq(response.headers.get("cache-control"), Some("no-store"))
    assert_true(
      @json.parse(body.text())
      is {
        "scope": { "audience": String("public"), .. },
        "local_cluster": { "machines": [_, _], .. },
        ..
      },
    )
    assert_eq(fleet_reads.val, 0)
    for principal in ["a", "b"] {
      let text = read(principal, "secret-compute-room.json?audience=admin").1.text()
      assert_true(text.contains("owned-" + principal))
      assert_false(
        text.contains("owned-" + (if principal == "a" { "b" } else { "a" })),
      )
      assert_false(text.contains("trial-"))
      assert_false(text.contains("lnxs_"))
    }
    assert_eq(fleet_reads.val, 0)
    let admin = read("admin", "secret-compute-room.json").1.text()
    assert_true(
      @json.parse(admin)
      is {
        "scope": { "audience": String("admin"), .. },
        "local_cluster": { "machines": [_, _, _, _], .. },
        ..
      },
    )
    for hidden in ["private-", "spark-", "lnxs_", "other-unapproved"] {
      assert_false(admin.contains(hidden))
    }
    role_revoked.val = true
    let denied = read("admin", "secret-compute-room.json").1.text()
    assert_true(
      @json.parse(denied)
      is {
        "scope": { "state": String("access-denied"), .. },
        "local_cluster": { "machines": [], .. },
        ..
      },
    )
    let (_, denied) = @http.get(url + "secret-compute-room.json", headers={
      "cookie": "a",
      "x-lunanexa-organization": "foreign",
    })
    assert_false(denied.text().contains("owned-"))
    let scope_a = read("a", "platform-scope.js").1.text()
    let scope_b = read("b", "platform-scope.js").1.text()
    assert_false(scope_a == scope_b)
    assert_true(scope_a.contains("account-"))
    expired.val = true
    let signed_out = read("a", "secret-compute-room.json").1.text()
    assert_false(signed_out.contains("owned-a"))
    assert_true(signed_out.contains("public-demo"))
    assert_true(read("a", "platform-scope.js").1.text().contains("\"public\""))
    for
      path in [
        "miniapp/account/admin", "workspace/private", "operator-requests.json",
      ] {
      assert_eq(read("admin", path).0.code, 404)
    }
    let (response, _) = @http.post(url + "miniapp/auth/visitor", "{}")
    assert_eq(response.code, 405)
  })
}
