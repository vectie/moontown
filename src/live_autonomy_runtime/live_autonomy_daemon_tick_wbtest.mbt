///|
async test "live autonomy can use daemon tick instead of event-derived tick" {
  let workspace = live_autonomy_test_workspace(
    "/tmp/moontown-live-autonomy-daemon-tick-check",
  )
  let snapshot_path = workspace.snapshot_path
  let state = @test_fixtures.visual_projection_test_state(
    worker_status=Idle,
    execution_status=Completed,
  )
  let goal = live_autonomy_watch_goal(
    id="watch-opc",
    title="Watch OPC",
    prompt="Track OPC updates",
    book_id="research-opc",
    next_due_tick=120,
  )
  let spine = write_live_autonomy_spine(
    state,
    snapshot_path~,
    standing_goals=[goal],
    tick_summary="daemon tick alignment",
    daemon_tick=Some(119),
  )
  assert_eq(spine.tick, 119)
  assert_eq(spine.due_goal_count, 1)
  let status = render_live_autonomy_status(snapshot_path~)
  assert_true(status.contains("Tick: `119`"))
  assert_true(status.contains("Due goals: `1`"))
  assert_true(status.contains("PlanBook change log:"))
  assert_true(status.contains("PlanBook engineering digest:"))
}
