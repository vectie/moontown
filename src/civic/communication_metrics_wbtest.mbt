///|
test "communication metrics count exchange yield and returned-home links" {
  let participants = [
    communication_metric_test_participant("vla"),
    communication_metric_test_participant("world-model"),
  ]
  let ideas = [
    {
      id: "embodiment-gate",
      title: "Embodiment Gate",
      summary: "Connect policy and prediction limits.",
      participating_books: ["vla", "world-model"],
      research_questions: [
        "Which VLA priors fail under morphology constraints?", "Which world-model warning should veto action?",
      ],
      why_it_matters: "It makes cross-book tension testable.",
      next_experiment: "Draft a benchmark card.",
    },
  ]
  let scenario = communication_metric_test_scenario(participants, ideas)
  let counts = civic_communication_metric_counts(participants, ideas)
  let metrics = civic_communication_metrics(scenario, participants, ideas)
  assert_eq(counts.participant_count, 2)
  assert_eq(counts.idea_count, 1)
  assert_eq(counts.research_question_count, 2)
  assert_eq(counts.participant_idea_links, 2)
  assert_eq(counts.participating_book_coverage_count, 2)
  assert_eq(counts.idea_return_home_count, 2)
  assert_eq(metrics.average_books_per_idea, "2/1 = 2.0")
  assert_eq(metrics.structural_effectiveness_score, 90)
  assert_true(metrics.summary.contains("robotics participant perspectives"))
}

///|
test "declared three-book salon can reach structural completion" {
  let participants = [
    communication_metric_test_participant("environment"),
    communication_metric_test_participant("mobility"),
    communication_metric_test_participant("simulation"),
  ]
  let ideas = [
    communication_metric_test_idea("gates", participants),
    communication_metric_test_idea("blockers", participants),
    communication_metric_test_idea("replay", participants),
  ]
  let scenario = communication_metric_test_scenario(participants, ideas)
  let metrics = civic_communication_metrics(scenario, participants, ideas)
  assert_eq(metrics.structural_effectiveness_score, 100)
}

///|
test "returned ideas filter by home book" {
  let ideas = [
    {
      id: "shared",
      title: "Shared Idea",
      summary: "",
      participating_books: ["vla", "world-model"],
      research_questions: [],
      why_it_matters: "",
      next_experiment: "",
    },
  ]
  assert_eq(
    civic_communication_returned_ideas_for_book("vla", ideas).length(),
    1,
  )
  assert_eq(
    civic_communication_returned_ideas_for_book("locomotion", ideas).length(),
    0,
  )
}

///|
fn communication_metric_test_participant(
  book_id : String,
) -> CivicCommunicationParticipantBook {
  {
    book_id,
    title: book_id,
    focus_area: book_id,
    perspective: "Perspective",
    cadence: "30m",
    current_question: "Question",
    contribution: "Contribution",
    next_artifact: "wiki/queries/\{book_id}.md",
  }
}

///|
fn communication_metric_test_scenario(
  participants : Array[CivicCommunicationParticipantBook],
  ideas : Array[CivicCommunicationIdea],
) -> CivicCommunicationScenario {
  {
    id: "robotics-salon",
    title: "Robotics Salon",
    communication_pattern_id: Some("research-salon"),
    communication_pattern_label: Some("Research Salon"),
    building_id: "social-square",
    building_book_id: "wenyu-social-square",
    domain_label: "robotics",
    topic: "embodied AI",
    cadence: "30m",
    interval_ms: None,
    skill_name: "robotics-salon",
    skill_description: "Reduce robotics ideas.",
    protocol_channel: "research_exchange",
    reduction_kind: "idea_reduction",
    output_channel: "returned_ideas",
    review_gate: "novelty_review",
    review_owner: "robotics-bookkeeper",
    review_reason: "new research idea",
    backlog_path: "wiki/queries/salon-backlog.md",
    synthesis_path: "wiki/synthesis/salon.md",
    metrics_path: "wiki/metrics/salon.md",
    review_path: "wiki/reviews/salon.md",
    returned_ideas_path: "wiki/queries/salon-returned-ideas.md",
    participant_contract_path: "wiki/contributions/current-perspective.md",
    quality_rules: [],
    skill_rules: [],
    participants,
    ideas,
  }
}

///|
fn communication_metric_test_idea(
  id : String,
  participants : Array[CivicCommunicationParticipantBook],
) -> CivicCommunicationIdea {
  {
    id,
    title: id,
    summary: "Cross-book output",
    participating_books: participants.map(participant => participant.book_id),
    research_questions: ["What is the gate?", "How is it replayed?"],
    why_it_matters: "It joins the declared desks.",
    next_experiment: "Run the bounded check.",
  }
}
