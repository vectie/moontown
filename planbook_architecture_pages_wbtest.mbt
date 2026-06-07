///|
test "planbook contract preserves role and growth boundaries" {
  let contract = planbook_contract_markdown()
  assert_true(contract.contains("# Planbook Contract"))
  assert_true(contract.contains(planbook_worker_residency_rule()))
  assert_true(contract.contains(planbook_bookkeeper_residency_rule()))
  assert_true(contract.contains(planbook_role_boundary_rule()))
  assert_true(contract.contains("book-scoped watcher slot"))
  assert_true(contract.contains("Buildings are protocol places"))
  assert_true(contract.contains("Durable growth must be visible"))
}

///|
test "planbook role model keeps mayor bookkeeper worker separation" {
  let role_model = planbook_role_model_markdown()
  assert_true(role_model.contains("## Mayor"))
  assert_true(role_model.contains("## MoonBook Bookkeeper"))
  assert_true(role_model.contains("## MoonClaw Worker"))
  assert_true(role_model.contains("Does not own: domain truth"))
  assert_true(role_model.contains("durable wiki promotion"))
  assert_true(role_model.contains("freelance executor"))
  assert_true(role_model.contains("update this PlanBook before coding"))
}

///|
test "planbook operating architecture treats buildings as document protocols" {
  let architecture = planbook_operating_architecture_markdown()
  assert_true(
    architecture.contains("Durable state lives in MoonBook documents"),
  )
  assert_true(architecture.contains("Active behavior is a protocol"))
  assert_true(architecture.contains("target MoonBook or building protocol"))
  assert_true(architecture.contains(planbook_civic_wiring_rule()))
  assert_true(architecture.contains("return-home rule"))
}

///|
test "planbook growth contract rejects operational churn as progress" {
  let growth = planbook_growth_contract_section().join("\n")
  assert_true(growth.contains("accepted pages"))
  assert_true(growth.contains("PlanBook backlog items"))
  assert_true(growth.contains("PlanBook repair loop"))
  assert_true(growth.contains("UI projections refresh"))
  assert_true(growth.contains(planbook_operational_activity_accounting_rule()))
}

///|
test "planbook stable watch state defines quiet healthy autonomy" {
  let stable = planbook_stable_watch_state_section().join("\n")
  assert_true(stable.contains("healthy watching, not permanent motion"))
  assert_true(stable.contains("active workers zero"))
  assert_true(stable.contains("PlanBook open gaps zero"))
  assert_true(stable.contains("review queues visible"))
  assert_true(stable.contains("do not block the live loop"))
}
