///|
async test "live autonomy journal tick floor is monotonic" {
  let workspace = live_autonomy_test_workspace(
    "/tmp/moontown-live-autonomy-tick-floor",
  )
  let snapshot_path = workspace.snapshot_path
  let state = @test_fixtures.visual_projection_test_state(
    worker_status=@core.WorkerStatus::Idle,
    execution_status=@core.TaskExecutionStatus::Completed,
  )
  ignore(
    write_live_autonomy_spine(
      state,
      snapshot_path~,
      tick_summary="older live file",
      daemon_tick=Some(12),
    ),
  )
  write_text_file(
    default_town_journal_path(snapshot_path~),
    live_autonomy_journal_snapshot_line(40) + "\n",
  )
  assert_eq(latest_live_autonomy_journal_tick(snapshot_path), 40)
}
