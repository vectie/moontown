///|
fn viewport_command_bar_test_dispatch() -> Dispatch[Msg] {
  Emit(fn(_msg) { @rabbita.none })
}

///|
fn render_viewport_command_bar_test_html(model : Model) -> String {
  @rabbita.render_to_string(
    @rabbita.static_cell(
      render_viewport_command_bar(viewport_command_bar_test_dispatch(), model),
    ),
  )
}

///|
test "viewport command bar reports truthful runtime availability" {
  let model = init_model()
  let connecting = {
    ..model,
    state_source: SnapshotFile,
    projection_snapshot: None,
    snapshot_version: 0,
  }
  let offline = { ..connecting, snapshot_version: 1 }
  let live = {
    ..offline,
    projection_snapshot: Some(projection_test_ready_snapshot(model)),
  }
  assert_eq(viewport_runtime_status_label(connecting), "Connecting")
  assert_eq(viewport_runtime_status_label(offline), "Town offline")
  assert_eq(viewport_runtime_status_label(live), "Live town")
  assert_true(
    !render_viewport_command_bar_test_html(offline).contains(">Live<"),
  )
}

///|
test "viewport command bar limits simulation controls to demo mode" {
  let demo = { ..init_model(), state_source: DemoSimulation }
  let demo_html = render_viewport_command_bar_test_html(demo)
  assert_true(demo_html.contains(">Demo<"))
  assert_true(demo_html.contains(">Pause<"))
  assert_true(demo_html.contains(">Step<"))
  let snapshot_html = render_viewport_command_bar_test_html({
    ..demo,
    state_source: SnapshotFile,
    snapshot_version: 1,
  })
  assert_true(!snapshot_html.contains(">Pause<"))
  assert_true(!snapshot_html.contains(">Step<"))
}

///|
test "viewport command bar removes duplicate and low-frequency chrome" {
  let html = render_viewport_command_bar_test_html(init_model())
  assert_true(html.contains("aria-label=\"Town pulse\""))
  assert_true(html.contains(">Agents<"))
  assert_true(html.contains(">Energy<"))
  assert_true(html.contains(">Budget<"))
  assert_true(html.contains(">Pressure<"))
  assert_true(html.contains("href=\"./operations.html\""))
  assert_true(html.contains(">Operations<"))
  assert_true(html.contains("aria-label=\"Viewport mode\""))
  assert_true(html.contains("aria-pressed=\"true\""))
  assert_true(html.contains("aria-label=\"Zoom out\""))
  assert_true(html.contains("aria-label=\"Zoom in\""))
  assert_true(!html.contains("viewport-mode-current"))
  assert_true(!html.contains("Copyable Mode URL"))
  assert_true(!html.contains("Local time"))
  assert_true(!html.contains("Town check waiting"))
}

///|
test "viewport command bar shows daemon tick only for connected live town" {
  let model = init_model()
  let live = {
    ..model,
    state_source: SnapshotFile,
    projection_snapshot: Some(projection_test_ready_snapshot(model)),
  }
  assert_eq(viewport_daemon_status_visible(live), false)
  assert_eq(
    viewport_daemon_status_visible({
      ..live,
      daemon_snapshot: Some({
        daemon_id: "daemon-test",
        lease_owner: "test",
        tick_sequence: 7,
        last_heartbeat_event_count: 0,
        active_goal_ids: [],
        jobs: [],
      }),
    }),
    true,
  )
}
