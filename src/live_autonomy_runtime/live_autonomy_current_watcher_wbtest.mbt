///|
async test "live status recomputes watcher summary from current ledger" {
  let workspace = live_autonomy_test_workspace(
    "/tmp/moontown-live-autonomy-current-watcher-check",
  )
  let root = workspace.root
  let snapshot_path = workspace.snapshot_path
  let state = @test_fixtures.visual_projection_test_state(
    worker_status=Idle,
    execution_status=Completed,
  )
  @storage.save_snapshot_file(snapshot_path, @storage.snapshot_of(state))
  let goal = live_autonomy_watch_goal(
    id="watch-opc-news",
    title="Watch OPC",
    prompt="watch opc",
    book_id="research-opc",
    next_due_tick=16000,
  )
  @storage.save_standing_goals_file("\{root}/standing-goals.json", [goal])
  let record = live_autonomy_watcher_record(
    goal_id="watch-opc-news",
    tick=15877,
    book_id="research-opc",
    decision=NeedsReview,
    detail="Standing watch execution failed for research-opc. RUNTIME ERROR: abort() called. StringBuilder::grow_if_necessary. SystemStore::save_job_proposals.",
    next_due_tick=15907,
  )
  write_live_autonomy_watcher_record_line(root, "watch-opc-news", record)
  ignore(
    write_live_autonomy_spine(
      state,
      snapshot_path~,
      tick_summary="stale cached live watcher",
    ),
  )
  let status = render_live_autonomy_status(snapshot_path~)
  assert_true(status.contains("watch-opc-news -> Failed"))
  assert_true(!status.contains("watch-opc-news -> NeedsReview"))
}
