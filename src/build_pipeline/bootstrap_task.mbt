///|
pub fn wenyu_bootstrap_ingest_task(
  entry : @moonbook.BookCatalogEntry,
  goal : String,
) -> @moonbook.BookTask {
  let normalized_goal = goal.trim().to_owned()
  @moonbook.BookTask::new(
    id="goal-\{entry.id}-research-bootstrap-ingest",
    goal=Some(normalized_goal),
    title="Bootstrap Wenyu Valley module coverage",
    kind="ingest",
    prompt=wenyu_bootstrap_ingest_prompt(),
    priority=100,
    requires_review=true,
    target_pages=wenyu_bootstrap_ingest_target_pages(),
    required_role=Some(Harness),
  )
}

///|
fn wenyu_bootstrap_ingest_prompt() -> String {
  wenyu_bootstrap_prompt([
    wenyu_bootstrap_scope_clause(),
    wenyu_bootstrap_research_order_clause(),
    wenyu_bootstrap_output_clause(),
    wenyu_bootstrap_specificity_clause(),
  ])
}

///|
fn wenyu_bootstrap_prompt(clauses : Array[String]) -> String {
  clauses.join(" ")
}

///|
fn wenyu_bootstrap_scope_clause() -> String {
  wenyu_bootstrap_prompt([
    "Bootstrap this Wenyu Valley module before implementation.", "Use `../../../docs/WENYU_VALLEY_PRD.md` as the primary contract from this book workspace.",
  ])
}

///|
fn wenyu_bootstrap_research_order_clause() -> String {
  "Run web search before local file search for comparable civic/AI innovation town patterns, then inspect local project files."
}

///|
fn wenyu_bootstrap_output_clause() -> String {
  wenyu_bootstrap_prompt([
    "Produce lane-specific raw bootstrap artifacts, a claim-level evidence matrix, and module entities/concepts.",
    "Also produce implementation tasks, acceptance criteria, a risk list, and a marketing/product brief.",
  ])
}

///|
fn wenyu_bootstrap_specificity_clause() -> String {
  "The result must be specific to this Wenyu module and must not collapse all Wenyu modules into one generic page."
}

///|
fn wenyu_bootstrap_ingest_target_pages() -> Array[String] {
  @research_quality.research_bootstrap_ingest_target_pages()
}
