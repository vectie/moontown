///|
test "Wenyu civic task includes service skill and projection target" {
  let entry = goal_run_wenyu_policy_hall_entry()
  let tasks = wenyu_build_tasks(entry, "Build Wenyu Valley")
  let service = tasks[0]
  assert_eq(service.kind, "civic-service-workflow")
  assert_true(
    service.target_pages.contains("skills/civic-policy-researcher/SKILL.md"),
  )
  assert_true(service.target_pages.contains("book/moonbook-ui-state.json"))
  assert_true(service.prompt.contains("wenyu.civic.policy_service.v1"))
}

///|
test "Wenyu civic service plan skips research bootstrap" {
  let entry = goal_run_wenyu_policy_hall_entry()
  let bootstrap_like_task = goal_run_wenyu_bootstrap_like_task()
  let plan = wenyu_civic_service_plan(
    entry,
    "Build Wenyu Valley AI Innovation Town",
    [bootstrap_like_task],
    1,
  )
  assert_true(!plan.bootstrap_active)
  assert_eq(plan.task_limit, 1)
  assert_eq(plan.tasks.length(), 1)
  assert_eq(plan.tasks[0].kind, "civic-service-workflow")
  assert_true(plan.tasks[0].prompt.contains("wenyu.civic.policy_service.v1"))
}
