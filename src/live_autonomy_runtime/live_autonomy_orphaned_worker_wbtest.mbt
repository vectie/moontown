///|
async test "live autonomy does not count orphaned worker loss as no-change" {
  let workspace = live_autonomy_test_workspace(
    "/tmp/moontown-live-autonomy-orphaned-worker-check",
  )
  let snapshot_path = workspace.snapshot_path
  let state = @test_fixtures.visual_projection_test_state(
    worker_status=@core.WorkerStatus::Idle,
    execution_status=@core.TaskExecutionStatus::Completed,
  )
  let record = live_autonomy_watcher_record(
    goal_id="book-quality-repair-research-ai-agents",
    tick=17782,
    book_id="research-ai-agents",
    decision=@core.WatcherDecisionKind::NoChange,
    detail="MoonClaw run run-1 is indexed as Running, but no live proposal process was found; treating it as failed for mayor recovery.\nkeeper_auto_triage: persisted_terminal_result\npersisted_result_review: false",
    next_due_tick=17842,
  )
  let spine = write_live_autonomy_spine(
    state,
    snapshot_path~,
    watcher_records=[record],
    tick_summary="orphaned worker accounting",
  )
  assert_eq(spine.no_change_count, 0)
  assert_eq(
    spine.latest_watcher_summary,
    "book-quality-repair-research-ai-agents -> Deferred sources=0 delta=0 next_due=17842",
  )
  assert_true(
    spine.next_actions.any(fn(action) {
      action.contains("Latest watcher is deferred")
    }),
  )
  assert_false(
    spine.next_actions.any(fn(action) {
      action.contains("Town is watching; wait")
    }),
  )
}
