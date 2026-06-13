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
