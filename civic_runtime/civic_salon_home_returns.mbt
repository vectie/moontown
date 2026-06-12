///|
fn civic_salon_home_return_records(
  scenario : CivicSalonScenario,
  building_id : String,
  ideas : Array[CivicSalonIdea],
  round_id? : String = "civic-salon-round-001",
) -> Array[CivicSalonHomeReturn] {
  let records : Array[CivicSalonHomeReturn] = []
  for idea in ideas {
    for book_id in idea.participating_books {
      records.push({
        id: "home-\{round_id}-\{idea.id}-\{book_id}",
        building_id,
        idea_id: idea.id,
        target_book_id: book_id,
        target_path: scenario.returned_ideas_path,
        summary: "Returned `\{idea.title}` to \{book_id} for review and follow-up work.",
        review_status: "pending",
      })
    }
  }
  records
}
