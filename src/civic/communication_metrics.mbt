///|
pub(all) struct CivicCommunicationMetricCounts {
  participant_count : Int
  idea_count : Int
  research_question_count : Int
  participant_idea_links : Int
  participating_book_coverage_count : Int
  idea_return_home_count : Int
} derive(Debug, Eq)

///|
pub fn civic_salon_metrics(
  scenario : CivicCommunicationScenario,
  participants : Array[CivicCommunicationParticipantBook],
  ideas : Array[CivicCommunicationIdea],
) -> CivicCommunicationMetric {
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
pub fn civic_salon_metric_counts(
  participants : Array[CivicCommunicationParticipantBook],
  ideas : Array[CivicCommunicationIdea],
) -> CivicCommunicationMetricCounts {
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
pub fn civic_salon_returned_ideas_for_book(
  book_id : String,
  ideas : Array[CivicCommunicationIdea],
) -> Array[CivicCommunicationIdea] {
  ideas.filter(fn(idea) { idea.participating_books.contains(book_id) })
}

///|
fn civic_salon_metric_summary(
  scenario : CivicCommunicationScenario,
  counts : CivicCommunicationMetricCounts,
) -> String {
  [
    "The pattern round converted \{counts.participant_count} \{scenario.domain_label} participant perspectives",
    "into \{counts.idea_count} reviewable outputs,",
    "\{counts.research_question_count} testable follow-up questions,",
    "and \{counts.idea_return_home_count} returned output-home records.",
  ].join(" ")
}

///|
fn civic_salon_average_books_per_idea_label(
  ideas : Array[CivicCommunicationIdea],
) -> String {
  if ideas.length() == 0 {
    "0"
  } else {
    let links = civic_salon_participant_idea_link_count(ideas)
    let scaled = links * 10 / ideas.length()
    "\{links}/\{ideas.length()} = \{scaled / 10}.\{scaled % 10}"
  }
}

///|
fn civic_salon_structural_score(
  participant_count~ : Int,
  idea_count~ : Int,
  research_question_count~ : Int,
  participating_book_coverage_count~ : Int,
  idea_return_home_count~ : Int,
  participant_idea_links~ : Int,
) -> Int {
  civic_salon_score_component(participant_count, 10, 20) +
  civic_salon_score_component(idea_count, 5, 20) +
  civic_salon_score_component(research_question_count, 15, 20) +
  civic_salon_score_component(
    participating_book_coverage_count, participant_count, 20,
  ) +
  civic_salon_score_component(
    idea_return_home_count, participant_idea_links, 20,
  )
}

///|
fn civic_salon_score_component(value : Int, target : Int, max : Int) -> Int {
  if target <= 0 {
    0
  } else if value >= target {
    max
  } else {
    value * max / target
  }
}

///|
fn civic_salon_research_question_count(
  ideas : Array[CivicCommunicationIdea],
) -> Int {
  let mut count = 0
  for idea in ideas {
    count += idea.research_questions.length()
  }
  count
}

///|
fn civic_salon_participant_idea_link_count(
  ideas : Array[CivicCommunicationIdea],
) -> Int {
  let mut count = 0
  for idea in ideas {
    count += idea.participating_books.length()
  }
  count
}

///|
fn civic_salon_covered_book_count(ideas : Array[CivicCommunicationIdea]) -> Int {
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
