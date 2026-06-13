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
    assert_true(service.target_pages.contains(civic_generated_site_path()))
    assert_true(!service.module_mode.is_empty())
    assert_true(!service.book_role.is_empty())
    assert_true(!service.skill_mode.is_empty())
    assert_true(!service.agent_work.is_empty())
    assert_true(!service.place_work.is_empty())
    assert_true(!service.acceptance.is_empty())
  }
}

///|
test "civic generated site path follows policy projection default" {
  assert_eq(
    civic_generated_site_path(),
    @policy.default_generated_site_projection_path(),
  )
  assert_eq(
    civic_generated_site_workspace_path("/tmp/civic"),
    "/tmp/civic/\{@policy.default_generated_site_projection_path()}",
  )
}

///|
test "Wenyu civic registry distinguishes workspaces from places" {
  let policy = wenyu_civic_service_for_book_id("wenyu-policy-hall").unwrap()
  let social = wenyu_civic_service_for_book_id("wenyu-social-square").unwrap()
  let market = wenyu_civic_service_for_book_id("wenyu-valley-market").unwrap()
  let bridge = wenyu_civic_service_for_book_id("wenyu-physical-bridge").unwrap()
  let tower = wenyu_civic_service_for_book_id("wenyu-vitality-dashboard").unwrap()
  assert_eq(policy.module_mode, "agent-workspace")
  assert_eq(social.module_mode, "exchange-place")
  assert_eq(market.module_mode, "exchange-place")
  assert_eq(bridge.module_mode, "gateway")
  assert_eq(tower.module_mode, "projection-surface")
  assert_true(social.place_work.any(fn(item) { item.contains("exchange") }))
  assert_true(!social.skill_mode.contains("research"))
}

///|
test "module ids and canonical book ids resolve to Wenyu services" {
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
test "civic package owns Wenyu build book eligibility" {
  assert_true(
    is_wenyu_book_entry("wenyu-policy-hall", "Policy Hall", ["civic-service"]),
  )
  assert_true(
    !is_wenyu_book_entry("custom-builder", "Custom Wenyu Builder", [
      "civic-service",
    ]),
  )
  assert_true(
    is_wenyu_build_book_entry("wenyu-custom-builder", "Custom Wenyu Builder", [
      "civic-service",
    ]),
  )
  assert_true(
    !is_wenyu_build_book_entry("wenyu-policy-hall", "Policy Hall", [
      "civic-service",
    ]),
  )
  assert_true(
    !is_wenyu_build_book_entry("custom-builder", "Custom Wenyu Builder", [
      "civic-service",
    ]),
  )
}

///|
test "civic task carries role skill and output contract prompt" {
  let service = wenyu_civic_service_for_book_id("wenyu-talent-avenue").unwrap()
  let task = wenyu_civic_service_task(service, "Build Wenyu civic town")
  assert_eq(task.kind, "civic-service-workflow")
  assert_true(task.prompt.contains(service.output_contract))
  assert_true(task.prompt.contains("Module mode"))
  assert_true(task.prompt.contains("not a generic research task"))
  assert_true(task.target_pages.contains(service.skill_path))
  assert_true(task.required_role == Some(service.worker_role))
}
