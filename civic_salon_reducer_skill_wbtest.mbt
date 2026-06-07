///|
test "civic reducer skill names map-reduce role reduction rules and contract" {
  let text = civic_salon_reducer_skill_text(civic_reducer_skill_test_scenario())
  assert_true(text.contains("agentic map-reduce place"))
  assert_true(text.contains("## Reduction Rules"))
  assert_true(text.contains("Read every participant"))
  assert_true(text.contains("Use at least two participant workspaces"))
  assert_true(text.contains("Do not copy or consume template seed ideas"))
  assert_true(text.contains("Every output must name the home books"))
  assert_true(text.contains("CivicSalonIdea"))
  assert_true(text.contains("raw/bootstrap/civic-salon-ideas.json"))
}

///|
test "civic reducer skill examples distinguish good research service and poor output" {
  let examples = civic_salon_reducer_concrete_examples()
  assert_true(examples.contains("robotics research salon"))
  assert_true(examples.contains("world-model uncertainty"))
  assert_true(examples.contains("policy triage desk"))
  assert_true(examples.contains("official-source extraction plus review"))
  assert_true(examples.contains("A poor output merely says"))
  assert_true(examples.contains("checkable follow-up question"))
}

///|
fn civic_reducer_skill_test_scenario() -> CivicSalonScenario {
  {
    id: "test-research-salon",
    title: "Test Research Salon",
    communication_pattern_id: Some("research-salon"),
    communication_pattern_label: Some("Research Salon"),
    building_id: "test-building",
    building_book_id: "test-building-book",
    domain_label: "test domain",
    topic: "test exchange",
    cadence: "manual",
    interval_ms: None,
    skill_name: "test-reducer",
    skill_description: "Reduce test participant packets into reviewable outputs.",
    protocol_channel: "domain_perspective",
    reduction_kind: "cross_area_research_idea",
    output_channel: "returned_questions",
    review_gate: "keeper_review",
    review_owner: "keeper",
    review_reason: "keeper checks novelty and routing",
    backlog_path: "wiki/queries/test.md",
    synthesis_path: "wiki/civic/test.md",
    metrics_path: "wiki/metrics/test.md",
    review_path: "wiki/reviews/test.md",
    returned_ideas_path: "wiki/queries/returned.md",
    participant_contract_path: "raw/bootstrap/TEST_CONTRACT.md",
    quality_rules: ["Every output must be reviewable."],
    skill_rules: ["Map one concrete bottleneck."],
    participants: [],
    ideas: [],
  }
}
