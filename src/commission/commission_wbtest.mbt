///|
fn candidate(
  id : String,
  safety : Double,
  utility : Double,
) -> CommissionCandidate {
  {
    candidate_id: id,
    summary: "independent candidate " + id,
    source_book_ids: ["book-" + id],
    artifact_refs: ["artifact-" + id],
    ratings: [
      {
        criterion_id: "safety",
        score: safety,
        evidence_refs: ["evidence-" + id + "-safety"],
        rationale: "tested",
      },
      {
        criterion_id: "utility",
        score: utility,
        evidence_refs: ["evidence-" + id + "-utility"],
        rationale: "compared",
      },
    ],
    proposal: { "design_id": id },
  }
}

///|
test "Town commission promotes the strongest qualified evidence-backed candidate" {
  let result = evaluate_commission({
    contract_id: "moonsuite.town-commission.v1",
    commission_id: "commission-1",
    question: "Which design should proceed?",
    criteria: [
      { criterion_id: "safety", weight: 2.0, minimum_score: 7.0 },
      { criterion_id: "utility", weight: 1.0, minimum_score: 5.0 },
    ],
    candidates: [candidate("a", 8.0, 6.0), candidate("b", 9.0, 8.0)],
  })
  guard result is Ok(promotion) else { fail("expected promotion") }
  assert_true(promotion.accepted)
  assert_eq(promotion.winner_id, "b")
  assert_true(promotion.source_book_ids == ["book-b"])
}

///|
test "Town commission does not promote candidates below explicit gates" {
  let result = evaluate_commission({
    contract_id: "moonsuite.town-commission.v1",
    commission_id: "commission-2",
    question: "Which design should proceed?",
    criteria: [
      { criterion_id: "safety", weight: 1.0, minimum_score: 9.0 },
      { criterion_id: "utility", weight: 1.0, minimum_score: 9.0 },
    ],
    candidates: [candidate("a", 8.0, 6.0), candidate("b", 7.0, 8.0)],
  })
  guard result is Ok(promotion) else { fail("expected a rejected promotion") }
  assert_false(promotion.accepted)
  assert_eq(promotion.winner_id, "")
}
