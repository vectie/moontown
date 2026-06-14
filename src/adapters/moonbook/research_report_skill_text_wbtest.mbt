///|
test "research report skill preserves long-form quality contract" {
  let entry = moonbook_adapter_external_research_entry(
    id="research-llm-training-detail",
    name="How LLMs are trained in very detail",
    purpose="Explain LLM training deeply",
    workspace_root="/tmp/research-llm-training-detail",
  )
  let skill = research_report_skill_text(entry)
  assert_true(skill.contains("name: research-report"))
  assert_true(skill.contains("# llm training detail: Deep Research Analysis"))
  assert_true(
    skill.contains(
      "Always produce or revise `\{@research_policy.deep_report_path()}`",
    ),
  )
  assert_true(skill.contains("at least 8 `##` sections"))
  assert_true(skill.contains("## Executive Summary"))
  assert_true(skill.contains("Mermaid relationship"))
  assert_true(skill.contains("source IDs on strong claims"))
  assert_true(skill.contains("12k-15k English words"))
  assert_true(skill.contains("12k English words is the quality floor"))
  assert_true(skill.contains("## Evidence and Limits"))
}

///|
test "research report skill keeps reference and no-reference depth policies explicit" {
  let entry = moonbook_adapter_external_research_entry(
    id="research-euv-lithography-machine-new-advantages-and-supplements",
    name="EUV lithography machine new advantages and supplements",
    purpose="Research EUV routes",
    workspace_root="/tmp/research-euv",
  )
  let skill = research_report_skill_text(entry)
  assert_true(skill.contains("raw/bootstrap/REFERENCE_STYLE.md"))
  assert_true(skill.contains("raw/bootstrap/REFERENCE_OUTPUT.md"))
  assert_true(skill.contains("60% of the reference line count"))
  assert_true(skill.contains("30-line safety buffer"))
  assert_true(skill.contains("With six or more included inspected sources"))
  assert_true(skill.contains("Prefer ten or more included inspected sources"))
  assert_true(skill.contains("source-depth blocker"))
  assert_true(skill.contains("do not pad with repeated definitions"))
}

///|
test "research report policy helpers come from research policy" {
  assert_eq(@research_policy.report_target_words(), "12k-15k English words")
  assert_eq(@research_policy.report_quality_floor_words(), "12k English words")
  assert_eq(@research_policy.report_min_included_sources(), "six")
  assert_eq(@research_policy.report_preferred_included_sources(), "ten")
  assert_eq(@research_policy.report_reference_line_ratio(), "60%")
  assert_eq(
    @research_policy.report_reference_line_buffer(),
    "30-line safety buffer",
  )
  assert_true(
    @research_policy.report_reference_length_rule().contains(
      "REFERENCE_STYLE.md",
    ),
  )
  assert_true(
    @research_policy.report_word_target_requirement().contains("quality floor"),
  )
}

///|
test "research report required inputs use shared artifact paths" {
  let required = @research_policy.report_required_inputs_section()
  for path in @research_policy.ingest_required_raw_artifact_paths() {
    assert_true(required.contains("- `\{path}`"))
  }
  assert_true(!required.contains("- `\{@research_policy.deep_report_path()}`"))
  assert_true(required.contains("- `wiki/sources/*.md`"))
  assert_true(required.contains("- `wiki/synthesis/*.md`"))
}
