///|
test "civic salon participant HTML renders page shell and participant work" {
  let scenario = test_participant_html_scenario()
  let participant = test_participant_html_book()
  let html = civic_communication_participant_html(
    scenario,
    participant,
    [],
    "round-1",
    1,
  )
  assert_true(html.has_prefix("<!doctype html>\n<html><head>"))
  assert_true(html.contains("<title>Robotics Brain Desk</title>"))
  assert_true(html.contains("<style>"))
  assert_true(html.contains("<code>Embodied Robotics Salon</code>"))
  assert_true(html.contains("<code>weekly</code>"))
  assert_true(html.contains("<code>round 1</code>"))
  assert_true(html.contains("<h1>Robotics Brain Desk</h1>"))
  assert_true(html.contains("<p><code>round-1</code></p>"))
  assert_true(html.contains("<h2>Contribution</h2>"))
  assert_true(html.contains("<h2>Question</h2>"))
  assert_true(html.contains("No returned outputs yet."))
  assert_true(html.has_suffix("</section></main></body></html>"))
}

///|
test "civic salon returned idea cards render count and next experiment" {
  let idea : CivicCommunicationIdea = {
    id: "idea-1",
    title: "Embodied Memory Contract",
    summary: "Connect robot memory, world models, and task planning.",
    participating_books: ["robotics-brain", "world-model"],
    research_questions: [
      "What memory survives task handoff?", "How should uncertainty be represented?",
    ],
    why_it_matters: "It turns salon discussion into a testable interface.",
    next_experiment: "Prototype a memory packet shared across two robot tasks.",
  }
  let cards = civic_communication_returned_output_cards([idea])
  assert_true(cards.contains("<article>"))
  assert_true(cards.contains("<h3>Embodied Memory Contract</h3>"))
  assert_true(cards.contains("Follow-up questions:</strong> 2"))
  assert_true(cards.contains("Prototype a memory packet"))
}

///|
fn test_participant_html_scenario() -> CivicCommunicationScenario {
  {
    id: "embodied-robotics-salon",
    title: "Embodied Robotics Salon",
    communication_pattern_id: Some("research-salon"),
    communication_pattern_label: Some("Research Salon"),
    building_id: "social-square",
    building_book_id: "robotics-social-square",
    domain_label: "embodied robotics",
    topic: "embodied robotics exchange",
    cadence: "weekly",
    interval_ms: None,
    skill_name: "robotics-salon",
    skill_description: "Exchange robotics perspectives into research questions.",
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
    participants: [],
    ideas: [],
  }
}

///|
fn test_participant_html_book() -> CivicCommunicationParticipantBook {
  {
    book_id: "robotics-brain",
    title: "Robotics Brain Desk",
    focus_area: "robot brain",
    perspective: "Robot intelligence needs memory, action, and recovery loops.",
    cadence: "weekly",
    current_question: "What state should the robot brain persist?",
    contribution: "Robot brain contributes planning, state tracking, and review gates.",
    next_artifact: "wiki/queries/robot-brain.md",
  }
}
