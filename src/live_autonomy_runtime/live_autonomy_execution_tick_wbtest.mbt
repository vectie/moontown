///|
async test "live status counts active executions when worker state is idle" {
  let workspace = live_autonomy_test_workspace(
    "/tmp/moontown-live-autonomy-active-execution-check",
  )
  let snapshot_path = workspace.snapshot_path
  let state = @test_fixtures.visual_projection_test_state(
    worker_status=Idle,
    execution_status=Running,
  )
  @storage.save_snapshot_file(snapshot_path, @storage.snapshot_of(state))
  ignore(
    write_live_autonomy_spine(
      state,
      snapshot_path~,
      tick_summary="active execution snapshot",
    ),
  )
  let status = render_live_autonomy_status(snapshot_path~)
  assert_true(status.contains("Active workers: `1`"))
}

///|
async test "live status uses effective tick from active execution task id" {
  let workspace = live_autonomy_test_workspace(
    "/tmp/moontown-live-autonomy-effective-tick-check",
  )
  let snapshot_path = workspace.snapshot_path
  let state = live_autonomy_empty_test_state()
  state.register_execution(
    live_autonomy_standing_watch_execution(
      "standing-watch-opc-news-tick-16012",
      Running,
      "running",
    ),
  )
  @storage.save_snapshot_file(snapshot_path, @storage.snapshot_of(state))
  ignore(
    write_live_autonomy_spine(
      state,
      snapshot_path~,
      tick_summary="stale cached live tick",
      daemon_tick=Some(15907),
    ),
  )
  let status = render_live_autonomy_status(snapshot_path~)
  assert_true(status.contains("Tick: `16012`"))
}
