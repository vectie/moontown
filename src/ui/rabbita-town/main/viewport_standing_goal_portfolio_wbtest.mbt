///|
fn standing_goal_portfolio_test_goal(
  id : String,
  enabled? : Bool = true,
  target_book_id? : String? = Some("research-opc"),
) -> StandingGoalSnapshot {
  {
    id,
    title: "Watch \{id}",
    prompt: "Track useful updates for \{id}.",
    target_book_id,
    cadence_ticks: 30,
    next_due_tick: 12,
    last_run_tick: Some(2),
    enabled,
    source_policy: "test-policy",
    quality_threshold: 82,
  }
}

///|
fn standing_goal_portfolio_test_record(
  goal_id : String,
  decision? : String = "Update",
  tick? : Int = 8,
) -> WatcherRunRecordSnapshot {
  {
    goal_id,
    tick,
    target_book_id: "research-opc",
    decision,
    delta_score: 12,
    new_source_count: 3,
    checked_sources_count: Some(9),
    new_sources_found: Some(4),
    accepted_facts_count: Some(5),
    rejected_facts_count: Some(1),
    wiki_pages_changed_count: Some(2),
    book_changed: Some("yes"),
    detail: "Accepted new facts\nwith source evidence.",
    task_id: Some("task-1"),
    run_id: Some("run-1"),
    next_due_tick: 38,
  }
}

///|
fn standing_goal_portfolio_test_daemon(tick_sequence : Int) -> DaemonSnapshot {
  {
    daemon_id: "daemon-test",
    lease_owner: "test",
    tick_sequence,
    last_heartbeat_event_count: 1,
    active_goal_ids: ["opc"],
    jobs: [],
  }
}

///|
test "standing goal card view uses waiting defaults without watcher record" {
  let goal = standing_goal_portfolio_test_goal("opc")
  let model = {
    ..init_model(),
    tick: 10,
    standing_goals: [goal],
    watcher_records: [],
  }
  let view = standing_goal_card_view(model, goal)
  assert_eq(view.decision, "Waiting")
  assert_eq(
    view.detail,
    "No ledger row has been recorded for this standing watch yet.",
  )
  assert_eq(view.latest_tick, "no completed tick")
  assert_eq(view.checked_sources, "n/a")
  assert_eq(view.book_changed, "unknown")
  assert_eq(view.record_count, 0)
}

///|
test "standing goal card view resolves latest watcher metrics once" {
  let goal = standing_goal_portfolio_test_goal("opc")
  let model = {
    ..init_model(),
    tick: 10,
    standing_goals: [goal],
    watcher_records: [
      standing_goal_portfolio_test_record("opc", decision="NoChange", tick=4),
      standing_goal_portfolio_test_record("opc", decision="Update", tick=8),
      standing_goal_portfolio_test_record("other", decision="Failed", tick=9),
    ],
  }
  let view = standing_goal_card_view(model, goal)
  assert_eq(view.decision, "Update")
  assert_eq(view.detail, "Accepted new facts")
  assert_eq(view.latest_tick, "latest tick 8")
  assert_eq(view.checked_sources, "9")
  assert_eq(view.new_sources_found, "4")
  assert_eq(view.accepted_facts, "5")
  assert_eq(view.rejected_facts, "1")
  assert_eq(view.changed_pages, "2")
  assert_eq(view.book_changed, "yes")
  assert_eq(view.record_count, 2)
  assert_eq(view.update_count, 1)
  assert_eq(view.no_change_count, 1)
  assert_eq(view.failed_count, 0)
}

///|
test "watcher decision summary aggregates all records and per-goal records" {
  let model = {
    ..init_model(),
    watcher_records: [
      standing_goal_portfolio_test_record("opc", decision="Update", tick=1),
      standing_goal_portfolio_test_record("opc", decision="NoChange", tick=2),
      standing_goal_portfolio_test_record("opc", decision="NeedsReview", tick=3),
      standing_goal_portfolio_test_record("llm", decision="Failed", tick=4),
      standing_goal_portfolio_test_record("llm", decision="Update", tick=5),
    ],
  }
  let all = watcher_decision_summary(model)
  assert_eq(all.update_count, 2)
  assert_eq(all.review_count, 1)
  assert_eq(all.no_change_count, 1)
  assert_eq(all.failed_count, 1)
  let opc = watcher_decision_summary_for_goal(model, Some("opc"))
  assert_eq(opc.update_count, 1)
  assert_eq(opc.review_count, 1)
  assert_eq(opc.no_change_count, 1)
  assert_eq(opc.failed_count, 0)
}

///|
test "standing goal summary counts enabled disabled and first active goal" {
  let first = standing_goal_portfolio_test_goal("opc")
  let disabled = standing_goal_portfolio_test_goal("hardware", enabled=false)
  let second = standing_goal_portfolio_test_goal("llm")
  let model = { ..init_model(), standing_goals: [first, disabled, second] }
  let summary = standing_goal_summary(model)
  assert_eq(summary.enabled_count, 2)
  assert_eq(summary.disabled_count, 1)
  assert_true(summary.active_goal is Some({ id: "opc", .. }))
}

///|
test "standing goal summary handles empty and disabled-only goals" {
  let empty_model = init_model()
  let empty_summary = standing_goal_summary(empty_model)
  assert_eq(empty_summary.enabled_count, 0)
  assert_eq(empty_summary.disabled_count, 0)
  assert_true(empty_summary.active_goal is None)
  let disabled_model = {
    ..init_model(),
    standing_goals: [
      standing_goal_portfolio_test_goal("opc", enabled=false),
      standing_goal_portfolio_test_goal("llm", enabled=false),
    ],
  }
  let disabled_summary = standing_goal_summary(disabled_model)
  assert_eq(disabled_summary.enabled_count, 0)
  assert_eq(disabled_summary.disabled_count, 2)
  assert_true(disabled_summary.active_goal is None)
}

///|
test "standing goal next check view formats active future goal" {
  let goal = standing_goal_portfolio_test_goal("opc")
  let model = {
    ..init_model(),
    daemon_snapshot: Some(standing_goal_portfolio_test_daemon(10)),
    standing_goals: [goal],
  }
  let view = standing_goal_next_check_view(model)
  assert_eq(view.operator_detail, "Next check in 2 ticks. Daemon tick 10.")
  assert_eq(view.portal_label, "2 ticks")
  assert_eq(
    view.idle_detail,
    "Waiting until 2 daemon ticks for `opc`. The next due check will move a watcher into an active run.",
  )
}

///|
test "standing goal next check view clamps overdue goal to next tick" {
  let goal = standing_goal_portfolio_test_goal("opc")
  let model = {
    ..init_model(),
    daemon_snapshot: Some(standing_goal_portfolio_test_daemon(15)),
    standing_goals: [goal],
  }
  let view = standing_goal_next_check_view(model)
  assert_eq(view.operator_detail, "Next check in 0 ticks. Daemon tick 15.")
  assert_eq(view.portal_label, "0 ticks")
  assert_eq(
    view.idle_detail,
    "Waiting until the next daemon tick for `opc`. The next due check will move a watcher into an active run.",
  )
}

///|
test "standing goal next check view explains missing active watcher" {
  let disabled = standing_goal_portfolio_test_goal("opc", enabled=false)
  let model = {
    ..init_model(),
    daemon_snapshot: Some(standing_goal_portfolio_test_daemon(10)),
    standing_goals: [disabled],
  }
  let view = standing_goal_next_check_view(model)
  assert_eq(view.operator_detail, "No enabled standing goal found.")
  assert_eq(view.portal_label, "not scheduled")
  assert_eq(
    view.idle_detail,
    "Waiting for a configured standing watch. Add one to `.moonsuite/products/moontown/standing-goals.json` to activate this worker.",
  )
}
