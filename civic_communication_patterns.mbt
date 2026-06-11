///|
pub fn civic_communication_patterns() -> Array[@civic.CivicCommunicationPattern] {
  @civic.civic_communication_patterns()
}

///|
pub fn civic_communication_pattern_for_id(
  id : String,
) -> @civic.CivicCommunicationPattern? {
  @civic.civic_communication_pattern_for_id(id)
}
