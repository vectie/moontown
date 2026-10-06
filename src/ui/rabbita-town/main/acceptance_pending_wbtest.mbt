///|
test "acceptance pending has explicit civic label without completed score or health bonus" {
  assert_true(civic_execution_stage(AwaitingAcceptance) is @ui.Acceptance)
  assert_eq(
    civic_execution_stage_label_for_status(
      AwaitingAcceptance,
      civic_execution_policy_test_phrases(),
    ),
    "Acceptance pending",
  )
  let score_policy : CivicExecutionScorePolicy = {
    packet: 10,
    running: 20,
    persisting: 30,
    review: 40,
    completed: 100,
    recovery: 0,
  }
  assert_eq(
    civic_execution_score_for_status(AwaitingAcceptance, score_policy),
    40,
  )
  let health_policy : CivicHealthExecutionPolicy = {
    awaiting_delta: 5,
    review_delta: -10,
    failed_delta: -20,
    completed_delta: 30,
  }
  assert_eq(
    civic_health_after_execution_stage(50, @ui.Acceptance, health_policy),
    50,
  )
  assert_eq(
    civic_module_signal_class_for_status(
      AwaitingAcceptance,
      running_is_live=true,
    ),
    "module-signal-neutral",
  )
}

///|
test "acceptance pending execution is unresolved but not active review complete or retry feed" {
  let execution = civic_execution_policy_test_execution(AwaitingAcceptance)
  let counts = execution_count_summary([execution])
  assert_eq(counts.awaiting_acceptance, 1)
  assert_eq(counts.review_queued, 0)
  assert_eq(counts.completed, 0)
  assert_eq(counts.active_run_flow(), 0)
  assert_eq(counts.active_or_unresolved(), 1)
  assert_eq(counts.issue_count(), 0)
  assert_false(execution_status_requires_review(AwaitingAcceptance))
  assert_false(execution_status_needs_attention(AwaitingAcceptance))
  assert_false(execution_status_is_active_run(AwaitingAcceptance))
  assert_true(execution_feed_kind(AwaitingAcceptance) is QuietExecution)
  let cards = execution_stage_cards([execution])
  assert_eq(cards.length(), execution_stage_cards([]).length() + 1)
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(cards[cards.length() - 1]),
  )
  assert_true(html.contains("Acceptance pending"))
}

///|
test "module acceptance pending retains waiting aggregate with distinct status" {
  let kind = module_execution_status_kind(AwaitingAcceptance)
  assert_true(kind is Acceptance)
  assert_eq(module_runtime_status_label(kind), "Acceptance pending")
  assert_eq(module_runtime_status_class(kind), "module-status-waiting")
  let counts = module_runtime_counts_from_status_kind(kind)
  assert_eq(counts.waiting, 1)
  assert_eq(counts.running, 0)
  assert_eq(counts.review, 0)
  assert_eq(counts.completed, 0)
  assert_eq(counts.blocked, 0)
  assert_eq(
    module_projection_status_label(
      visual_module_fixture(status="acceptance-pending", waiting_count=1),
    ),
    "Acceptance pending",
  )
  let runtime = runtime_state_from_execution(
    civic_execution_policy_test_execution(AwaitingAcceptance),
    0,
    0,
  )
  assert_eq(runtime.status_label, "Acceptance pending")
  assert_eq(runtime.waiting_count, 1)
  assert_eq(runtime.review_count, 0)
  assert_eq(runtime.completed_count, 0)
}

///|
test "live wire acceptance pending validates and stays inactive while retaining result links" {
  let raw = @json.parse(
    energy_valley_runtime_test_projection_text(
      "1970-01-01T00:01:40.000Z", "live",
    ),
  )
  guard raw is Object(fields) else { fail("expected runtime object") }
  guard fields.get("tasks") is Some(Array(tasks)) && tasks[0] is Object(task) else {
    fail("expected task")
  }
  task["status"] = "awaiting_acceptance".to_json()
  guard fields.get("agents") is Some(Array(agents)) &&
    agents[0] is Object(agent) else {
    fail("expected agent")
  }
  agent["status"] = "idle".to_json()
  let state = energy_valley_runtime_state_from_text(
    raw.stringify(),
    1,
    110000.0,
  )
  assert_true(state.phase is Live)
  assert_true(energy_valley_runtime_work_status_is_valid("awaiting_acceptance"))
  assert_false(
    energy_valley_runtime_task_status_is_active("awaiting_acceptance"),
  )
  assert_false(ecosystem_runtime_status_is_active("awaiting_acceptance"))
  assert_true(ecosystem_runtime_behavior("awaiting_acceptance") is Rest)
  assert_eq(energy_valley_runtime_active_agents(state).length(), 0)
  let work = state.projection.unwrap().tasks[0]
  assert_eq(work.resultLinks.unwrap().length(), 1)
  assert_eq(
    golden_valley_primary_building_status([work]),
    "awaiting_acceptance",
  )
  assert_eq(town_chronicle_status_label(work.status), "Awaiting acceptance")
  assert_eq(town_chronicle_task_tone(state, work), "neutral")
  assert_true(
    town_chronicle_live_title(state, work).contains(
      "goal acceptance remains unevaluated",
    ),
  )
  assert_eq(
    resident_status_copy(Live, work.status),
    ("Awaiting acceptance", "is-waiting"),
  )
  let civic = wenyu_module_building_test_module()
  let runtime = runtime_state_from_energy_valley(state, civic, 0)
  assert_eq(runtime.status_label, "Acceptance pending")
  assert_eq(runtime.waiting_count, 1)
  assert_eq(runtime.running_count, 0)
  assert_eq(runtime.review_count, 0)
  assert_eq(runtime.completed_count, 0)
  assert_true(runtime.detail.contains("goal acceptance remains unevaluated"))
}
