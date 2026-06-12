///|
test "research raw bootstrap artifact paths centralize full handoff contract" {
  assert_eq(
    research_raw_bootstrap_artifact_paths().join("|"),
    "raw/bootstrap/research-question.md|raw/bootstrap/search-log.md|raw/bootstrap/source-screen.md|raw/bootstrap/evidence-matrix.md|raw/bootstrap/local-sources.md|raw/bootstrap/synthesis-brief.md|raw/bootstrap/deep-report.md|raw/bootstrap/marketing-brief.md",
  )
  assert_true(
    research_raw_bootstrap_artifacts_sentence().contains(
      "`raw/bootstrap/deep-report.md`",
    ),
  )
  assert_true(
    research_raw_bootstrap_artifact_bullets("  ")
    .join("\n")
    .contains("  - `raw/bootstrap/marketing-brief.md`"),
  )
}

///|
test "research raw bootstrap path helpers expose named contract files" {
  assert_eq(research_question_path(), "raw/bootstrap/research-question.md")
  assert_eq(research_search_log_path(), "raw/bootstrap/search-log.md")
  assert_eq(research_source_screen_path(), "raw/bootstrap/source-screen.md")
  assert_eq(research_evidence_matrix_path(), "raw/bootstrap/evidence-matrix.md")
  assert_eq(research_local_sources_path(), "raw/bootstrap/local-sources.md")
  assert_eq(research_synthesis_brief_path(), "raw/bootstrap/synthesis-brief.md")
  assert_eq(research_deep_report_path(), "raw/bootstrap/deep-report.md")
  assert_eq(research_marketing_brief_path(), "raw/bootstrap/marketing-brief.md")
  assert_eq(research_tool_blockers_path(), "raw/bootstrap/tool-blockers.md")
}

///|
test "research workspace artifact path joins root and shared relative path" {
  assert_eq(
    research_workspace_artifact_path("/tmp/book", research_question_path()),
    "/tmp/book/raw/bootstrap/research-question.md",
  )
  assert_eq(
    research_workspace_artifact_path("/tmp/book/", research_search_log_path()),
    "/tmp/book/raw/bootstrap/search-log.md",
  )
}

///|
test "research ingest raw artifact paths preserve pre-report ingest boundary" {
  let paths = research_ingest_required_raw_artifact_paths()
  assert_true(paths.contains("raw/bootstrap/research-question.md"))
  assert_true(paths.contains("raw/bootstrap/marketing-brief.md"))
  assert_true(!paths.contains("raw/bootstrap/deep-report.md"))
  assert_true(
    !research_ingest_required_raw_artifact_bullets("")
    .join("\n")
    .contains("deep-report.md"),
  )
}

///|
test "research topic wiki page helpers are consistent across skills" {
  let topic = "moonclaw"
  assert_eq(
    research_topic_wiki_page_examples(topic).join("|"),
    "wiki/sources/moonclaw-web-and-local.md|wiki/entities/moonclaw.md|wiki/concepts/moonclaw-architecture.md|wiki/synthesis/moonclaw-research-brief.md",
  )
  assert_eq(
    research_topic_source_page(topic),
    "wiki/sources/moonclaw-web-and-local.md",
  )
  assert_eq(research_topic_entity_page(topic), "wiki/entities/moonclaw.md")
}
