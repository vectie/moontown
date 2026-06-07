///|
async test "live autonomy spine persists current state and journal" {
  let workspace = live_autonomy_test_workspace(
    "/tmp/moontown-live-autonomy-check",
  )
  let snapshot_path = workspace.snapshot_path
  let state = visual_projection_test_state(
    worker_status=@core.WorkerStatus::Idle,
    execution_status=@core.TaskExecutionStatus::ReviewQueued,
  )
  let goal = live_autonomy_watch_goal(
    id="watch-opc",
    title="Watch OPC",
    prompt="Track OPC updates",
    book_id="research-opc",
  )
  let record = live_autonomy_watcher_record(
    goal_id="watch-opc",
    tick=42,
    book_id="research-opc",
    decision=@core.WatcherDecisionKind::Update,
    delta_score=7,
    new_source_count=2,
    detail="accepted two useful sources",
    next_due_tick=102,
  )
  let spine = write_live_autonomy_spine(
    state,
    snapshot_path~,
    standing_goals=[goal],
    watcher_records=[record],
    tick_summary="test live tick",
  )
  assert_eq(spine.status, "watching")
  assert_false(spine.stable_waiting)
  assert_eq(spine.stable_waiting_observation_streak, 0)
  assert_eq(spine.review_count, 1)
  assert_eq(spine.accepted_update_count, 1)
  assert_eq(spine.blocked_count, 0)
  assert_true(
    spine.stable_waiting_blockers.any(fn(blocker) {
      blocker.contains("review queue")
    }),
  )
  let live_text = read_text_or_empty(default_live_autonomy_path(snapshot_path~))
  let journal_text = read_text_or_empty(
    default_town_journal_path(snapshot_path~),
  )
  let digest_text = read_text_or_empty(default_live_digest_path(snapshot_path~))
  assert_true(live_text.contains("\"status\": \"watching\""))
  assert_true(live_text.contains("\"stable_waiting\": false"))
  assert_true(live_text.contains("\"digest_path\""))
  assert_true(live_text.contains("\"planbook_change_log_path\""))
  assert_true(live_text.contains("\"planbook_engineering_digest_path\""))
  assert_true(live_text.contains("\"latest_change_summary\""))
  assert_true(journal_text.contains("\"accepted_update_count\":1"))
  assert_true(digest_text.contains("# Moontown Live Digest"))
  assert_true(digest_text.contains("stable_waiting: `false`"))
  assert_true(digest_text.contains("Stable Waiting Blockers"))
  assert_true(digest_text.contains("Latest PlanBook Change"))
  assert_true(digest_text.contains("|watch-opc|research-opc|"))
}
