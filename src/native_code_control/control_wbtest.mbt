///|
async test "configured private control binds owner daemon and authenticated exact-byte transport without Desk" {
  let root = @fs.realpath(@fsx.mkdtemp("/tmp/town-native-control-XXXXXX"))
  let owner = root + "/owner"
  @fs.mkdir(owner)
  let path = root + "/app-data/control/execution-sandbox/moonclaw.json"
  let instance = "0123456789abcdef0123456789abcdef"
  let token = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
  @support.write_text_file(
    path,
    (
      {
        "protocol_version": 1,
        "instance_id": instance,
        "auth_token": token,
        "workspace_id": "owner",
        "workspace_root": owner,
      } : Json).stringify(),
  )
  let daemon = @moonsuite.product_artifact_for_workspace_root(
    owner, "moonclaw", "daemon.json",
  )
  @support.write_text_file(daemon, "{\"port\":43123}")
  let seen : Array[String] = []
  let result = load(path~, owner_workspace=owner, exchange=async fn(
    method,
    uri,
    body,
    headers,
  ) {
    assert_eq(headers["X-MoonClaw-Execution-Token"], token)
    assert_eq(headers["X-MoonClaw-Instance-ID"], instance)
    seen.push(method + " " + uri + " " + body)
    (202, instance, "{\"accepted\":true}")
  })
  guard result is Ok(client) else { fail("fixture control should load") }
  let frozen = "{\"command\":\"prompt\", \"text\":\"frozen bytes\"}"
  assert_true(
    client.request("POST", "/v1/code/sessions/exact/turns", frozen) is Ok(_),
  )
  assert_eq(
    seen[0],
    "POST http://127.0.0.1:43123/v1/code/sessions/exact/turns " + frozen,
  )
  assert_true(
    load(path~, owner_workspace=root) is Err(reason) &&
    reason == "control_owner_mismatch",
  )
  @support.write_text_file(daemon, "{\"port\":43123.5}")
  assert_true(
    load(path~, owner_workspace=owner) is Err(reason) &&
    reason == "runtime_port_invalid",
  )
}

///|
test "native control rejects bad response identity reflection auth denial and unavailable models" {
  let config : Config = {
    protocol_version: 1,
    instance_id: "0123456789abcdef0123456789abcdef",
    auth_token: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
    workspace_id: "fixture",
    workspace_root: "/fixture",
  }
  assert_true(
    validate_response(config, 200, "other", "{}") is Err(reason) &&
    reason == "runtime_instance_mismatch",
  )
  assert_true(
    validate_response(config, 200, config.instance_id, config.auth_token)
    is Err(reason) &&
    reason == "native_response_invalid",
  )
  assert_true(
    validate_response(config, 403, "", "{}") is Err(reason) &&
    reason == "control_authority_denied",
  )
  let route : Json = {
    "contract": "moonclaw.moongate-route.v1",
    "ready": true,
    "default_model": "moongate/one",
    "models": [{ "name": "moongate/one" }, { "name": "moongate/two" }],
  }
  assert_eq(select_model(route, "").unwrap(), "moongate/one")
  assert_eq(select_model(route, "moongate/two").unwrap(), "moongate/two")
  assert_true(select_model(route, "provider/model") is Err(_))
  assert_true(select_model(route, "moongate/missing") is Err(_))
  assert_true(select_model({ "ready": false }, "") is Err(_))
}
