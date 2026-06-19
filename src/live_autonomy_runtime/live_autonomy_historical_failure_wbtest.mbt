///|
async test "live autonomy distinguishes historical watcher failures from current blockers" {
  let workspace = live_autonomy_test_workspace(
    "/tmp/moontown-live-autonomy-failure-check",
  )
  let snapshot_path = workspace.snapshot_path
  let state = @test_fixtures.visual_projection_test_state(
    worker_status=Idle,
    execution_status=Completed,
  )
  let record = live_autonomy_watcher_record(
    goal_id="watch-opc",
    tick=41,
    book_id="research-opc",
    decision=Failed,
    detail="historical network issue already recovered",
    next_due_tick=101,
  )
  let spine = write_live_autonomy_spine(
    state,
    snapshot_path~,
    watcher_records=[record],
    tick_summary="test recovered failure",
  )
  assert_eq(spine.status, "watching")
  assert_eq(spine.failed_count, 0)
  let live_text = render_live_autonomy_status(snapshot_path~)
  assert_true(live_text.contains("Unresolved failures: `0`"))
}
