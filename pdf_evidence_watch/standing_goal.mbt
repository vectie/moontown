///|
fn pdf_evidence_watch_standing_goal(
  book_id : String,
  title : String,
  purpose : String,
  websites : Array[String],
  cadence_ticks : Int,
) -> @core.StandingGoal {
  @core.StandingGoal::new(
    id=pdf_evidence_watch_goal_id(book_id),
    title="Watch PDFs for \{title}",
    prompt=pdf_evidence_watch_goal_prompt(title, purpose, websites),
    target_book_id=Some(book_id),
    cadence_ticks~,
    next_due_tick=0,
    source_policy="web-first",
    quality_threshold=90,
  )
}

///|
fn upsert_pdf_evidence_watch_standing_goal(
  goals : Array[@core.StandingGoal],
  goal : @core.StandingGoal,
) -> Array[@core.StandingGoal] {
  standing_goal_registry_upsert(goals, goal)
}

///|
fn pdf_evidence_watch_goal_in(
  goals : Array[@core.StandingGoal],
  goal_id : String,
) -> Bool {
  standing_goal_registry_contains(goals, goal_id)
}

///|
fn pdf_evidence_watch_goal_enabled_in(
  goals : Array[@core.StandingGoal],
  goal_id : String,
) -> Bool {
  standing_goal_registry_enabled(goals, goal_id)
}

///|
fn pdf_evidence_watch_goal_id(book_id : String) -> String {
  "watch-\{book_id}-pdfs"
}

///|
fn pdf_evidence_watch_goal_prompt(
  title : String,
  purpose : String,
  websites : Array[String],
) -> String {
  [
    "Run the PDF Evidence Watch workflow for `\{title}`.",
    "",
    "Purpose: \{purpose}",
    "",
    "Configured websites:",
    if websites.is_empty() {
      "- none yet; ask Moondesk/user configuration for approved sites before fetching"
    } else {
      markdown_bullets(websites)
    },
    "",
    "Required loop:",
    "- search configured websites for new or changed PDFs before local reuse",
    "- download approved PDFs into `raw/pdfs/`",
    "- extract text, tables, figures, metadata, and provenance into `raw/extracted/`",
    "- analyze with `wiki/methods/analysis-method.md` and book-local skills",
    "- write durable source cards under `wiki/sources/`",
    "- promote only accepted new knowledge under `wiki/findings/`",
    "- update `wiki/history/standing-watch.md` with checked sources, accepted facts, rejected facts, and notification status",
    "- notify the operator only when accepted domain knowledge changes",
  ].join("\n")
}
