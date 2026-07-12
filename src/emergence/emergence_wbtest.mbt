///|
fn contribution(
  id : String,
  participant : String,
  origin : String,
  evidence? : Array[String] = ["evidence/\{id}.json"],
  claim? : String = "accepted-knowledge",
) -> CivicContribution {
  {
    contribution_id: id,
    participant_id: participant,
    source_book_id: "book-\{participant}",
    origin,
    summary: "Contribution \{id}",
    evidence_refs: evidence,
    alternatives: ["retain the baseline", "use a reduced mission"],
    blockers: [],
    implementation_criteria: ["the idea has a reproducible digital test"],
    claim_ceiling: claim,
    supports: [],
    proposal: { "idea": id },
  }
}

///|
fn qualified_round() -> AutonomousCivicRound {
  {
    contract_id: "moontown.autonomous-civic-round.v1",
    round_id: "round-robot-1",
    commission_id: "commission-robot-readiness",
    question: "Which robot idea should advance to digital implementation?",
    commissioned_agenda_ids: ["baseline"],
    comparison_criteria: [
      {
        criterion_id: "evidence",
        name: "evidence quality",
        definition: "Prefers traceable evidence and bounded claims.",
      },
    ],
    contributions: [
      contribution("baseline", "mobility-book", "commissioned"),
      contribution("adaptive-cache", "operations-book", "emergent"),
      contribution("not-ready", "safety-book", "dissenting"),
      contribution("reduced-mission", "power-book", "minority"),
    ],
    critiques: [
      {
        critique_id: "critique-cache-complexity",
        participant_id: "safety-book",
        target_contribution_id: "adaptive-cache",
        concern: "Recovery complexity needs a bounded scenario test.",
        evidence_refs: ["evidence/cache-risk.json"],
        severity: "major",
        resolved: false,
      },
    ],
    rankings: [
      {
        voter_id: "mobility-book",
        ordered_contribution_ids: [
          "adaptive-cache", "reduced-mission", "baseline", "not-ready",
        ],
        rationale: "The emergent idea has the strongest bounded digital value.",
      },
      {
        voter_id: "power-book",
        ordered_contribution_ids: [
          "reduced-mission", "adaptive-cache", "not-ready", "baseline",
        ],
        rationale: "Reduced mission remains a strong fallback.",
      },
    ],
    review: {
      reviewer_id: "constitutional-reviewer",
      decision: "accepted",
      evidence_refs: ["evidence/round-review.json"],
      note: "Promotion is digital-only and preserves dissent.",
    },
    deliveries: [
      {
        participant_id: "mobility-book",
        received: true,
        returned_home: true,
        receipt_ref: "receipts/mobility.json",
      },
      {
        participant_id: "operations-book",
        received: true,
        returned_home: true,
        receipt_ref: "receipts/operations.json",
      },
      {
        participant_id: "safety-book",
        received: true,
        returned_home: true,
        receipt_ref: "receipts/safety.json",
      },
      {
        participant_id: "power-book",
        received: true,
        returned_home: true,
        receipt_ref: "receipts/power.json",
      },
    ],
    requested_authority: "cognitive-maintenance",
    recorded_at: "2026-07-12T16:00:00+08:00",
  }
}

///|
test "autonomous round promotes an unseeded idea and preserves dissent" {
  let result = evaluate_autonomous_civic_round(qualified_round())
  guard result is Ok(round) else { fail("expected qualified civic round") }
  assert_true(round.accepted)
  assert_eq(round.winner_id, "adaptive-cache")
  assert_true(round.unseeded_idea_ids.contains("adaptive-cache"))
  assert_true(round.dissent_ids.contains("not-ready"))
  assert_true(round.minority_ids.contains("reduced-mission"))
  assert_eq(round.stage_receipts.length(), 9)
  assert_true(round.coalition_graph.length() >= 2)
}

///|
test "autonomous round requires explicit comparison criteria" {
  let missing = { ..qualified_round(), comparison_criteria: [] }
  assert_true(
    evaluate_autonomous_civic_round(missing) ==
    Err("round requires explicit comparison criteria"),
  )
}

///|
test "Mayor cannot promote external authority or physical claims" {
  let physical = { ..qualified_round(), requested_authority: "physical-effect" }
  assert_true(
    evaluate_autonomous_civic_round(physical) ==
    Err("Mayor cannot schedule external or physical authority"),
  )
  let overclaim = qualified_round()
  overclaim.contributions[1] = contribution(
    "adaptive-cache",
    "operations-book",
    "emergent",
    claim="physical-readiness",
  )
  let result = evaluate_autonomous_civic_round(overclaim)
  guard result is Ok(round) else { fail("expected typed rejected candidate") }
  assert_true(
    round.evaluations.any(evaluation => {
      evaluation.contribution_id == "adaptive-cache" &&
      evaluation.reasons.contains(
        "claim ceiling exceeds MoonTown knowledge authority",
      )
    }),
  )
}

///|
test "autonomy qualification requires unseeded emergence and dissent" {
  let top_down = qualified_round()
  top_down.commissioned_agenda_ids.push("adaptive-cache")
  top_down.contributions[2] = contribution(
    "not-ready", "safety-book", "commissioned",
  )
  let result = evaluate_autonomous_civic_round(top_down)
  guard result is Ok(round) else { fail("expected evaluated round") }
  assert_false(round.autonomous_round_qualified)
  assert_false(round.accepted)
  assert_eq(round.winner_id, "")
}

///|
test "blocking critique prevents candidate promotion until resolved" {
  let blocked = qualified_round()
  blocked.critiques[0] = {
    ..blocked.critiques[0],
    severity: "blocking",
    resolved: false,
  }
  let result = evaluate_autonomous_civic_round(blocked)
  guard result is Ok(round) else { fail("expected evaluated round") }
  let mut emergent : ContributionEvaluation? = None
  for evaluation in round.evaluations {
    if evaluation.contribution_id == "adaptive-cache" {
      emergent = Some(evaluation)
    }
  }
  guard emergent is Some(evaluation) else {
    fail("expected emergent evaluation")
  }
  assert_false(evaluation.qualified)
  assert_true(evaluation.reasons[0].contains("unresolved blocking critique"))
}
