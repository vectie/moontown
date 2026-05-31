///|
async test "live autonomy spine persists current state and journal" {
  let root = "/tmp/moontown-live-autonomy-check"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let state = visual_projection_test_state(
    worker_status=@core.WorkerStatus::Idle,
    execution_status=@core.TaskExecutionStatus::ReviewQueued,
  )
  let goal = @core.StandingGoal::new(
    id="watch-opc",
    title="Watch OPC",
    prompt="Track OPC updates",
    target_book_id=Some("research-opc"),
    cadence_ticks=60,
    next_due_tick=0,
  )
  let record = @core.WatcherRunRecord::new(
    goal_id="watch-opc",
    tick=42,
    target_book_id="research-opc",
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
  assert_eq(spine.status, "reviewing")
  assert_eq(spine.review_count, 1)
  assert_eq(spine.accepted_update_count, 1)
  assert_eq(spine.blocked_count, 0)
  let live_text = read_text_or_empty(default_live_autonomy_path(snapshot_path~))
  let journal_text = read_text_or_empty(
    default_town_journal_path(snapshot_path~),
  )
  let digest_text = read_text_or_empty(default_live_digest_path(snapshot_path~))
  assert_true(live_text.contains("\"status\": \"reviewing\""))
  assert_true(live_text.contains("\"digest_path\""))
  assert_true(journal_text.contains("\"accepted_update_count\":1"))
  assert_true(digest_text.contains("# Moontown Live Digest"))
  assert_true(digest_text.contains("|watch-opc|research-opc|"))
}

///|
async test "live autonomy can use daemon tick instead of event-derived tick" {
  let root = "/tmp/moontown-live-autonomy-daemon-tick-check"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let state = visual_projection_test_state(
    worker_status=@core.WorkerStatus::Idle,
    execution_status=@core.TaskExecutionStatus::Completed,
  )
  let goal = @core.StandingGoal::new(
    id="watch-opc",
    title="Watch OPC",
    prompt="Track OPC updates",
    target_book_id=Some("research-opc"),
    cadence_ticks=60,
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
}

///|
async test "live autonomy distinguishes historical watcher failures from current blockers" {
  let root = "/tmp/moontown-live-autonomy-failure-check"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let state = visual_projection_test_state(
    worker_status=@core.WorkerStatus::Idle,
    execution_status=@core.TaskExecutionStatus::Completed,
  )
  let record = @core.WatcherRunRecord::new(
    goal_id="watch-opc",
    tick=41,
    target_book_id="research-opc",
    decision=@core.WatcherDecisionKind::Failed,
    delta_score=0,
    new_source_count=0,
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

///|
async test "live status reconciles stale planbook counts from authoritative state" {
  let root = "/tmp/moontown-live-autonomy-planbook-reconcile-check"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let workspace_root = "\{root}/books/plan-moontown-quality"
  ignore(
    write_moontown_planbook_autonomy(
      snapshot_path~,
      workspace_root~,
      book_catalog_path="\{root}/catalog.json",
    ),
  )
  let state = visual_projection_test_state(
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
  write_text_file(
    default_live_autonomy_path(snapshot_path~),
    stale_spine.to_json().stringify(indent=2),
  )
  let status = render_live_autonomy_status(snapshot_path~)
  assert_true(!status.contains("PlanBook open gaps: `99`"))
  assert_true(!status.contains("PlanBook active repairs: `99`"))
  assert_true(status.contains("planbook counts reconciled"))
}

///|
async test "live refresh works without saved town snapshot" {
  let root = "/tmp/moontown-live-autonomy-no-snapshot-refresh-check"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let message = refresh_live_autonomy_spine(snapshot_path~)
  assert_true(message.contains("without saved town snapshot"))
  let status = render_live_autonomy_status(snapshot_path~)
  assert_true(status.contains("# Live Autonomy Spine"))
  assert_true(status.contains("Active workers: `0`"))
}
