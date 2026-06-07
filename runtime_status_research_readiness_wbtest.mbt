///|
test "research readiness exposes typed coverage gaps" {
  let summary = @moonbook.BookStateSummary::new(
    book_id="research-moonclaw",
    root="/tmp/research-moonclaw",
    page_count=2,
    source_count=0,
    entity_count=0,
    concept_count=0,
    pending_review_count=0,
    keeper_memory_count=0,
    keeper_working_count=0,
    evidence_count=0,
    summary="empty",
  )
  let readiness = ResearchReadiness::from_summary(summary)
  assert_true(!readiness.substantive_coverage_ready)
  assert_true(readiness.gaps.length() >= 4)
}

///|
test "research readiness reports pending review without treating it as coverage gap" {
  let summary = @moonbook.BookStateSummary::new(
    book_id="research-llm-training",
    root="/tmp/research-llm-training",
    page_count=8,
    source_count=2,
    source_page_count=2,
    verified_source_count=2,
    entity_count=1,
    entity_page_count=1,
    concept_count=1,
    concept_page_count=1,
    pending_review_count=1,
    keeper_memory_count=0,
    keeper_working_count=0,
    evidence_count=3,
    summary="ready with human review backlog",
  )
  let readiness = ResearchReadiness::from_summary(summary)
  assert_true(readiness.substantive_coverage_ready)
  assert_eq(readiness.pending_review_count, 1)
  assert_true(readiness.gaps.is_empty())
}
