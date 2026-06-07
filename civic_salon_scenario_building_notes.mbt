///|
fn civic_salon_building_intro(
  pattern : CivicCommunicationPattern,
  protocol : @civic.BuildingProtocolDefinition,
) -> String {
  [
    "This is a live `\{pattern.title}` communication-pattern test for `\{protocol.title}` as a domain exchange building.",
    "Internal participant workspaces contribute focused perspectives,",
    "and the building reduces them into reviewable outputs and follow-up questions worth ongoing work.",
  ].join(" ")
}

///|
fn civic_salon_structural_metric_note() -> String {
  [
    "This metric is structural: it proves the building moved from exchange to reduction to distribution.",
    "It does not claim the outputs are correct;", "the review queue still decides which become accepted service work.",
  ].join(" ")
}

///|
fn civic_salon_metrics_certification_note() -> String {
  [
    "These metrics evaluate whether the building actually held an exchange, reduced new shared outputs, and returned them to the right home workspaces.",
    "They do not certify truth; they certify protocol effectiveness for this round.",
  ].join(" ")
}

///|
fn civic_salon_return_home_contract_note(
  scenario : CivicSalonScenario,
) -> String {
  [
    "Each participating workspace receives `\{scenario.returned_ideas_path}` with the reduced outputs relevant to its perspective.",
    "That page is the next place for each home workspace to review, accept, refine, or reject the pattern output.",
  ].join(" ")
}
