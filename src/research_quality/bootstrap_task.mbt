///|
pub fn research_bootstrap_ingest_task(
  entry : @moonbook.BookCatalogEntry,
  goal : String,
) -> @moonbook.BookTask {
  let normalized_goal = goal.trim().to_owned()
  @moonbook.BookTask::new(
    id="goal-\{entry.id}-research-bootstrap-ingest",
    goal=Some(normalized_goal),
    title="Bootstrap verified research coverage",
    kind="ingest",
    prompt=research_bootstrap_ingest_prompt(),
    priority=100,
    requires_review=true,
    target_pages=research_bootstrap_ingest_target_pages(),
    required_role=Some(Harness),
  )
}

///|
fn research_bootstrap_ingest_prompt() -> String {
  research_bootstrap_prompt([
    research_bootstrap_scope_clause(),
    research_bootstrap_workflow_clause(),
    research_bootstrap_specificity_clause(),
  ])
}

///|
fn research_bootstrap_prompt(clauses : Array[String]) -> String {
  clauses.join(" ")
}

///|
fn research_bootstrap_scope_clause() -> String {
  "Bootstrap this book before answering the research question."
}

///|
fn research_bootstrap_workflow_clause() -> String {
  research_bootstrap_prompt([
    "Work as a researcher: formulate the lane-specific question.", "Run web search before local file search.",
    "Fetch and screen authoritative sources.", "Extract a claim-level evidence matrix.",
    "Inspect local files only after web discovery.", "Write a skill-authored marketing brief.",
    "Materialize verified source, entity, concept, and synthesis pages.",
  ])
}

///|
fn research_bootstrap_specificity_clause() -> String {
  research_bootstrap_prompt([
    "The result must be specific to this book lane, not generic MoonBook copy.",
    "every major claim must cite a source ID or local path.",
  ])
}

///|
pub fn research_bootstrap_ingest_target_pages() -> Array[String] {
  research_bootstrap_ingest_raw_pages() + research_bootstrap_ingest_wiki_pages()
}

///|
fn research_bootstrap_ingest_raw_pages() -> Array[String] {
  [
    "raw/bootstrap/research-question.md", "raw/bootstrap/search-log.md", "raw/bootstrap/source-screen.md",
    "raw/bootstrap/evidence-matrix.md", "raw/bootstrap/local-sources.md", "raw/bootstrap/synthesis-brief.md",
    "raw/bootstrap/marketing-brief.md",
  ]
}

///|
fn research_bootstrap_ingest_wiki_pages() -> Array[String] {
  [
    "wiki/sources", "wiki/entities", "wiki/concepts", "wiki/synthesis", "wiki/index.md",
    "wiki/log.md",
  ]
}
