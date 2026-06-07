///|
async test "live autonomy latest watcher prefers parsed terminal duplicate" {
  let workspace = live_autonomy_test_workspace(
    "/tmp/moontown-live-autonomy-canonical-watcher-check",
  )
  let snapshot_path = workspace.snapshot_path
  let state = visual_projection_test_state(
    worker_status=@core.WorkerStatus::Idle,
    execution_status=@core.TaskExecutionStatus::Completed,
  )
  let parsed = live_autonomy_watcher_record(
    goal_id="watch-opc-news",
    tick=17972,
    book_id="research-opc",
    decision=@core.WatcherDecisionKind::NoChange,
    delta_score=8,
    detail="standing_goal_decision: no_change\ndelta_score: 8\nnew_source_count: 0\nbook_changed: no",
    task_id=Some("standing-watch-opc-news-tick-17972"),
    run_id=Some("run-opc"),
    next_due_tick=18032,
  )
  let generic = live_autonomy_watcher_record(
    goal_id="watch-opc-news",
    tick=17972,
    book_id="research-opc",
    decision=@core.WatcherDecisionKind::NeedsReview,
    detail="MoonClaw run run-opc completed: Workflow completed",
    task_id=Some("standing-watch-opc-news-tick-17972"),
    run_id=Some("run-opc"),
    next_due_tick=18002,
  )
  let spine = write_live_autonomy_spine(
    state,
    snapshot_path~,
    watcher_records=[parsed, generic],
    tick_summary="canonical watcher check",
  )
  assert_eq(
    spine.latest_watcher_summary,
    "watch-opc-news -> NoChange sources=0 delta=8 next_due=18032",
  )
}
