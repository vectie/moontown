///|
fn civic_salon_metric_summary(
  scenario : CivicSalonScenario,
  counts : CivicSalonMetricCounts,
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
  ideas : Array[CivicSalonIdea],
) -> String {
  if ideas.length() == 0 {
    "0"
  } else {
    let links = civic_salon_participant_idea_link_count(ideas)
    let scaled = links * 10 / ideas.length()
    "\{links}/\{ideas.length()} = \{scaled / 10}.\{scaled % 10}"
  }
}
