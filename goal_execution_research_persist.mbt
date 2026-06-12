///|
async fn research_persist_summary(
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
) -> String {
  if !is_research_bootstrap_execution(entry, execution) {
    return execution.summary
  }
  let display = research_persist_display(entry)
  let evidence_summary = read_research_bootstrap_artifacts(entry).summary_excerpt()
  let run_line = match execution.run_id {
    Some(run_id) => " Worker run: `\{run_id}`."
    None => ""
  }
  "Research bootstrap completed for \{display}. Raw artifacts are ready under `raw/bootstrap/`: research-question, search-log, source-screen, evidence-matrix, local-sources, synthesis-brief, deep-report, and marketing-brief.\{run_line} Evidence summary: \{evidence_summary}"
}

///|
fn research_persist_artifacts(
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
) -> Array[String] {
  let artifacts : Array[String] = []
  match execution.run_id {
    Some(run_id) => artifacts.push(run_id)
    None => ()
  }
  if is_research_bootstrap_execution(entry, execution) {
    for artifact in research_bootstrap_result_artifacts() {
      artifacts.push(artifact)
    }
  }
  artifacts
}

///|
async fn research_persist_memory_candidates(
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
) -> Array[@moonbook.MemoryCandidate] {
  if !is_research_bootstrap_execution(entry, execution) {
    return []
  }
  let topic = @research_quality.quality_topic_for_entry(entry)
  let display = research_persist_display(entry)
  let artifacts = read_research_bootstrap_artifacts(entry)
  let source_detail = artifacts.source_detail()
  let entity_detail = artifacts.entity_detail()
  let concept_detail = artifacts.concept_detail()
  let synthesis_detail = artifacts.synthesis_detail()
  [
    @moonbook.MemoryCandidate::new(
      kind="source",
      title="\{display} screened source set",
      detail="Screened research evidence for this book: \{source_detail}",
      durable=true,
      target_page=Some("sources/\{topic}-screened-sources.md"),
    ),
    @moonbook.MemoryCandidate::new(
      kind="entity",
      title=display,
      detail="Primary research entity for this book: \{entity_detail}",
      durable=true,
      target_page=Some("entities/\{topic}.md"),
    ),
    @moonbook.MemoryCandidate::new(
      kind="concept",
      title="\{display} research thesis",
      detail="Maintained concept synthesized from the evidence matrix: \{concept_detail}",
      durable=true,
      target_page=Some("concepts/\{topic}-research-thesis.md"),
    ),
    @moonbook.MemoryCandidate::new(
      kind="synthesis",
      title="\{display} evidence-limited synthesis",
      detail="Current synthesis and open gaps: \{synthesis_detail}",
      durable=true,
      target_page=Some("synthesis/\{topic}-research-thesis.md"),
    ),
  ]
}

///|
fn is_research_bootstrap_execution(
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
) -> Bool {
  entry.id.has_prefix("research-") &&
  execution.task_id.contains("research-bootstrap-ingest")
}

///|
fn research_bootstrap_result_artifacts() -> Array[String] {
  [
    "raw/bootstrap/research-question.md", "raw/bootstrap/search-log.md", "raw/bootstrap/source-screen.md",
    "raw/bootstrap/evidence-matrix.md", "raw/bootstrap/local-sources.md", "raw/bootstrap/synthesis-brief.md",
    "raw/bootstrap/deep-report.md", "raw/bootstrap/marketing-brief.md",
  ]
}

///|
fn research_persist_display(entry : @moonbook.BookCatalogEntry) -> String {
  let topic = @research_quality.quality_topic_for_entry(entry)
  if topic == "opc" {
    "One Person Company (OPC)"
  } else if !entry.name.trim().is_blank() {
    entry.name
  } else {
    label_from_slug(topic)
  }
}

///|
fn first_non_empty_compact_excerpt(
  texts : Array[String],
  limit : Int,
) -> String {
  for text in texts {
    let compact = compact_markdown_for_candidate(text)
    if !compact.is_blank() {
      return markdown_excerpt(compact, limit)
    }
  }
  "No non-empty research artifact text was available at persistence time."
}

///|
fn compact_markdown_for_candidate(text : String) -> String {
  let builder = StringBuilder::new()
  let mut wrote = false
  for raw in text.split("\n") {
    let line = raw.trim().to_owned()
    if line.is_empty() ||
      line.has_prefix("#") ||
      line.has_prefix("| ---") ||
      line.has_prefix("```") {
      continue
    }
    if wrote {
      builder.write_string(" ")
    }
    builder.write_string(line)
    wrote = true
  }
  builder.to_string()
}
