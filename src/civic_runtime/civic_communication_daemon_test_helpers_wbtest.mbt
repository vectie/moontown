///|
fn daemon_civic_communication_schedule(
  next_due_ms? : UInt64 = 0UL,
) -> CivicCommunicationSchedule {
  CivicCommunicationSchedule::new(
    id="future-energy-social-square",
    title="Future Energy Social Square Salon",
    building_id="social-square",
    topic="future energy",
    interval_ms=1_800_000UL,
    next_due_ms~,
    participant_book_ids=["future-energy-storage", "future-energy-grid-ai"],
  )
}

///|
fn daemon_civic_communication_scenario() -> CivicCommunicationScenario {
  {
    id: "future-energy-social-square",
    title: "Future Energy Social Square Salon",
    communication_pattern_id: Some("research-salon"),
    communication_pattern_label: Some("Research Salon"),
    building_id: "social-square",
    building_book_id: "wenyu-social-square",
    domain_label: "future energy",
    topic: "future energy cross-area exchange",
    cadence: "operator-triggered salon",
    interval_ms: None,
    skill_name: "future-energy-salon",
    skill_description: "Exchange future-energy perspectives and reduce them into testable research questions.",
    protocol_channel: "domain_perspective",
    reduction_kind: "cross_area_research_idea",
    output_channel: "research_question_backlog",
    review_gate: "research_program_quality",
    review_owner: "keeper",
    review_reason: "keeper reviews novelty, feasibility, evidence gaps, and owner books",
    backlog_path: "wiki/queries/future-energy-salon.md",
    synthesis_path: "wiki/civic/future-energy-salon.md",
    metrics_path: "wiki/metrics/future-energy-salon.md",
    review_path: "wiki/reviews/future-energy-salon.md",
    returned_ideas_path: "wiki/queries/salon-returned-ideas.md",
    participant_contract_path: "raw/bootstrap/FUTURE_ENERGY_SALON_CONTRACT.md",
    quality_rules: [
      "Every output must connect more than one participant book.", "Every idea must include a testable next experiment.",
    ],
    skill_rules: [
      "Bring one domain-specific bottleneck.", "Turn disagreements into questions rather than accepted facts.",
    ],
    participants: [
      {
        book_id: "future-energy-storage",
        title: "Storage Desk",
        focus_area: "long-duration storage",
        perspective: "Storage bottlenecks determine whether intermittent supply becomes useful capacity.",
        cadence: "operator-triggered salon",
        current_question: "Which storage constraints most change deployment economics?",
        contribution: "Storage contributes cost, duration, degradation, and siting constraints.",
        next_artifact: "wiki/queries/storage-constraints.md",
      },
      {
        book_id: "future-energy-grid-ai",
        title: "Grid AI Desk",
        focus_area: "grid forecasting and autonomous control",
        perspective: "Grid AI matters only when it respects physical constraints and operator trust.",
        cadence: "operator-triggered salon",
        current_question: "Which control decisions are safe enough for autonomy?",
        contribution: "Grid AI contributes forecasting, dispatch policy, and operator-review loops.",
        next_artifact: "wiki/queries/grid-ai-control.md",
      },
    ],
    ideas: [
      {
        id: "storage-grid-control-contract",
        title: "Storage-Grid Control Contract",
        summary: "Define the interface between long-duration storage constraints and AI grid-control decisions.",
        participating_books: ["future-energy-storage", "future-energy-grid-ai"],
        research_questions: [
          "Which storage constraints must a grid-control model see before dispatch?",
          "What operator review gate is needed before autonomous storage dispatch?",
        ],
        why_it_matters: "It turns a cross-domain dependency into a concrete protocol contract.",
        next_experiment: "Prototype a dispatch schema that carries duration, degradation, confidence, and review status.",
      },
    ],
  }
}
