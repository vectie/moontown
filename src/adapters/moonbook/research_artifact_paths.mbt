///|
fn research_raw_bootstrap_artifact_paths() -> Array[String] {
  [
    research_question_path(),
    research_search_log_path(),
    research_source_screen_path(),
    research_evidence_matrix_path(),
    research_local_sources_path(),
    research_synthesis_brief_path(),
    research_deep_report_path(),
    research_marketing_brief_path(),
  ]
}

///|
fn research_question_path() -> String {
  "raw/bootstrap/research-question.md"
}

///|
fn research_search_log_path() -> String {
  "raw/bootstrap/search-log.md"
}

///|
fn research_source_screen_path() -> String {
  "raw/bootstrap/source-screen.md"
}

///|
fn research_evidence_matrix_path() -> String {
  "raw/bootstrap/evidence-matrix.md"
}

///|
fn research_local_sources_path() -> String {
  "raw/bootstrap/local-sources.md"
}

///|
fn research_synthesis_brief_path() -> String {
  "raw/bootstrap/synthesis-brief.md"
}

///|
fn research_deep_report_path() -> String {
  "raw/bootstrap/deep-report.md"
}

///|
fn research_marketing_brief_path() -> String {
  "raw/bootstrap/marketing-brief.md"
}

///|
fn research_tool_blockers_path() -> String {
  "raw/bootstrap/tool-blockers.md"
}

///|
fn research_workspace_artifact_path(
  root : String,
  relative_path : String,
) -> String {
  if root.has_suffix("/") {
    "\{root}\{relative_path}"
  } else {
    "\{root}/\{relative_path}"
  }
}

///|
fn research_ingest_required_raw_artifact_paths() -> Array[String] {
  let paths : Array[String] = []
  for path in research_raw_bootstrap_artifact_paths() {
    if path != research_deep_report_path() {
      paths.push(path)
    }
  }
  paths
}

///|
fn research_artifact_bullets(
  paths : Array[String],
  indent : String,
) -> Array[String] {
  let lines : Array[String] = []
  for path in paths {
    lines.push("\{indent}- `\{path}`")
  }
  lines
}

///|
fn research_raw_bootstrap_artifact_bullets(indent : String) -> Array[String] {
  research_artifact_bullets(research_raw_bootstrap_artifact_paths(), indent)
}

///|
fn research_ingest_required_raw_artifact_bullets(
  indent : String,
) -> Array[String] {
  research_artifact_bullets(
    research_ingest_required_raw_artifact_paths(),
    indent,
  )
}

///|
fn research_raw_bootstrap_artifacts_sentence() -> String {
  let quoted : Array[String] = []
  for path in research_raw_bootstrap_artifact_paths() {
    quoted.push("`\{path}`")
  }
  match quoted {
    [] => ""
    [only] => only
    [.. rest, last] => "\{rest.join(", ")}, and \{last}"
  }
}

///|
fn research_topic_source_page(topic : String) -> String {
  "wiki/sources/\{topic}-web-and-local.md"
}

///|
fn research_topic_entity_page(topic : String) -> String {
  "wiki/entities/\{topic}.md"
}

///|
fn research_topic_concept_page(topic : String) -> String {
  "wiki/concepts/\{topic}-architecture.md"
}

///|
fn research_topic_synthesis_page(topic : String) -> String {
  "wiki/synthesis/\{topic}-research-brief.md"
}

///|
fn research_topic_wiki_page_examples(topic : String) -> Array[String] {
  [
    research_topic_source_page(topic),
    research_topic_entity_page(topic),
    research_topic_concept_page(topic),
    research_topic_synthesis_page(topic),
  ]
}
