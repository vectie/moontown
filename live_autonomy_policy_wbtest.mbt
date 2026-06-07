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
  assert_eq(live_autonomy_workflow_blockers(context).length(), 4)
  assert_eq(
    live_autonomy_workflow_blockers(context)[0],
    "active workers or executions: 1",
  )
  assert_eq(
    live_autonomy_standing_goal_blockers(context).join("\n"),
    ["due standing goals: 5"].join("\n"),
  )
  assert_eq(
    live_autonomy_planbook_blockers(context).join("\n"),
    ["PlanBook open gaps: 6", "PlanBook active repairs: 7"].join("\n"),
  )
  assert_eq(
    live_autonomy_template_request_blockers(context).join("\n"),
    ["pending book-template requests: 8", "failed book-template requests: 9"].join(
      "\n",
    ),
  )
  assert_eq(
    live_autonomy_stable_waiting_blockers_for(context).join("\n"),
    [
      "active workers or executions: 1", "review queue: 2", "blocked or unhealthy items: 3",
      "unresolved failures: 4", "due standing goals: 5", "PlanBook open gaps: 6",
      "PlanBook active repairs: 7", "pending book-template requests: 8", "failed book-template requests: 9",
    ].join("\n"),
  )
}

///|
test "live autonomy string append helper preserves order" {
  let target = ["a"]
  append_live_autonomy_strings(target, ["b", "c"])
  assert_eq(target.join(","), "a,b,c")
}

///|
test "live autonomy action helpers keep subsystem precedence explicit" {
  let workflow = live_autonomy_workflow_actions(
    live_autonomy_action_context_fixture(blocked=1, review=1, due_goals=1),
  )
  assert_eq(workflow.length(), 3)
  assert_eq(
    workflow[0],
    "Mayor should recover blocked or stale work before dispatching more tasks.",
  )
  assert_eq(workflow[2], "Dispatch due standing goals on the next daemon tick.")
  let planbook_repair = live_autonomy_planbook_actions(
    live_autonomy_action_context_fixture(
      planbook_open=4,
      planbook_repair_active=1,
    ),
  )
  assert_eq(planbook_repair.length(), 1)
  assert_true(planbook_repair[0].contains("active self-repair packet"))
  let template_failed = live_autonomy_template_request_actions(
    live_autonomy_action_context_fixture(
      pending_book_template_requests=3,
      failed_book_template_requests=1,
    ),
  )
  assert_eq(template_failed.length(), 1)
  assert_true(template_failed[0].contains("Inspect failed book-template"))
}

///|
test "live autonomy watcher and idle action helpers isolate terminal decisions" {
  let update_actions = live_autonomy_watcher_decision_actions(
    Some(@core.WatcherDecisionKind::Update),
  )
  assert_true(update_actions[0].contains("Promote the latest watcher update"))
  let deferred_actions = live_autonomy_watcher_decision_actions(
    Some(@core.WatcherDecisionKind::Deferred),
  )
  assert_true(deferred_actions[0].contains("Latest watcher is deferred"))
  let idle_actions = live_autonomy_idle_actions(
    live_autonomy_action_context_fixture(transient_infrastructure_debt=2),
    None,
  )
  assert_eq(idle_actions.length(), 2)
  assert_true(idle_actions[0].contains("Historical transient infrastructure"))
  let deferred_idle = live_autonomy_idle_actions(
    live_autonomy_action_context_fixture(transient_infrastructure_debt=2),
    Some(@core.WatcherDecisionKind::Deferred),
  )
  assert_true(deferred_idle.is_empty())
}
