///|
fn hosted_route_fixture() -> Json {
  {
    "contract": "moonclaw.moongate-route.v1",
    "ready": false,
    "default_ready": false,
    "catalog_ready": true,
    "default_model": "",
    "models": [{ "name": "moongate/explicit" }],
    "status": "unavailable",
    "error": "MoonGate default model is not configured",
  }
}

///|
fn hosted_route_override(route : Json, key : String, value : Json) -> Json {
  guard route is Object(fields) else { abort("fixture") }
  let next = fields.copy()
  next[key] = value
  Json::object(next)
}

///|
async fn hosted_transport_fixture(
  text : String,
  status? : Int = 503,
  method? : String = "GET",
  path? : String = "/v1/moongate-route",
  body? : String = "",
  instance? : String = "fixture-instance",
) -> Result[Json, String] {
  let config : Config = {
    protocol_version: 1,
    instance_id: "fixture-instance",
    auth_token: "fixture-token-never-real",
    workspace_id: "fixture",
    workspace_root: "/unused-fixture",
  }
  request_existing(config, "http://unused.invalid", method, path, body, exchange=async fn(
    sent_method,
    uri,
    sent_body,
    headers,
  ) {
    assert_eq(sent_method, method)
    assert_eq(uri, "http://unused.invalid" + path)
    assert_eq(sent_body, body)
    assert_eq(headers["X-MoonClaw-Instance-ID"], config.instance_id)
    assert_eq(headers["X-MoonClaw-Execution-Token"], config.auth_token)
    (status, instance, text)
  })
}

///|
async test "hosted route 503 reaches exact explicit selection without a default" {
  guard hosted_transport_fixture(hosted_route_fixture().stringify())
    is Ok(route) else {
    fail("catalog-only hosted 503 should expose the live route")
  }
  assert_eq(select_model(route, "moongate/explicit"), Ok("moongate/explicit"))
  for requested in ["", "moongate/absent", "codex/legacy", "default"] {
    assert_true(select_model(route, requested) is Err(_))
  }
}

///|
async test "hosted route exception is limited to exact read-only endpoint and status" {
  let text = hosted_route_fixture().stringify()
  for status in [401, 403, 404, 409, 500, 502, 202] {
    assert_true(hosted_transport_fixture(text, status~) is Err(_))
  }
  for
    path in [
      "/v1/code/capabilities", "/v1/moongate-route?cached=true", "/v1/moongate-route/",
      "/v1/code/sessions/exact/turns",
    ] {
    assert_true(hosted_transport_fixture(text, path~) is Err(_))
  }
  for method in ["POST", "PUT", "DELETE", "PATCH"] {
    assert_true(hosted_transport_fixture(text, method~) is Err(_))
  }
  assert_true(hosted_transport_fixture(text, body="{}") is Err(_))
}

///|
async test "hosted route 503 requires a genuine catalog-only readiness projection" {
  let route = hosted_route_fixture()
  for
    (key, value) in [
      ("contract", ("other.v1" : Json)),
      ("ready", true),
      ("default_ready", true),
      ("default_ready", Json::null()),
      ("default_model", "moongate/explicit"),
      ("default_model", Json::null()),
      ("catalog_ready", false),
      ("catalog_ready", Json::null()),
      ("catalog_ready", "true"),
      ("catalog_ready", 1),
      ("models", []),
      ("models", Json::null()),
      ("models", [{ "name": "codex/legacy" }]),
      ("models", [{ "name": "moongate/" }]),
      ("models", [{ "name": "moongate/explicit " }]),
      ("models", [{ "name": "moongate/explicit" }, {}]),
    ] {
    assert_true(
      hosted_transport_fixture(
        hosted_route_override(route, key, value).stringify(),
      )
      is Err(_),
      msg=key,
    )
  }
  assert_true(
    hosted_transport_fixture(
      "{\"contract\":\"moonclaw.moongate-route.v1\",\"ready\":true,\"default_model\":\"moongate/explicit\",\"models\":[{\"name\":\"moongate/explicit\"}]}",
    )
    is Err(_),
  )
}

///|
async test "hosted route transport preserves response authority and legacy success" {
  let text = hosted_route_fixture().stringify()
  for
    bad in [
      "{",
      "null",
      text + " ".repeat(2_000_001),
      hosted_route_override(
        hosted_route_fixture(),
        "error",
        "fixture-token-never-real",
      ).stringify(),
    ] {
    assert_true(hosted_transport_fixture(bad) is Err(_))
  }
  assert_eq(
    hosted_transport_fixture(text, instance="different"),
    Err("runtime_instance_mismatch"),
  )
  let legacy = "{\"contract\":\"moonclaw.moongate-route.v1\",\"ready\":true,\"default_model\":\"moongate/explicit\",\"models\":[{\"name\":\"moongate/explicit\"}]}"
  guard hosted_transport_fixture(legacy, status=200) is Ok(route) else {
    fail("legacy200 must remain accepted")
  }
  assert_eq(select_model(route, ""), Ok("moongate/explicit"))
  assert_eq(select_model(route, "moongate/explicit"), Ok("moongate/explicit"))
}
