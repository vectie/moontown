///|
fn civic_communication_metrics(
  scenario : CivicCommunicationScenario,
  participants : Array[CivicCommunicationParticipantBook],
  ideas : Array[CivicCommunicationIdea],
) -> CivicCommunicationMetric {
  @civic.civic_communication_metrics(scenario, participants, ideas)
}

///|
fn civic_communication_returned_ideas_for_book(
  book_id : String,
  ideas : Array[CivicCommunicationIdea],
) -> Array[CivicCommunicationIdea] {
  @civic.civic_communication_returned_ideas_for_book(book_id, ideas)
}
