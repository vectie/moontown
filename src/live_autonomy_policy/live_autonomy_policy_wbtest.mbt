///|
test "live autonomy policy counts active workers and transient debt" {
  let running_worker = @core.WorkerRef::new(
    id="worker-running",
    name="Running",
    book_id="book",
    role=Watcher,
    status=Running,
  )
  let idle_worker = @core.WorkerRef::new(
    id="worker-idle",
    name="Idle",
    book_id="book",
    role=Watcher,
    status=Idle,
  )
  let debt_execution = @core.TaskExecutionRecord::new(
    task_id="task-1",
    book_id="book",
    packet_id="packet-1",
    packet_path="packet.json",
    status=Completed,
    summary="deferred",
    output_contract="watch.result.v1",
    assigned_worker_id=Some("worker-running"),
    heartbeat_tick=7,
    result_decision="deferred-transient-infrastructure",
  )
  let state = @core.empty_state(@core.TownConfig::new(id="town", name="Town"))
  state.register_worker(running_worker)
  state.register_worker(idle_worker)
  state.register_execution(debt_execution)
  assert_eq(count_live_workers(state), 1)
  assert_eq(count_live_activity(state), 1)
  assert_eq(count_transient_infrastructure_debt(state), 1)
  assert_eq(live_autonomy_tick(state), 7)
}

///|
test "live autonomy policy constructs aggregate metric counts" {
  let counts = live_autonomy_metric_counts(
    active_workers=1,
    review=2,
    blocked=3,
    accepted_updates=4,
    no_change=5,
    failed=6,
    transient_infrastructure_debt=7,
    enabled_standing_goals=8,
    disabled_standing_goals=9,
    due_goals=10,
  )
  assert_eq(counts.active_workers, 1)
  assert_eq(counts.review, 2)
  assert_eq(counts.blocked, 3)
  assert_eq(counts.accepted_updates, 4)
  assert_eq(counts.no_change, 5)
  assert_eq(counts.failed, 6)
  assert_eq(counts.transient_infrastructure_debt, 7)
  assert_eq(counts.enabled_standing_goals, 8)
  assert_eq(counts.disabled_standing_goals, 9)
  assert_eq(counts.due_goals, 10)
}

///|
test "live autonomy markdown renderer includes operational spine sections" {
  let spine : LiveAutonomySpine = {
    generated_at_ms: 1UL,
    tick: 12,
    status: "watching",
    summary: "town waiting",
    stable_waiting: true,
    stable_waiting_observation_streak: 3,
    stable_waiting_blockers: [],
    active_worker_count: 0,
    review_count: 1,
    blocked_count: 0,
    accepted_update_count: 2,
    no_change_count: 4,
    failed_count: 0,
    transient_infrastructure_debt_count: 1,
    due_goal_count: 0,
    standing_goal_count: 2,
    enabled_standing_goal_count: 2,
    disabled_standing_goal_count: 0,
    planbook_open_count: 1,
    planbook_repair_active_count: 0,
    book_template_request_count: 1,
    pending_book_template_request_count: 0,
    failed_book_template_request_count: 0,
    book_template_request_summary: "none pending",
    book_template_latest_event_summary: "request accepted",
    latest_watcher_summary: "no new source",
    visual_projection_path: ".moontown/visual-projection.json",
    journal_path: ".moontown/town-journal.jsonl",
    digest_path: ".moontown/live-autonomy.md",
    planbook_change_log_path: "books/plan/wiki/log.md",
    planbook_engineering_digest_path: "books/plan/wiki/digest.md",
    latest_change_summary: "validated",
    next_actions: ["wait for cadence"],
  }
  let text = render_live_autonomy_spine_markdown(spine)
  assert_true(text.contains("# Live Autonomy Spine"))
  assert_true(text.contains("- Status: `watching`"))
  assert_true(text.contains("- PlanBook open gaps: `1`"))
  assert_true(text.contains("## Next Actions"))
  assert_true(text.contains("- wait for cadence"))
}
