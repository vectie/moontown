///|
fn research_raw_bootstrap_artifact_paths() -> Array[String] {
  @research_policy.raw_bootstrap_artifact_paths()
}

///|
fn research_question_path() -> String {
  @research_policy.question_path()
}

///|
fn research_search_log_path() -> String {
  @research_policy.search_log_path()
}

///|
fn research_source_screen_path() -> String {
  @research_policy.source_screen_path()
}

///|
fn research_evidence_matrix_path() -> String {
  @research_policy.evidence_matrix_path()
}

///|
fn research_local_sources_path() -> String {
  @research_policy.local_sources_path()
}

///|
fn research_synthesis_brief_path() -> String {
  @research_policy.synthesis_brief_path()
}

///|
fn research_deep_report_path() -> String {
  @research_policy.deep_report_path()
}

///|
fn research_marketing_brief_path() -> String {
  @research_policy.marketing_brief_path()
}

///|
fn research_tool_blockers_path() -> String {
  @research_policy.tool_blockers_path()
}

///|
fn research_workspace_artifact_path(
  root : String,
  relative_path : String,
) -> String {
  @research_policy.workspace_artifact_path(root, relative_path)
}

///|
fn research_ingest_required_raw_artifact_paths() -> Array[String] {
  @research_policy.ingest_required_raw_artifact_paths()
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
  @research_policy.topic_source_page(topic)
}

///|
fn research_topic_entity_page(topic : String) -> String {
  @research_policy.topic_entity_page(topic)
}

///|
fn research_topic_concept_page(topic : String) -> String {
  @research_policy.topic_concept_page(topic)
}

///|
fn research_topic_synthesis_page(topic : String) -> String {
  @research_policy.topic_synthesis_page(topic)
}

///|
fn research_topic_wiki_page_examples(topic : String) -> Array[String] {
  @research_policy.topic_wiki_page_examples(topic)
}
