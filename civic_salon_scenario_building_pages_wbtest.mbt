///|
test "civic salon building synthesis separates protocol structure from truth claims" {
  let scenario = building_pages_test_scenario()
  let protocol = civic_salon_generic_protocol_for_scenario(scenario)
  let participants = scenario.participants
  let ideas = scenario.ideas
  let metrics = civic_salon_metrics(scenario, participants, ideas)
  let markdown = civic_salon_building_synthesis(
    scenario, protocol, participants, ideas, metrics, "robotics-round-1", 1,
  )
  assert_true(
    markdown.contains(civic_salon_round_metadata("robotics-round-1", 1)),
  )
  assert_true(markdown.contains("## Participants"))
  assert_true(markdown.contains("## Reduced Pattern Outputs"))
  assert_true(markdown.contains("## Effectiveness Metrics"))
  assert_true(markdown.contains(civic_salon_structural_metric_note()))
  assert_true(markdown.contains("It does not claim the outputs are correct"))
}

///|
test "civic salon metrics markdown explains protocol effectiveness and return home" {
  let scenario = building_pages_test_scenario()
  let metrics = civic_salon_metrics(
    scenario,
    scenario.participants,
    scenario.ideas,
  )
  let markdown = civic_salon_metrics_markdown(
    scenario,
    metrics,
    scenario.participants,
    scenario.ideas,
    "robotics-round-1",
    1,
  )
  assert_true(markdown.contains(civic_salon_metrics_certification_note()))
  assert_true(markdown.contains("Structural effectiveness score"))
  assert_true(markdown.contains("## Formula"))
  assert_true(markdown.contains("## Return Home Contract"))
  assert_true(
    markdown.contains(civic_salon_return_home_contract_note(scenario)),
  )
  assert_true(markdown.contains("wiki/queries/returned.md"))
}

///|
test "civic salon metric tables keep participant output edges visible" {
  let scenario = building_pages_test_scenario()
  let metrics = civic_salon_metrics(
    scenario,
    scenario.participants,
    scenario.ideas,
  )
  let table = civic_salon_metrics_table(metrics)
  assert_true(table.contains("| Participant-output links | 2 |"))
  assert_true(table.contains("| Return-home records | 2 |"))
  let idea_table = civic_salon_idea_metric_table(scenario.ideas)
  assert_true(idea_table.contains("|Embodied Memory Contract|2|2|"))
  assert_true(idea_table.contains("`robot-brain`, `world-model`"))
}

///|
fn building_pages_test_scenario() -> CivicSalonScenario {
  {
    id: "embodied-robotics-salon",
    title: "Embodied Robotics Salon",
    communication_pattern_id: Some("research-salon"),
    communication_pattern_label: Some("Research Salon"),
    building_id: "robotics-square",
    building_book_id: "robotics-square-book",
    domain_label: "embodied robotics",
    topic: "robotics cross-area exchange",
    cadence: "weekly",
    interval_ms: None,
    skill_name: "robotics-salon",
    skill_description: "Reduce robotics perspectives into questions.",
    protocol_channel: "domain_perspective",
    reduction_kind: "cross_area_research_idea",
    output_channel: "returned_questions",
    review_gate: "keeper_review",
    review_owner: "keeper",
    review_reason: "keeper reviews novelty and feasibility",
    backlog_path: "wiki/queries/robotics.md",
    synthesis_path: "wiki/civic/robotics.md",
    metrics_path: "wiki/metrics/robotics.md",
    review_path: "wiki/reviews/robotics.md",
    returned_ideas_path: "wiki/queries/returned.md",
    participant_contract_path: "raw/bootstrap/ROBOTICS_CONTRACT.md",
    quality_rules: ["Every output must be reviewable."],
    skill_rules: ["Map one concrete bottleneck."],
    participants: [
      {
        book_id: "robot-brain",
        title: "Robot Brain Desk",
        focus_area: "robot brain",
        perspective: "Brains need memory and recovery.",
        cadence: "weekly",
        current_question: "What state should survive task handoff?",
        contribution: "Robot brain contributes planning and state.",
        next_artifact: "wiki/queries/robot-brain.md",
      },
      {
        book_id: "world-model",
        title: "World Model Desk",
        focus_area: "world models",
        perspective: "World models constrain action.",
        cadence: "weekly",
        current_question: "How should uncertainty be carried?",
        contribution: "World model contributes prediction and uncertainty.",
        next_artifact: "wiki/queries/world-model.md",
      },
    ],
    ideas: [
      {
        id: "embodied-memory",
        title: "Embodied Memory Contract",
        summary: "Connect robot memory and world models.",
        participating_books: ["robot-brain", "world-model"],
        research_questions: [
          "What memory survives task handoff?", "How should uncertainty be represented?",
        ],
        why_it_matters: "It turns a salon exchange into a protocol.",
        next_experiment: "Prototype a shared memory packet.",
      },
    ],
  }
}
