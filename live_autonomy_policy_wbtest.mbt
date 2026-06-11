///|
test "live autonomy blocker helpers keep subsystem order explicit" {
  let context = live_autonomy_blocker_context_fixture(
    active_workers=1,
    review=2,
    blocked=3,
    failed=4,
    due_goals=5,
    planbook_open=6,
    planbook_repair_active=7,
    pending_book_template_requests=8,
    failed_book_template_requests=9,
  )
  let blockers = @live_autonomy_policy.live_autonomy_stable_waiting_blockers_for(
    context,
  )
  assert_eq(
    blockers.join("\n"),
    [
      "active workers or executions: 1", "review queue: 2", "blocked or unhealthy items: 3",
      "unresolved failures: 4", "due standing goals: 5", "PlanBook open gaps: 6",
      "PlanBook active repairs: 7", "pending book-template requests: 8", "failed book-template requests: 9",
    ].join("\n"),
  )
}

///|
test "live autonomy action helpers keep subsystem precedence explicit" {
  let workflow = @live_autonomy_policy.live_autonomy_next_actions_for(
    live_autonomy_action_context_fixture(blocked=1, review=1, due_goals=1),
  )
  assert_eq(
    workflow[0],
    "Mayor should recover blocked or stale work before dispatching more tasks.",
  )
  assert_eq(workflow[2], "Dispatch due standing goals on the next daemon tick.")
  let planbook_repair = @live_autonomy_policy.live_autonomy_next_actions_for(
    live_autonomy_action_context_fixture(
      planbook_open=4,
      planbook_repair_active=1,
    ),
  )
  assert_true(planbook_repair[0].contains("active self-repair packet"))
  assert_true(planbook_repair[1].contains("Town is watching"))
  let template_failed = @live_autonomy_policy.live_autonomy_next_actions_for(
    live_autonomy_action_context_fixture(
      pending_book_template_requests=3,
      failed_book_template_requests=1,
    ),
  )
  assert_true(template_failed[0].contains("Inspect failed book-template"))
  assert_true(template_failed[1].contains("Town is watching"))
}

///|
test "live autonomy watcher and idle action helpers isolate terminal decisions" {
  let update_actions = @live_autonomy_policy.live_autonomy_next_actions_for({
    blockers: live_autonomy_blocker_context_fixture(),
    latest_watcher_decision: Some(@core.WatcherDecisionKind::Update),
    transient_infrastructure_debt: 0,
  })
  assert_true(update_actions[0].contains("Promote the latest watcher update"))
  let deferred_actions = @live_autonomy_policy.live_autonomy_next_actions_for({
    blockers: live_autonomy_blocker_context_fixture(),
    latest_watcher_decision: Some(@core.WatcherDecisionKind::Deferred),
    transient_infrastructure_debt: 0,
  })
  assert_true(deferred_actions[0].contains("Latest watcher is deferred"))
  let idle_actions = @live_autonomy_policy.live_autonomy_next_actions_for(
    live_autonomy_action_context_fixture(transient_infrastructure_debt=2),
  )
  assert_eq(idle_actions.length(), 2)
  assert_true(idle_actions[0].contains("Historical transient infrastructure"))
  let deferred_idle = @live_autonomy_policy.live_autonomy_next_actions_for({
    blockers: live_autonomy_blocker_context_fixture(),
    latest_watcher_decision: Some(@core.WatcherDecisionKind::Deferred),
    transient_infrastructure_debt: 2,
  })
  assert_eq(deferred_idle.length(), 1)
  assert_true(deferred_idle[0].contains("Latest watcher is deferred"))
}
