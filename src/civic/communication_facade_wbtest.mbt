///|
test "generic civic communication schedule facade delegates schedule policy" {
  let schedule = CivicSalonSchedule::new(
    id="robotics-salon",
    title="Robotics Communication Pattern",
    building_id="social-square",
    topic="robotics exchange",
    next_due_ms=10UL,
  )
  assert_true(!civic_communication_is_due(schedule, 9UL))
  assert_true(civic_communication_is_due(schedule, 10UL))
  assert_eq(civic_communication_round_id(schedule), "robotics-salon-round-1")
  let next = complete_civic_communication_schedule(
    schedule, 10UL, "robotics-salon-round-1", "completed",
  )
  assert_eq(next.round_count, 1)
  assert_eq(next.latest_summary, "completed")
}

///|
test "generic civic communication metrics facade keeps routing semantics" {
  let participant : CivicCommunicationParticipantBook = {
    book_id: "vla",
    title: "VLA",
    focus_area: "vision-language-action",
    perspective: "models",
    cadence: "30m",
    current_question: "How should embodied policies learn?",
    contribution: "Policy bottlenecks",
    next_artifact: "wiki/queries/vla.md",
  }
  let idea : CivicCommunicationIdea = {
    id: "vla-world-model",
    title: "VLA and world model uncertainty",
    summary: "Connect control policy failure to uncertainty.",
    participating_books: ["vla"],
    research_questions: ["Which uncertainty signal predicts failure?"],
    why_it_matters: "It creates a testable research loop.",
    next_experiment: "Build a failure replay benchmark.",
  }
  let scenario : CivicCommunicationScenario = {
    id: "robotics-salon",
    title: "Robotics Salon",
    communication_pattern_id: Some("research-salon"),
    communication_pattern_label: Some("Research Salon"),
    building_id: "social-square",
    building_book_id: "wenyu-social-square",
    domain_label: "robotics",
    topic: "embodied intelligence",
    cadence: "30m",
    interval_ms: None,
    skill_name: "robotics-salon",
    skill_description: "Reduce participant views.",
    protocol_channel: "domain_perspective",
    reduction_kind: "cross_area_idea",
    output_channel: "returned_questions",
    review_gate: "keeper_review",
    review_owner: "keeper",
    review_reason: "Review novelty.",
    backlog_path: "wiki/queries/backlog.md",
    synthesis_path: "wiki/civic/synthesis.md",
    metrics_path: "wiki/metrics/metrics.md",
    review_path: "wiki/reviews/review.md",
    returned_ideas_path: "wiki/queries/returned.md",
    participant_contract_path: "raw/bootstrap/CONTRACT.md",
    quality_rules: [],
    skill_rules: [],
    participants: [participant],
    ideas: [idea],
  }
  let metrics = civic_communication_metrics(scenario, [participant], [idea])
  assert_eq(metrics.participant_count, 1)
  assert_eq(metrics.idea_count, 1)
  assert_eq(
    civic_communication_returned_ideas_for_book("vla", [idea]).length(),
    1,
  )
}
