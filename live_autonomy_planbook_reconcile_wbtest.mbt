///|
async test "live status reconciles stale planbook counts from authoritative state" {
  let workspace = live_autonomy_test_workspace(
    "/tmp/moontown-live-autonomy-planbook-reconcile-check",
  )
  let root = workspace.root
  let snapshot_path = workspace.snapshot_path
  let workspace_root = "\{workspace.root}/books/plan-moontown-quality"
  ignore(
    write_moontown_planbook_autonomy(
      snapshot_path~,
      workspace_root~,
      book_catalog_path="\{root}/catalog.json",
    ),
  )
  let state = @test_fixtures.visual_projection_test_state(
    worker_status=@core.WorkerStatus::Idle,
    execution_status=@core.TaskExecutionStatus::Completed,
  )
  let spine = write_live_autonomy_spine(
    state,
    snapshot_path~,
    tick_summary="stale planbook count setup",
  )
  let stale_spine = {
    ..spine,
    planbook_open_count: 99,
    planbook_repair_active_count: 99,
  }
  let goal = live_autonomy_watch_goal(
    id="watch-sync-deferred",
    title="Watch deferred sync",
    prompt="watch sync",
    book_id="research-sync",
    next_due_tick=16000,
  )
  @storage.save_standing_goals_file("\{root}/standing-goals.json", [goal])
  let record = live_autonomy_watcher_record(
    goal_id="watch-sync-deferred",
    tick=15877,
    book_id="research-sync",
    decision=@core.WatcherDecisionKind::Deferred,
    detail="Mayor deferred standing goal because no watcher was currently eligible.",
    next_due_tick=16000,
  )
  write_live_autonomy_watcher_record_line(root, "watch-sync-deferred", record)
  write_text_file(
    default_live_autonomy_path(snapshot_path~),
    stale_spine.to_json().stringify(indent=2),
  )
  let status = render_live_autonomy_status(snapshot_path~)
  assert_true(!status.contains("PlanBook open gaps: `99`"))
  assert_true(!status.contains("PlanBook active repairs: `99`"))
  assert_true(status.contains("planbook counts reconciled"))
  assert_true(status.contains("watch-sync-deferred -> Deferred"))
  assert_true(status.contains("Latest watcher is deferred"))
}
