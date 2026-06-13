///|
fn civic_salon_metrics_table(metrics : CivicCommunicationMetric) -> String {
  [
    "| Metric | Value | Meaning |",
    "| --- | ---: | --- |",
    "| Structural effectiveness score | \{metrics.structural_effectiveness_score}/100 | Exchange-reduce-distribute completion, not truth certification |",
    "| Participant perspectives | \{metrics.participant_count} | Distinct internal perspectives in the pattern round |",
    "| Output reductions | \{metrics.idea_count} | New reviewable outputs produced by the building |",
    "| Follow-up questions | \{metrics.research_question_count} | Testable questions attached to those outputs |",
    "| Participant-output links | \{metrics.participant_idea_links} | Cross-pollination edges between outputs and home workspaces |",
    "| Covered workspaces | \{metrics.participating_book_coverage_count} | Home workspaces receiving at least one returned output |",
    "| Return-home records | \{metrics.idea_return_home_count} | Output-to-book distributions written back home |",
    "| Average workspaces per output | \{metrics.average_books_per_idea} | Breadth of each reduced output |",
  ].join("\n")
}

///|
fn civic_salon_idea_metric_table(
  ideas : Array[CivicCommunicationIdea],
) -> String {
  let builder = StringBuilder::new()
  builder.write_string(
    "| Output | Workspaces | Questions | Home workspaces |\n",
  )
  builder.write_string("| --- | ---:| ---:| --- |\n")
  for idea in ideas {
    builder.write_string(
      "|\{idea.title}|\{idea.participating_books.length()}|\{idea.research_questions.length()}|`\{idea.participating_books.join("`, `")}`|\n",
    )
  }
  builder.to_string().trim().to_owned()
}

///|
fn civic_salon_participant_table(
  participants : Array[CivicCommunicationParticipantBook],
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("| Workspace | Focus | Current Question |\n")
  builder.write_string("| --- | --- | --- |\n")
  for participant in participants {
    builder.write_string(
      "|\{participant.book_id}|\{participant.focus_area}|\{participant.current_question}|\n",
    )
  }
  builder.to_string().trim().to_owned()
}
