///|
test "distinct reviewer sees submitted cards without private fields" {
  let (state, owner, reviewer, reader) = test_state_with_sessions()
  let drafted = marketplace_upsert_agent_draft(
    state,
    owner,
    test_agent_draft(),
    now_ms=100UL,
  )
  let submitted = marketplace_transition_listing(
    drafted,
    owner,
    AgentListing,
    "agent.robot-guide",
    PublicationSubmitted,
    review_summary="ready for review",
    now_ms=110UL,
  )
  let owner_queue = marketplace_listing_review_queue(submitted, owner)
  assert_true(owner_queue.stringify().contains("\"result_count\":0"))
  let reviewer_queue = marketplace_listing_review_queue(submitted, reviewer)
  let review_text = reviewer_queue.stringify()
  assert_true(review_text.contains("agent.robot-guide"))
  assert_true(review_text.contains("publication-review-card.v1"))
  assert_true(review_text.contains("\"result_count\":1"))
  assert_true(!review_text.contains("private_memory"))
  assert_true(!review_text.contains("host_path"))
  try marketplace_listing_review_queue(submitted, reader) catch {
    _ => ()
  } noraise {
    _ => fail("reader must not receive the publication review queue")
  }
}
