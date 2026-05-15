///|
async fn research_quality_gaps(
  entry : @moonbook.BookCatalogEntry,
) -> Array[String] {
  if !entry.id.has_prefix("research-") && !is_wenyu_book(entry) {
    return []
  }
  let root = @moonbook.workspace_root(entry)
  let required = if is_wenyu_book(entry) {
    [
      "raw/bootstrap/research-question.md", "raw/bootstrap/search-log.md", "raw/bootstrap/source-screen.md",
      "raw/bootstrap/evidence-matrix.md", "raw/bootstrap/local-sources.md", "raw/bootstrap/synthesis-brief.md",
      "raw/bootstrap/marketing-brief.md", "raw/bootstrap/deep-report.md", "raw/bootstrap/WENYU_VALLEY_PRD.md",
      "mounted-sources/MANIFEST.md",
    ]
  } else {
    [
      "raw/bootstrap/research-question.md", "raw/bootstrap/search-log.md", "raw/bootstrap/source-screen.md",
      "raw/bootstrap/evidence-matrix.md", "raw/bootstrap/local-sources.md", "raw/bootstrap/synthesis-brief.md",
      "raw/bootstrap/marketing-brief.md",
    ]
  }
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
  let topic = quality_topic_for_entry(entry)
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
  for gap in research_wiki_materialization_gaps(entry, root, topic) {
    gaps.push(gap)
  }
  for gap in research_generated_site_gaps(root, topic) {
    gaps.push(gap)
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
  let topic = quality_topic_for_entry(entry)
  if !lower.contains("deep research analysis") {
    gaps.push("deep report title does not declare `Deep Research Analysis`")
  }
  if !lower.contains(topic) {
    gaps.push("deep report is not lane-specific for `\{topic}`")
  }
  if is_external_quality_topic(topic) {
    for gap in external_domain_report_gaps(topic, lower) {
      gaps.push(gap)
    }
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
fn is_external_quality_topic(topic : String) -> Bool {
  match topic {
    "opc" => true
    _ => false
  }
}

///|
fn external_domain_report_gaps(topic : String, lower : String) -> Array[String] {
  let gaps : Array[String] = []
  if topic == "opc" {
    if lower.contains("vectie/opc") ||
      lower.contains("github.com/vectie/opc") ||
      lower.contains("/workspace/opc") {
      gaps.push(
        "OPC report incorrectly treats the lane as a Vectie/local repository",
      )
    }
    if lower.contains("moonbit package") || lower.contains("moon.mod.json") {
      gaps.push(
        "OPC report incorrectly treats the lane as a MoonBit software package",
      )
    }
    if !lower.contains("one person company") &&
      !lower.contains("one-person company") {
      gaps.push(
        "OPC report does not anchor the topic as One Person Company research",
      )
    }
  }
  gaps
}

///|
async fn research_wiki_materialization_gaps(
  entry : @moonbook.BookCatalogEntry,
  root : String,
  topic : String,
) -> Array[String] {
  ignore(entry)
  if !is_external_quality_topic(topic) {
    return []
  }
  let gaps : Array[String] = []
  if topic == "opc" {
    if has_external_topic_runtime_entity_contamination(root) {
      gaps.push(
        "OPC wiki materialization promoted Moon* runtime entities instead of only OPC domain entities",
      )
    }
    let aliases = topic_page_aliases(topic)
    if !directory_has_topic_named_page(root, "wiki/entities", aliases) {
      gaps.push(
        "missing OPC-specific durable entity page under `wiki/entities/`",
      )
    }
    if !directory_has_topic_named_page(root, "wiki/concepts", aliases) {
      gaps.push(
        "missing OPC-specific durable concept page under `wiki/concepts/`",
      )
    }
    if !directory_has_topic_source_page(root, aliases) {
      gaps.push(
        "missing OPC-specific durable source coverage under `wiki/sources/`",
      )
    }
  }
  gaps
}

///|
async fn research_generated_site_gaps(
  root : String,
  topic : String,
) -> Array[String] {
  if !is_external_quality_topic(topic) {
    return []
  }
  let gaps : Array[String] = []
  let generated_path = "\{root}/book/site/generated/index.html"
  if !@fs.exists(generated_path) {
    gaps.push(
      "missing live generated marketing projection at `book/site/generated/index.html`",
    )
    return gaps
  }
  let html = @fs.read_file(generated_path).text() catch {
    _ => {
      gaps.push("generated marketing projection could not be read")
      return gaps
    }
  }
  let lower = html.to_lower()
  if lower.contains("llm wiki website") ||
    lower.contains("markdown. wiki. website.") ||
    lower.contains("turn a maintained knowledge workspace") {
    gaps.push(
      "generated marketing projection is still the generic MoonBook scaffold",
    )
  }
  if lower.contains("marketing brief needed") ||
    lower.contains("missing: raw/bootstrap") {
    gaps.push(
      "generated marketing projection is diagnostic instead of buyer-facing",
    )
  }
  if !projection_contains_topic(lower, topic) {
    gaps.push(
      "generated marketing projection is not topic-specific for `\{topic}`",
    )
  }
  if !lower.contains("deep research") ||
    !lower.contains("deep research analysis") ||
    !lower.contains("executive summary") ||
    !lower.contains("report-table") {
    gaps.push(
      "generated marketing projection does not embed the deep research article",
    )
  }
  for gap in research_site_entry_gaps(root, topic) {
    gaps.push(gap)
  }
  gaps
}

///|
async fn research_site_entry_gaps(
  root : String,
  topic : String,
) -> Array[String] {
  let gaps : Array[String] = []
  let entry_path = "\{root}/book/site/index.html"
  if !@fs.exists(entry_path) {
    gaps.push("missing default marketing entrypoint at `book/site/index.html`")
    return gaps
  }
  let html = @fs.read_file(entry_path).text() catch {
    _ => {
      gaps.push("default marketing entrypoint could not be read")
      return gaps
    }
  }
  let lower = html.to_lower()
  if lower.contains("llm wiki website") ||
    lower.contains("markdown. wiki. website.") ||
    lower.contains("turn a maintained knowledge workspace") {
    gaps.push(
      "default marketing entrypoint is still the generic MoonBook scaffold",
    )
  }
  if !lower.contains("./generated/index.html") &&
    !projection_contains_topic(lower, topic) {
    gaps.push(
      "default marketing entrypoint does not open a topic-specific generated projection",
    )
  }
  gaps
}

///|
fn projection_contains_topic(lower : String, topic : String) -> Bool {
  for topic_alias in topic_page_aliases(topic) {
    if lower.contains(topic_alias.to_lower()) {
      return true
    }
  }
  false
}

///|
fn topic_page_aliases(topic : String) -> Array[String] {
  if topic == "opc" {
    ["opc", "one-person-company", "one person company", "one-person company"]
  } else {
    [topic, topic.replace(old="-", new=" ").to_string()]
  }
}

///|
async fn has_external_topic_runtime_entity_contamination(root : String) -> Bool {
  for name in ["moonclaw", "moonbook", "moontown"] {
    if @fs.exists("\{root}/wiki/entities/\{name}.md") {
      return true
    }
  }
  false
}

///|
async fn directory_has_topic_named_page(
  root : String,
  relative_dir : String,
  aliases : Array[String],
) -> Bool {
  let listed = @integration.run_checked("find", [
    "\{root}/\{relative_dir}",
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
    let lower_name = path_basename(file.to_string()).to_lower()
    for page_alias in aliases {
      if lower_name.contains(page_alias) {
        return true
      }
    }
  }
  false
}

///|
async fn directory_has_topic_source_page(
  root : String,
  aliases : Array[String],
) -> Bool {
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
    let lower_name = path_basename(file.to_string()).to_lower()
    let lower_content = @fs.read_file(file).text().to_lower() catch { _ => "" }
    for page_alias in aliases {
      if lower_name.contains(page_alias) || lower_content.contains(page_alias) {
        return true
      }
    }
  }
  false
}

///|
fn quality_topic_for_entry(entry : @moonbook.BookCatalogEntry) -> String {
  if entry.id.has_prefix("research-") {
    entry.id.replace(old="research-", new="").to_lower()
  } else if entry.id.has_prefix("wenyu-") {
    entry.id.replace(old="wenyu-", new="").replace(old="-", new=" ").to_lower()
  } else {
    entry.id.to_lower()
  }
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
fn complete_recovered_research_bootstrap_if_clean(
  state : @core.TownState,
  book_id : String,
  task_ids : Array[String],
) -> Unit {
  if !book_id.has_prefix("research-") {
    return
  }
  let mut recovered = 0
  for task_id in task_ids {
    if !task_id.contains("research-bootstrap-ingest") {
      continue
    }
    match @core.find_execution(state, task_id) {
      Some(execution) =>
        if execution.status is @core.TaskExecutionStatus::Failed ||
          execution.status is @core.TaskExecutionStatus::Stale {
          let updated = copy_execution_with(
            execution,
            status=@core.TaskExecutionStatus::Completed,
            summary="\{execution.summary} / quality_gate_recovered=clean_research_projection",
          )
          state.replace_execution(updated)
          state.replace_task(task_for_supervision(state, updated))
          sync_worker_from_execution(state, updated)
          recovered += 1
        }
      None => ()
    }
  }
  if recovered > 0 {
    state.record_event(
      @core.TownEvent::new(
        id="event-quality-recovered-\{book_id}",
        kind="recovery",
        detail="Research bootstrap for \{book_id} recovered after late worker failure because MoonBook artifacts, wiki materialization, and generated site passed quality gates.",
        related_book_id=Some(book_id),
      ),
    )
  }
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
