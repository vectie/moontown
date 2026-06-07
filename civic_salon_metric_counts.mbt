///|
priv struct CivicSalonMetricCounts {
  participant_count : Int
  idea_count : Int
  research_question_count : Int
  participant_idea_links : Int
  participating_book_coverage_count : Int
  idea_return_home_count : Int
}

///|
fn civic_salon_metric_counts(
  participants : Array[CivicSalonParticipantBook],
  ideas : Array[CivicSalonIdea],
) -> CivicSalonMetricCounts {
  let participant_idea_links = civic_salon_participant_idea_link_count(ideas)
  {
    participant_count: participants.length(),
    idea_count: ideas.length(),
    research_question_count: civic_salon_research_question_count(ideas),
    participant_idea_links,
    participating_book_coverage_count: civic_salon_covered_book_count(ideas),
    idea_return_home_count: participant_idea_links,
  }
}

///|
fn civic_salon_research_question_count(ideas : Array[CivicSalonIdea]) -> Int {
  let mut count = 0
  for idea in ideas {
    count += idea.research_questions.length()
  }
  count
}

///|
fn civic_salon_participant_idea_link_count(
  ideas : Array[CivicSalonIdea],
) -> Int {
  let mut count = 0
  for idea in ideas {
    count += idea.participating_books.length()
  }
  count
}

///|
fn civic_salon_covered_book_count(ideas : Array[CivicSalonIdea]) -> Int {
  let covered : Array[String] = []
  for idea in ideas {
    for book_id in idea.participating_books {
      if !covered.contains(book_id) {
        covered.push(book_id)
      }
    }
  }
  covered.length()
}
