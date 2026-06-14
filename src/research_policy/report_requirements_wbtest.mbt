///|
test "research policy owns report output requirements" {
  let section = report_non_negotiable_output_section("MoonClaw")
  assert_true(
    section.contains("Always produce or revise `\{deep_report_path()}`"),
  )
  assert_true(section.contains("# MoonClaw: Deep Research Analysis"))
  assert_true(section.contains("at least 8 `##` sections"))
  assert_true(section.contains("Mermaid relationship"))
  assert_true(section.contains("source IDs on strong claims"))
  assert_true(section.contains("12k-15k English words"))
  assert_true(section.contains("12k English words is the quality floor"))
  assert_true(section.contains("## Evidence and Limits"))
}

///|
test "research policy owns report required input section" {
  let required = report_required_inputs_section()
  for path in ingest_required_raw_artifact_paths() {
    assert_true(required.contains("- `\{path}`"))
  }
  assert_true(!required.contains("- `\{deep_report_path()}`"))
  assert_true(required.contains("- `wiki/sources/*.md`"))
  assert_true(required.contains("- `wiki/synthesis/*.md`"))
}
