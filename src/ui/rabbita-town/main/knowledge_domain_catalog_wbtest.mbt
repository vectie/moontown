///|
fn knowledge_projection_fixture(
  acceptance_receipt : ProjectionAcceptanceReceipt?,
) -> BookProjectionFragment {
  {
    book_id: "research-fixture",
    title: "Fixture",
    summary: "Fixture projection",
    status_chips: [{ label: "completed and delivered", tone: "healthy" }],
    metrics: [],
    readiness: [],
    review_queue: [],
    page_families: [],
    journey: [
      {
        title: "Workspace",
        stage: "completed",
        status: "approved",
        summary: "Presentation text only",
        highlights: [],
      },
    ],
    links: [],
    acceptance_receipt,
  }
}

///|
fn valid_knowledge_acceptance_receipt() -> ProjectionAcceptanceReceipt {
  {
    contract_version: "moontown.moonbook.acceptance-receipt-projection.v1",
    decision: "accepted",
    decision_id: "decision-7",
    candidate_version: "candidate-v3",
    reviewer: "bookkeeper://named-reviewer",
    evidence_count: 4,
    issue_count: 0,
    requires_human_review: false,
    source_contract: "moonbook.bookkeeper.v1",
    source_projection: "moonbook.bookkeeper.ui.v1",
  }
}

///|
test "accepted-looking projection copy is not an acceptance receipt" {
  assert_false(
    knowledge_projection_is_explicitly_accepted(
      knowledge_projection_fixture(None),
    ),
  )
}

///|
test "catalog identity comparison fails closed on different bytes" {
  let digest = "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  assert_true(knowledge_domain_catalog_digest_matches(None, ""))
  assert_true(knowledge_domain_catalog_digest_matches(Some(digest), digest))
  assert_false(
    knowledge_domain_catalog_digest_matches(
      Some(digest),
      "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
    ),
  )
}

///|
test "explicit MoonBook acceptance receipt validates fail closed" {
  let receipt = valid_knowledge_acceptance_receipt()
  assert_true(
    knowledge_projection_is_explicitly_accepted(
      knowledge_projection_fixture(Some(receipt)),
    ),
  )
  assert_false(
    knowledge_projection_is_explicitly_accepted(
      knowledge_projection_fixture(Some({ ..receipt, evidence_count: 0 })),
    ),
  )
  assert_false(
    knowledge_projection_is_explicitly_accepted(
      knowledge_projection_fixture(
        Some({ ..receipt, requires_human_review: true }),
      ),
    ),
  )
}
