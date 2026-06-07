///|
test "generic civic service skill preserves protocol-place rules" {
  let text = wenyu_civic_service_skill_text()
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
  assert_true(text.contains(civic_accepted_facts_accounting_rule()))
  assert_true(text.contains("## Concrete Example"))
}

///|
test "module civic skill preserves service-specific mode and output contract" {
  let service = @civic.wenyu_civic_service_for_book_id("wenyu-policy-hall").unwrap()
  let text = civic_module_skill_text(service)
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
  assert_true(text.contains(civic_mode_output_guidance(service)))
  assert_true(text.contains("## Concrete Example"))
  assert_true(text.contains("book/moonbook-ui-state.json"))
}

///|
test "civic mode output guidance does not default every module to research" {
  let service = @civic.wenyu_civic_service_for_book_id("wenyu-social-square").unwrap()
  assert_eq(service.module_mode, "exchange-place")
  let guidance = civic_mode_output_guidance(service)
  assert_true(guidance.contains("consent"))
  assert_true(guidance.contains("match"))
  assert_true(guidance.contains("review-gated"))
  assert_true(!guidance.contains("generic research"))
}

///|
test "civic skill example summary names mode pages and review gate" {
  let service = @civic.wenyu_civic_service_for_book_id("wenyu-policy-hall").unwrap()
  let summary = civic_skill_example_summary(
    service, "wiki/civic/policy.md", "wiki/reviews/policy.md",
  )
  assert_true(summary.contains("Summary: \{service.title}"))
  assert_true(summary.contains("`\{service.module_mode}`"))
  assert_true(summary.contains("`\{service.skill_mode}`"))
  assert_true(summary.contains("updated `wiki/civic/policy.md`"))
  assert_true(summary.contains("queued one review item"))
  assert_true(summary.contains("public/user-facing service behavior"))
}
