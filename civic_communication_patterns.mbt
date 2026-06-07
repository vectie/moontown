///|
pub fn civic_communication_patterns() -> Array[CivicCommunicationPattern] {
  [
    research_salon_pattern(),
    signal_watch_pattern(),
    triage_desk_pattern(),
    review_council_pattern(),
    match_market_pattern(),
    learning_cohort_pattern(),
    story_forge_pattern(),
    incident_bridge_pattern(),
  ]
}

///|
pub fn civic_communication_pattern_for_id(
  id : String,
) -> CivicCommunicationPattern? {
  let key = civic_pattern_key(id)
  for pattern in civic_communication_patterns() {
    if civic_pattern_key(pattern.id) == key {
      return Some(pattern)
    }
  }
  None
}

///|
fn civic_pattern_key(value : String) -> String {
  value.to_lower().trim().to_owned()
}
