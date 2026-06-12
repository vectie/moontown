///|
fn civic_salon_metrics(
  scenario : CivicSalonScenario,
  participants : Array[CivicSalonParticipantBook],
  ideas : Array[CivicSalonIdea],
) -> CivicSalonMetric {
  @civic.civic_salon_metrics(scenario, participants, ideas)
}

///|
fn civic_salon_returned_ideas_for_book(
  book_id : String,
  ideas : Array[CivicSalonIdea],
) -> Array[CivicSalonIdea] {
  @civic.civic_salon_returned_ideas_for_book(book_id, ideas)
}
