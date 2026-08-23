///|
test "compute room parser accepts bounded redacted projection" {
  let projection = parse_secret_compute_room_projection_text(
    (
      #|{"schema":"moontown.secret-compute-room.v1","mode":"observed","observed_at":"2026-08-23T00:00:00Z","authority":{"agent_boundary":"MoonGate","local_control_plane":"LunaNexa","claim":"read-only redacted projection"},"gateway":{"state":"reachable","active_targets":[],"model_count":2},"local_cluster":{"configured":true,"state":"observed","machines":[{"id":"local-node-1","label":"Local node 1","state":"Active","architecture":"nvidia-gb10","accelerator_count":1,"memory_total_mib":128000,"memory_free_mib":64000,"healthy":true,"running_workloads":1,"observed_at_unix_ms":"1000"}]},"remote_routes":[{"id":"kimi","label":"Kimi","state":"observed","evidence":"MoonGate reports a matching model."}]}
    ),
  )
  assert_eq(projection.mode, "observed")
  assert_eq(projection.gateway.state, "reachable")
  assert_eq(projection.local_cluster.machines.length(), 1)
  assert_eq(projection.local_cluster.machines[0].id, "local-node-1")
  assert_eq(projection.remote_routes[0].state, "observed")
}

///|
test "compute room parser rejects authority boundary drift" {
  let projection = parse_secret_compute_room_projection_text(
    (
      #|{"schema":"moontown.secret-compute-room.v1","mode":"observed","observed_at":"","authority":{"agent_boundary":"direct-shell","local_control_plane":"LunaNexa","claim":"full access"},"gateway":{"state":"reachable","active_targets":[],"model_count":0},"local_cluster":{"configured":false,"state":"not-configured","machines":[]},"remote_routes":[]}
    ),
  )
  assert_eq(projection.mode, "unavailable")
  assert_eq(projection.authority.agent_boundary, "MoonGate")
  assert_eq(projection.authority.claim, "read-only redacted projection")
}

///|
test "compute room status uses text as well as color" {
  assert_eq(secret_compute_state_label("observed"), "已观测")
  assert_eq(secret_compute_state_label("not-observed"), "未观测")
  assert_eq(secret_compute_state_class("unreachable"), " is-offline")
}

///|
test "compute room renders spatial and textual route evidence" {
  let dispatch : Dispatch[Msg] = Emit(fn(_message) { @rabbita.none })
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_secret_compute_room(dispatch, {
        ..init_model(),
        secret_compute_room_open: true,
      }),
    ),
  )
  assert_true(html.contains("secret-compute-room"))
  assert_true(html.contains("秘密算力室"))
  assert_true(html.contains("MoonGate"))
  assert_true(html.contains("LunaNexa"))
  assert_true(html.contains("Codex / OpenAI"))
  assert_true(html.contains("DeepSeek"))
  assert_true(html.contains("GLM"))
  assert_true(html.contains("Kimi"))
  assert_true(html.contains("read-only redacted projection"))
}
