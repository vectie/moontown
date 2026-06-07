///|
fn bootstrap_ingest_task(
  entry : @moonbook.BookCatalogEntry,
  goal : String,
) -> @moonbook.BookTask {
  let normalized_goal = goal.trim().to_owned()
  let prompt = bootstrap_ingest_prompt(normalized_goal)
  @moonbook.BookTask::new(
    id="goal-\{entry.id}-research-bootstrap-ingest",
    goal=Some(normalized_goal),
    title=bootstrap_ingest_title(normalized_goal),
    kind="ingest",
    prompt~,
    priority=100,
    requires_review=true,
    target_pages=bootstrap_ingest_target_pages(),
    required_role=Some(@core.WorkerRole::Harness),
  )
}

///|
fn bootstrap_ingest_prompt(goal : String) -> String {
  if is_wenyu_valley_goal(goal) {
    return wenyu_bootstrap_ingest_prompt()
  }
  research_bootstrap_ingest_prompt()
}

///|
fn wenyu_bootstrap_ingest_prompt() -> String {
  bootstrap_prompt([
    wenyu_bootstrap_scope_clause(),
    wenyu_bootstrap_research_order_clause(),
    wenyu_bootstrap_output_clause(),
    wenyu_bootstrap_specificity_clause(),
  ])
}

///|
fn research_bootstrap_ingest_prompt() -> String {
  bootstrap_prompt([
    research_bootstrap_scope_clause(),
    research_bootstrap_workflow_clause(),
    research_bootstrap_specificity_clause(),
  ])
}

///|
fn bootstrap_prompt(clauses : Array[String]) -> String {
  clauses.join(" ")
}

///|
fn wenyu_bootstrap_scope_clause() -> String {
  bootstrap_prompt([
    "Bootstrap this Wenyu Valley module before implementation.", "Use `../../../docs/WENYU_VALLEY_PRD.md` as the primary contract from this book workspace.",
  ])
}

///|
fn wenyu_bootstrap_research_order_clause() -> String {
  "Run web search before local file search for comparable civic/AI innovation town patterns, then inspect local project files."
}

///|
fn wenyu_bootstrap_output_clause() -> String {
  bootstrap_prompt([
    "Produce lane-specific raw bootstrap artifacts, a claim-level evidence matrix, and module entities/concepts.",
    "Also produce implementation tasks, acceptance criteria, a risk list, and a marketing/product brief.",
  ])
}

///|
fn wenyu_bootstrap_specificity_clause() -> String {
  "The result must be specific to this Wenyu module and must not collapse all Wenyu modules into one generic page."
}

///|
fn research_bootstrap_scope_clause() -> String {
  "Bootstrap this book before answering the research question."
}

///|
fn research_bootstrap_workflow_clause() -> String {
  bootstrap_prompt([
    "Work as a researcher: formulate the lane-specific question.", "Run web search before local file search.",
    "Fetch and screen authoritative sources.", "Extract a claim-level evidence matrix.",
    "Inspect local files only after web discovery.", "Write a skill-authored marketing brief.",
    "Materialize verified source, entity, concept, and synthesis pages.",
  ])
}

///|
fn research_bootstrap_specificity_clause() -> String {
  bootstrap_prompt([
    "The result must be specific to this book lane, not generic MoonBook copy.",
    "every major claim must cite a source ID or local path.",
  ])
}

///|
fn bootstrap_ingest_title(goal : String) -> String {
  if is_wenyu_valley_goal(goal) {
    "Bootstrap Wenyu Valley module coverage"
  } else {
    "Bootstrap verified research coverage"
  }
}

///|
fn bootstrap_ingest_target_pages() -> Array[String] {
  bootstrap_ingest_raw_pages() + bootstrap_ingest_wiki_pages()
}

///|
fn bootstrap_ingest_raw_pages() -> Array[String] {
  [
    "raw/bootstrap/research-question.md", "raw/bootstrap/search-log.md", "raw/bootstrap/source-screen.md",
    "raw/bootstrap/evidence-matrix.md", "raw/bootstrap/local-sources.md", "raw/bootstrap/synthesis-brief.md",
    "raw/bootstrap/marketing-brief.md",
  ]
}

///|
fn bootstrap_ingest_wiki_pages() -> Array[String] {
  [
    "wiki/sources", "wiki/entities", "wiki/concepts", "wiki/synthesis", "wiki/index.md",
    "wiki/log.md",
  ]
}
