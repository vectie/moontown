///|
test "research policy owns canonical artifact paths" {
  assert_eq(question_path(), "raw/bootstrap/research-question.md")
  assert_eq(search_log_path(), "raw/bootstrap/search-log.md")
  assert_eq(source_screen_path(), "raw/bootstrap/source-screen.md")
  assert_eq(deep_report_path(), "raw/bootstrap/deep-report.md")
  assert_true(raw_bootstrap_artifact_paths().contains(marketing_brief_path()))
  assert_true(
    !ingest_required_raw_artifact_paths().contains(deep_report_path()),
  )
  assert_eq(
    workspace_artifact_path("/tmp/book", question_path()),
    "/tmp/book/raw/bootstrap/research-question.md",
  )
  assert_eq(
    topic_source_page("moonclaw"),
    "wiki/sources/moonclaw-web-and-local.md",
  )
  assert_eq(topic_entity_page("moonclaw"), "wiki/entities/moonclaw.md")
}

///|
test "research policy owns bootstrap stage artifact groups" {
  assert_eq(
    bootstrap_report_input_artifacts().join("|"),
    [
      source_screen_path(),
      search_log_path(),
      tool_blockers_path(),
      question_path(),
    ].join("|"),
  )
  assert_eq(
    bootstrap_report_artifact_targets().join("|"),
    [
      local_sources_path(),
      evidence_matrix_path(),
      synthesis_brief_path(),
      deep_report_path(),
      marketing_brief_path(),
    ].join("|"),
  )
  assert_eq(
    bootstrap_quality_repair_input_artifacts().join("|"),
    [
      source_screen_path(),
      evidence_matrix_path(),
      synthesis_brief_path(),
      deep_report_path(),
      marketing_brief_path(),
    ].join("|"),
  )
}
