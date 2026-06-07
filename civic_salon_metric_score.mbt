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
