///|
async fn research_quality_gaps(
  entry : @moonbook.BookCatalogEntry,
) -> Array[String] {
  if !entry.id.has_prefix("research-") {
    return []
  }
  let root = @moonbook.workspace_root(entry)
  let required = [
    "raw/bootstrap/research-question.md", "raw/bootstrap/search-log.md", "raw/bootstrap/source-screen.md",
    "raw/bootstrap/evidence-matrix.md", "raw/bootstrap/local-sources.md", "raw/bootstrap/synthesis-brief.md",
    "raw/bootstrap/marketing-brief.md",
  ]
  let gaps : Array[String] = []
  for relative in required {
    if !@fs.exists("\{root}/\{relative}") {
      gaps.push("missing `\{relative}`")
    }
  }
  if !has_research_source_marker(root) {
    gaps.push("no verified research source digest marker in `wiki/sources/`")
  }
  let summary = Some(@moonbook.summarize_state(entry)) catch { _ => None }
  match summary {
    Some(summary) => {
      let readiness = ResearchReadiness::from_summary(summary)
      for gap in readiness.gaps {
        gaps.push(gap)
      }
    }
    None => gaps.push("MoonBook summary unavailable for typed readiness")
  }
  for gap in research_content_quality_gaps(entry, root) {
    gaps.push(gap)
  }
  gaps
}

///|
async fn research_content_quality_gaps(
  entry : @moonbook.BookCatalogEntry,
  root : String,
) -> Array[String] {
  let gaps : Array[String] = []
  let topic = entry.id.replace(old="research-", new="").to_lower()
  let brief_path = "\{root}/raw/bootstrap/synthesis-brief.md"
  let overview_path = "\{root}/wiki/synthesis/overview.md"
  let search_log_path = "\{root}/raw/bootstrap/search-log.md"
  let source_screen_path = "\{root}/raw/bootstrap/source-screen.md"
  let brief = read_optional_text(brief_path)
  let overview = read_optional_text(overview_path)
  let search_log = read_optional_text(search_log_path)
  let source_screen = read_optional_text(source_screen_path)
  match brief {
    Some(text) => {
      let lower = text.to_lower()
      if !lower.contains(topic) {
        gaps.push("synthesis brief is not lane-specific for `\{topic}`")
      }
      if lower.contains("require model/web enrichment") ||
        lower.contains("provisional findings") {
        gaps.push("synthesis brief still reports provisional-only research")
      }
    }
    None => ()
  }
  match overview {
    Some(text) => {
      let lower = text.to_lower()
      if lower.contains("web evidence is still provisional") ||
        lower.contains("should be refined by later review") {
        gaps.push("wiki synthesis still declares unresolved research review")
      }
    }
    None => ()
  }
  match search_log {
    Some(text) => {
      let lower = text.to_lower()
      if lower.contains("may enrich it later") {
        gaps.push("search log has only a planned/enrichment-pending web pass")
      }
    }
    None => ()
  }
  match source_screen {
    Some(text) => {
      let lower = text.to_lower()
      if lower.contains("provisional web candidates") &&
        !lower.contains("fetched web evidence") &&
        !lower.contains("verified web evidence") {
        gaps.push("web candidates were listed but not fetched and screened")
      }
    }
    None => ()
  }
  let deep_report_path = "\{root}/raw/bootstrap/deep-report.md"
  match read_optional_text(deep_report_path) {
    Some(text) =>
      for gap in deep_report_quality_gaps(entry, text) {
        gaps.push(gap)
      }
    None => gaps.push("missing `raw/bootstrap/deep-report.md`")
  }
  gaps
}

///|
fn deep_report_quality_gaps(
  entry : @moonbook.BookCatalogEntry,
  report : String,
) -> Array[String] {
  let gaps : Array[String] = []
  let lower = report.to_lower()
  let topic = entry.id.replace(old="research-", new="").to_lower()
  if !lower.contains("deep research analysis") {
    gaps.push("deep report title does not declare `Deep Research Analysis`")
  }
  if !lower.contains(topic) {
    gaps.push("deep report is not lane-specific for `\{topic}`")
  }
  let section_count = count_markdown_sections(report)
  if section_count < 8 {
    gaps.push(
      "deep report has only \{section_count} top-level sections; expected at least 8",
    )
  }
  if !lower.contains("## executive summary") {
    gaps.push("deep report is missing `## Executive Summary`")
  }
  if !markdown_has_table(report) {
    gaps.push("deep report is missing at least one comparison/evidence table")
  }
  if !lower.contains("```mermaid") {
    gaps.push("deep report is missing a Mermaid relationship diagram")
  }
  if contains_process_heavy_research_text(lower) {
    gaps.push("deep report still reads like a run log instead of research")
  }
  gaps
}

///|
fn count_markdown_sections(markdown : String) -> Int {
  let mut count = 0
  for line in markdown.split("\n") {
    let trimmed = line.trim().to_string()
    if trimmed.has_prefix("## ") {
      count += 1
    }
  }
  count
}

///|
fn markdown_has_table(markdown : String) -> Bool {
  for line in markdown.split("\n") {
    let trimmed = line.trim().to_string()
    if trimmed.has_prefix("|") && trimmed.contains("---") {
      return true
    }
  }
  false
}

///|
fn contains_process_heavy_research_text(lower : String) -> Bool {
  if lower.contains("pending enrichment") ||
    lower.contains("provisional-only") ||
    lower.contains("placeholder notes") ||
    lower.contains("placeholder output") ||
    lower.contains("placeholder-only") ||
    lower.contains("unable to access") ||
    lower.contains("i could not") {
    return true
  }
  let mut process_markers = 0
  if lower.contains("this run") {
    process_markers += 1
  }
  if lower.contains("the worker failed") ||
    lower.contains("the worker could not") ||
    lower.contains("worker log") {
    process_markers += 1
  }
  if lower.contains("tool output") {
    process_markers += 1
  }
  process_markers >= 2
}

///|
async fn has_research_source_marker(root : String) -> Bool {
  let listed = @integration.run_checked("find", [
    "\{root}/wiki/sources",
    "-type",
    "f",
    "-name",
    "*.md",
  ]) catch {
    _ => return false
  }
  for path in listed.stdout.split("\n") {
    let file = path.trim()
    if file.is_empty() {
      continue
    }
    let content = @fs.read_file(file).text() catch { _ => continue }
    if content.contains("Source type: verified source digest") ||
      content.contains("Evidence Matrix") ||
      content.contains("Claim ID") {
      return true
    }
  }
  false
}

///|
fn queue_research_quality_gate(
  state : @core.TownState,
  book_id : String,
  task_ids : Array[String],
  gaps : Array[String],
) -> Unit {
  let gap_summary = gaps.join("; ")
  let detail = "Research quality gate failed for \{book_id}: \{gap_summary}"
  let mut marked = 0
  for task_id in task_ids {
    match @core.find_execution(state, task_id) {
      Some(execution) =>
        if execution.status is @core.TaskExecutionStatus::Completed {
          let updated = copy_execution_with(
            execution,
            status=@core.TaskExecutionStatus::ReviewQueued,
            summary="\{execution.summary} / quality_gate_failed=\{gaps.length()}",
          )
          state.replace_execution(updated)
          state.replace_task(task_for_supervision(state, updated))
          sync_worker_from_execution(state, updated)
          marked += 1
        }
      None => ()
    }
  }
  state.record_event(
    @core.TownEvent::new(
      id="event-quality-\{book_id}",
      kind="review",
      detail="\{detail}; mayor marked \{marked} task(s) as review-queued.",
      related_book_id=Some(book_id),
    ),
  )
}

///|
fn queue_book_review_backlog(
  state : @core.TownState,
  book_id : String,
  task_ids : Array[String],
  pending_review_count : Int,
) -> Unit {
  let mut marked = 0
  for task_id in task_ids {
    match @core.find_execution(state, task_id) {
      Some(execution) =>
        if execution.status is @core.TaskExecutionStatus::Completed {
          let updated = copy_execution_with(
            execution,
            status=@core.TaskExecutionStatus::ReviewQueued,
            summary="\{execution.summary} / pending_review=\{pending_review_count}",
          )
          state.replace_execution(updated)
          state.replace_task(task_for_supervision(state, updated))
          sync_worker_from_execution(state, updated)
          marked += 1
        }
      None => ()
    }
  }
  if marked > 0 {
    state.record_event(
      @core.TownEvent::new(
        id="event-review-backlog-\{book_id}",
        kind="review",
        detail="Book \{book_id} still has \{pending_review_count} pending review items after execution; mayor marked \{marked} task(s) as review-queued.",
        related_book_id=Some(book_id),
      ),
    )
  }
}
