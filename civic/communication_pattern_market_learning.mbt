///|
pub fn match_market_pattern() -> CivicCommunicationPattern {
  {
    id: "match-market",
    title: "Match Market",
    category: "matching-exchange",
    summary: "Needs, offers, constraints, and trust signals are aggregated, matched, and distributed as introductions or deal rooms.",
    protocol_mode: "aggregate-match-distribute",
    input_contract: "need/offer packet",
    reduction_contract: "match proposal",
    output_contract: "civic.match.proposal.v1",
    review_contract: "fit, consent, conflict, next action",
    cadence_hint: "hourly to weekly",
    good_for: [
      "talent matching", "marketplace offers", "mentor-founder matching",
    ],
    civic_examples: [
      "talent graph", "social matching square", "startup resource market",
    ],
  }
}

///|
pub fn learning_cohort_pattern() -> CivicCommunicationPattern {
  {
    id: "learning-cohort",
    title: "Learning Cohort",
    category: "education-workflow",
    summary: "Learners, mentors, and content workspaces exchange progress, generate lessons, assign exercises, and review outcomes.",
    protocol_mode: "assess-teach-practice-review",
    input_contract: "learner progress packet",
    reduction_contract: "lesson and exercise plan",
    output_contract: "civic.learning.plan.v1",
    review_contract: "skill gap, exercise quality, measurable outcome",
    cadence_hint: "daily or weekly",
    good_for: ["course generation", "workshop cohorts", "skill ladders"],
    civic_examples: [
      "youth innovation class", "robotics workshop", "AI builder bootcamp",
    ],
  }
}
