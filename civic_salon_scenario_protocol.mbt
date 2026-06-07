///|
fn civic_salon_generic_protocol_for_scenario(
  scenario : CivicSalonScenario,
) -> @civic.BuildingProtocolDefinition {
  let pattern = civic_salon_pattern_for_scenario(scenario)
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
