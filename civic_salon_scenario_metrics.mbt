///|
fn civic_salon_metrics(
  scenario : CivicSalonScenario,
  participants : Array[CivicSalonParticipantBook],
  ideas : Array[CivicSalonIdea],
) -> CivicSalonMetric {
  let counts = civic_salon_metric_counts(participants, ideas)
  let structural_effectiveness_score = civic_salon_structural_score(
    participant_count=counts.participant_count,
    idea_count=counts.idea_count,
    research_question_count=counts.research_question_count,
    participating_book_coverage_count=counts.participating_book_coverage_count,
    idea_return_home_count=counts.idea_return_home_count,
    participant_idea_links=counts.participant_idea_links,
  )
  {
    participant_count: counts.participant_count,
    idea_count: counts.idea_count,
    research_question_count: counts.research_question_count,
    participant_idea_links: counts.participant_idea_links,
    participating_book_coverage_count: counts.participating_book_coverage_count,
    idea_return_home_count: counts.idea_return_home_count,
    average_books_per_idea: civic_salon_average_books_per_idea_label(ideas),
    structural_effectiveness_score,
    summary: civic_salon_metric_summary(scenario, counts),
  }
}

///|
fn civic_salon_returned_ideas_for_book(
  book_id : String,
  ideas : Array[CivicSalonIdea],
) -> Array[CivicSalonIdea] {
  ideas.filter(fn(idea) { idea.participating_books.contains(book_id) })
}
