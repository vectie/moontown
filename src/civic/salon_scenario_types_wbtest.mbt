///|
test "salon scenario DTOs round-trip as civic package data" {
  let scenario : CivicSalonScenario = {
    id: "robotics-salon",
    title: "Robotics Research Salon",
    communication_pattern_id: Some("research-salon"),
    communication_pattern_label: Some("Research Salon"),
    building_id: "social-square",
    building_book_id: "wenyu-social-square",
    domain_label: "robotics",
    topic: "embodied AI",
    cadence: "30m",
    interval_ms: Some(1_800_000UL),
    skill_name: "robotics-salon",
    skill_description: "Reduce robotics perspectives into questions.",
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
    quality_rules: ["specific question"],
    skill_rules: ["use participant tension"],
    participants: [
      {
        book_id: "vla",
        title: "VLA Desk",
        focus_area: "vision-language-action",
        perspective: "Policy needs embodiment checks.",
        cadence: "30m",
        current_question: "Where does VLA fail?",
        contribution: "VLA contributes action priors.",
        next_artifact: "wiki/queries/vla-failure.md",
      },
    ],
    ideas: [
      {
        id: "embodiment-gate",
        title: "Embodiment Gate",
        summary: "Add a gate between policy priors and robot action.",
        participating_books: ["vla"],
        research_questions: ["Which priors fail under morphology constraints?"],
        why_it_matters: "It makes action safety testable.",
        next_experiment: "Draft a benchmark card.",
      },
    ],
  }
  let parsed : CivicSalonScenario = @json.from_json(scenario.to_json()) catch {
    _ => fail("expected scenario JSON to decode")
  }
  assert_eq(parsed.id, "robotics-salon")
  assert_eq(parsed.participants[0].book_id, "vla")
  assert_eq(parsed.ideas[0].id, "embodiment-gate")
}

///|
test "salon reduction modes expose constructors across package boundary" {
  let mode = CivicSalonReductionMode::FixtureReducer
  assert_true(mode is CivicSalonReductionMode::FixtureReducer)
}

///|
test "salon scenario policy resolves pattern defaults and labels" {
  let scenario = {
    id: "robotics-salon",
    title: "Robotics Research Salon",
    communication_pattern_id: None,
    communication_pattern_label: Some(""),
    building_id: "social-square",
    building_book_id: "wenyu-social-square",
    domain_label: "robotics",
    topic: "embodied AI",
    cadence: "30m",
    interval_ms: Some(1_800_000UL),
    skill_name: "robotics-salon",
    skill_description: "Reduce robotics perspectives into questions.",
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
    quality_rules: ["specific question"],
    skill_rules: ["use participant tension"],
    participants: [],
    ideas: [],
  }
  assert_eq(communication_pattern_id_for_scenario(scenario), "research-salon")
  assert_eq(communication_pattern_for_scenario(scenario).id, "research-salon")
  assert_eq(
    communication_pattern_label_for_scenario(scenario),
    "Research Salon",
  )
}

///|
test "salon scenario policy builds building protocol from pattern contract" {
  let scenario = {
    id: "robotics-salon",
    title: "Robotics Research Salon",
    communication_pattern_id: Some("match-market"),
    communication_pattern_label: None,
    building_id: "social-square",
    building_book_id: "wenyu-social-square",
    domain_label: "robotics",
    topic: "embodied AI",
    cadence: "30m",
    interval_ms: Some(1_800_000UL),
    skill_name: "robotics-salon",
    skill_description: "Reduce robotics perspectives into questions.",
    protocol_channel: "market_exchange",
    reduction_kind: "match_reduction",
    output_channel: "matched_requests",
    review_gate: "match_review",
    review_owner: "robotics-bookkeeper",
    review_reason: "new market match",
    backlog_path: "wiki/queries/salon-backlog.md",
    synthesis_path: "wiki/synthesis/salon.md",
    metrics_path: "wiki/metrics/salon.md",
    review_path: "wiki/reviews/salon.md",
    returned_ideas_path: "wiki/queries/salon-returned-ideas.md",
    participant_contract_path: "wiki/contributions/current-perspective.md",
    quality_rules: ["specific question"],
    skill_rules: ["use participant tension"],
    participants: [],
    ideas: [],
  }
  let protocol = communication_protocol_for_scenario(scenario)
  assert_eq(protocol.building_id, "social-square")
  assert_eq(protocol.service_id, "robotics-salon")
  assert_eq(protocol.protocol_mode, "aggregate-match-distribute")
  assert_eq(protocol.skill_packs.length(), 2)
  assert_eq(protocol.skill_packs[0], "match-market")
  assert_eq(protocol.skill_packs[1], "robotics-salon")
  let intro = communication_building_intro(
    communication_pattern_for_scenario(scenario),
    protocol,
  )
  assert_true(intro.contains("Robotics Research Salon"))
  assert_true(intro.contains("domain exchange building"))
}
