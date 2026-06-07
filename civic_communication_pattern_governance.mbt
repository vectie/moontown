///|
fn triage_desk_pattern() -> CivicCommunicationPattern {
  {
    id: "triage-desk",
    title: "Triage Desk",
    category: "intake-routing",
    summary: "Requests enter one place, get classified, routed, escalated, or closed with an auditable reason.",
    protocol_mode: "intake-classify-route",
    input_contract: "request packet",
    reduction_contract: "routing decision",
    output_contract: "civic.triage.routing.v1",
    review_contract: "priority, owner, risk, missing input",
    cadence_hint: "continuous or operator-triggered",
    good_for: ["operator requests", "bug intake", "citizen service desks"],
    civic_examples: [
      "town operator inbox", "policy help desk", "civic service intake",
    ],
  }
}

///|
fn review_council_pattern() -> CivicCommunicationPattern {
  {
    id: "review-council",
    title: "Review Council",
    category: "quality-governance",
    summary: "Reviewers evaluate an artifact against criteria, produce accept/revise/reject decisions, and return concrete fixes.",
    protocol_mode: "submit-review-decide",
    input_contract: "artifact submission",
    reduction_contract: "review decision",
    output_contract: "civic.review.decision.v1",
    review_contract: "criteria fit, risk, evidence, actionability",
    cadence_hint: "after material artifacts are produced",
    good_for: [
      "research report review", "contest judging", "wiki promotion gates",
    ],
    civic_examples: [
      "research quality council", "innovation contest judges", "resident privacy review",
    ],
  }
}
