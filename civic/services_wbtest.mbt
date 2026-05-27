///|
test "Wenyu civic registry covers configured service modules" {
  let services = wenyu_civic_services()
  assert_eq(services.length(), 11)
  assert_true(services.any(fn(service) { service.id == "policy-hall" }))
  assert_true(services.any(fn(service) { service.id == "contest-express" }))
  assert_true(services.any(fn(service) { service.id == "social-square" }))
  assert_true(services.any(fn(service) { service.id == "talent-avenue" }))
  assert_true(services.any(fn(service) { service.id == "valley-market" }))
  assert_true(services.any(fn(service) { service.id == "broadcast-tower" }))
  assert_true(services.any(fn(service) { service.id == "ai-garden" }))
}

///|
test "Wenyu civic services expose book workspace and skill contracts" {
  for service in wenyu_civic_services() {
    assert_true(service.book_id.has_prefix("wenyu-"))
    assert_true(service.skill_path.has_suffix("/SKILL.md"))
    assert_true(service.output_contract.has_prefix("wenyu.civic."))
    assert_true(service.target_pages.contains(service.skill_path))
    assert_true(service.target_pages.contains("book/moonbook-ui-state.json"))
    assert_true(!service.acceptance.is_empty())
  }
}

///|
test "legacy module book ids resolve to canonical Wenyu books" {
  match wenyu_civic_service_for_book_id("policy-hall") {
    Some(service) => assert_eq(service.book_id, "wenyu-policy-hall")
    None => abort("expected policy service")
  }
  match wenyu_civic_service_for_book_id("wenyu-social-square") {
    Some(service) => assert_eq(service.id, "social-square")
    None => abort("expected social square service")
  }
}

///|
test "civic task carries role skill and output contract prompt" {
  let service = wenyu_civic_service_for_book_id("wenyu-talent-avenue").unwrap()
  let task = wenyu_civic_service_task(service, "Build Wenyu civic town")
  assert_eq(task.kind, "civic-service-workflow")
  assert_true(task.prompt.contains(service.output_contract))
  assert_true(task.target_pages.contains(service.skill_path))
  assert_eq(task.required_role, Some(service.worker_role))
}
