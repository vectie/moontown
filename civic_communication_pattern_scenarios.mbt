///|
fn default_research_salon_pattern() -> CivicCommunicationPattern {
  research_salon_pattern()
}

///|
fn civic_salon_pattern_id(scenario : CivicSalonScenario) -> String {
  match scenario.communication_pattern_id {
    Some(id) => if id.trim().is_empty() { "research-salon" } else { id }
    None => "research-salon"
  }
}

///|
fn civic_salon_pattern_for_scenario(
  scenario : CivicSalonScenario,
) -> CivicCommunicationPattern {
  match civic_communication_pattern_for_id(civic_salon_pattern_id(scenario)) {
    Some(pattern) => pattern
    None => default_research_salon_pattern()
  }
}

///|
fn civic_salon_pattern_label(scenario : CivicSalonScenario) -> String {
  match scenario.communication_pattern_label {
    Some(label) =>
      if label.trim().is_empty() {
        civic_salon_pattern_for_scenario(scenario).title
      } else {
        label
      }
    None => civic_salon_pattern_for_scenario(scenario).title
  }
}
