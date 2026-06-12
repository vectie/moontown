///|
pub fn salon_pattern_id(scenario : CivicSalonScenario) -> String {
  match scenario.communication_pattern_id {
    Some(id) => if id.trim().is_empty() { "research-salon" } else { id }
    None => "research-salon"
  }
}

///|
pub fn salon_pattern_for_scenario(
  scenario : CivicSalonScenario,
) -> CivicCommunicationPattern {
  match civic_communication_pattern_for_id(salon_pattern_id(scenario)) {
    Some(pattern) => pattern
    None => research_salon_pattern()
  }
}

///|
pub fn salon_pattern_label(scenario : CivicSalonScenario) -> String {
  match scenario.communication_pattern_label {
    Some(label) =>
      if label.trim().is_empty() {
        salon_pattern_for_scenario(scenario).title
      } else {
        label
      }
    None => salon_pattern_for_scenario(scenario).title
  }
}

///|
pub fn salon_protocol_for_scenario(
  scenario : CivicSalonScenario,
) -> BuildingProtocolDefinition {
  let pattern = salon_pattern_for_scenario(scenario)
  {
    building_id: scenario.building_id,
    service_id: scenario.id,
    title: scenario.title,
    book_id: scenario.building_book_id,
    protocol_mode: pattern.protocol_mode,
    persistence_mode: "ledger-backed",
    social_responsibility: pattern.summary,
    participant_roles: [
      pattern.input_contract,
      pattern.reduction_contract,
      "review-gate",
    ],
    input_channels: [scenario.protocol_channel],
    output_channels: [scenario.output_channel],
    aggregation_policy: "Accept participant packets from the scenario template only; do not infer hidden participants.",
    exchange_policy: pattern.summary,
    reduction_policy: pattern.reduction_contract,
    distribution_policy: "Return each accepted pattern output to the building backlog and the participating home workspaces.",
    review_gates: [scenario.review_gate],
    privacy_scope: "book-public",
    moonbook_role: "building-surface",
    skill_packs: [pattern.id, scenario.skill_name],
    projection_contract: pattern.output_contract,
  }
}

///|
pub fn salon_building_intro(
  pattern : CivicCommunicationPattern,
  protocol : BuildingProtocolDefinition,
) -> String {
  [
    "This is a live `\{pattern.title}` communication-pattern test for `\{protocol.title}` as a domain exchange building.",
    "Internal participant workspaces contribute focused perspectives,",
    "and the building reduces them into reviewable outputs and follow-up questions worth ongoing work.",
  ].join(" ")
}

///|
pub fn salon_structural_metric_note() -> String {
  [
    "This metric is structural: it proves the building moved from exchange to reduction to distribution.",
    "It does not claim the outputs are correct;", "the review queue still decides which become accepted service work.",
  ].join(" ")
}

///|
pub fn salon_metrics_certification_note() -> String {
  [
    "These metrics evaluate whether the building actually held an exchange, reduced new shared outputs, and returned them to the right home workspaces.",
    "They do not certify truth; they certify protocol effectiveness for this round.",
  ].join(" ")
}

///|
pub fn salon_return_home_contract_note(scenario : CivicSalonScenario) -> String {
  [
    "Each participating workspace receives `\{scenario.returned_ideas_path}` with the reduced outputs relevant to its perspective.",
    "That page is the next place for each home workspace to review, accept, refine, or reject the pattern output.",
  ].join(" ")
}
