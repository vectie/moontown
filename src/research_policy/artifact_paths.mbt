///|
pub fn raw_bootstrap_artifact_paths() -> Array[String] {
  [
    question_path(),
    search_log_path(),
    source_screen_path(),
    evidence_matrix_path(),
    local_sources_path(),
    synthesis_brief_path(),
    deep_report_path(),
    marketing_brief_path(),
  ]
}

///|
pub fn question_path() -> String {
  "raw/bootstrap/research-question.md"
}

///|
pub fn search_log_path() -> String {
  "raw/bootstrap/search-log.md"
}

///|
pub fn source_screen_path() -> String {
  "raw/bootstrap/source-screen.md"
}

///|
pub fn evidence_matrix_path() -> String {
  "raw/bootstrap/evidence-matrix.md"
}

///|
pub fn local_sources_path() -> String {
  "raw/bootstrap/local-sources.md"
}

///|
pub fn synthesis_brief_path() -> String {
  "raw/bootstrap/synthesis-brief.md"
}

///|
pub fn deep_report_path() -> String {
  "raw/bootstrap/deep-report.md"
}

///|
pub fn marketing_brief_path() -> String {
  "raw/bootstrap/marketing-brief.md"
}

///|
pub fn tool_blockers_path() -> String {
  "raw/bootstrap/tool-blockers.md"
}

///|
pub fn workspace_artifact_path(root : String, relative_path : String) -> String {
  if root.has_suffix("/") {
    "\{root}\{relative_path}"
  } else {
    "\{root}/\{relative_path}"
  }
}

///|
pub fn ingest_required_raw_artifact_paths() -> Array[String] {
  let paths : Array[String] = []
  for path in raw_bootstrap_artifact_paths() {
    if path != deep_report_path() {
      paths.push(path)
    }
  }
  paths
}

///|
pub fn bootstrap_report_input_artifacts() -> Array[String] {
  [
    source_screen_path(),
    search_log_path(),
    tool_blockers_path(),
    question_path(),
  ]
}

///|
pub fn bootstrap_report_artifact_targets() -> Array[String] {
  [
    local_sources_path(),
    evidence_matrix_path(),
    synthesis_brief_path(),
    deep_report_path(),
    marketing_brief_path(),
  ]
}

///|
pub fn bootstrap_quality_repair_input_artifacts() -> Array[String] {
  [
    source_screen_path(),
    evidence_matrix_path(),
    synthesis_brief_path(),
    deep_report_path(),
    marketing_brief_path(),
  ]
}

///|
pub fn artifact_bullets(
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
pub fn raw_bootstrap_artifact_bullets(indent : String) -> Array[String] {
  artifact_bullets(raw_bootstrap_artifact_paths(), indent)
}

///|
pub fn ingest_required_raw_artifact_bullets(indent : String) -> Array[String] {
  artifact_bullets(ingest_required_raw_artifact_paths(), indent)
}

///|
pub fn raw_bootstrap_artifacts_sentence() -> String {
  let quoted : Array[String] = []
  for path in raw_bootstrap_artifact_paths() {
    quoted.push("`\{path}`")
  }
  match quoted {
    [] => ""
    [only] => only
    [.. rest, last] => "\{rest.join(", ")}, and \{last}"
  }
}

///|
pub fn topic_source_page(topic : String) -> String {
  "wiki/sources/\{topic}-web-and-local.md"
}

///|
pub fn topic_entity_page(topic : String) -> String {
  "wiki/entities/\{topic}.md"
}

///|
pub fn topic_concept_page(topic : String) -> String {
  "wiki/concepts/\{topic}-architecture.md"
}

///|
pub fn topic_synthesis_page(topic : String) -> String {
  "wiki/synthesis/\{topic}-research-brief.md"
}

///|
pub fn topic_wiki_page_examples(topic : String) -> Array[String] {
  [
    topic_source_page(topic),
    topic_entity_page(topic),
    topic_concept_page(topic),
    topic_synthesis_page(topic),
  ]
}
