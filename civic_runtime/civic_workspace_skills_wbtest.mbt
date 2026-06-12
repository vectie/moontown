///|
test "generic civic service skill preserves protocol-place rules" {
  let text = @civic.wenyu_civic_service_skill_text()
  assert_true(text.has_prefix("---\nname: wenyu-civic-service"))
  assert_true(text.contains("# Wenyu Civic Service Skill"))
  assert_true(text.contains("## Rules"))
  assert_true(text.contains("Treat the building as a protocol place"))
  assert_true(text.contains("Do not force every civic module into research"))
  assert_true(text.contains("Queue review for public, legal, financial"))
  assert_true(
    text.contains("Separate operational activity from domain progress"),
  )
  assert_true(text.contains("## Required Output Shape"))
  assert_true(text.contains("civic_service_decision: update | no_change"))
  assert_true(
    text.contains("changed_pages: comma-separated durable page paths"),
  )
  assert_true(text.contains("protocol_decision_basis"))
  assert_true(text.contains("projection_delta"))
  assert_true(text.contains("review_items: comma-separated"))
  assert_true(text.contains("do not treat generic operational retries"))
  assert_true(text.contains("## Concrete Example"))
}

///|
test "module civic skill preserves service-specific mode and output contract" {
  let service = @civic.wenyu_civic_service_for_book_id("wenyu-policy-hall").unwrap()
  let text = @civic.civic_module_skill_text(service)
  assert_true(text.has_prefix("---\nname: \{service.skill_pack}"))
  assert_true(text.contains("# \{service.title} Skill Pack"))
  assert_true(text.contains("- Module mode: `\{service.module_mode}`"))
  assert_true(
    text.contains("- Persistence mode: `\{service.persistence_mode}`"),
  )
  assert_true(text.contains("- Contract id: `\{service.output_contract}`"))
  assert_true(text.contains("## What To Decide"))
  assert_true(text.contains("Use imagination, curiosity, and judgment"))
  assert_true(text.contains("## Mode-Specific Output"))
  assert_true(text.contains("domain artifact"))
  assert_true(text.contains("## Concrete Example"))
  assert_true(text.contains("book/moonbook-ui-state.json"))
}

///|
test "civic mode output guidance does not default every module to research" {
  let service = @civic.wenyu_civic_service_for_book_id("wenyu-social-square").unwrap()
  assert_eq(service.module_mode, "exchange-place")
  let text = @civic.civic_module_skill_text(service)
  assert_true(text.contains("consent"))
  assert_true(text.contains("match"))
  assert_true(text.contains("review-gated"))
  assert_true(!text.contains("default to generic research"))
}

///|
test "civic skill example summary names mode pages and review gate" {
  let service = @civic.wenyu_civic_service_for_book_id("wenyu-policy-hall").unwrap()
  let text = @civic.civic_module_skill_text(service)
  assert_true(text.contains("Summary: \{service.title}"))
  assert_true(text.contains("`\{service.module_mode}`"))
  assert_true(text.contains("`\{service.skill_mode}`"))
  assert_true(text.contains("queued one review item"))
  assert_true(text.contains("public/user-facing service behavior"))
}
