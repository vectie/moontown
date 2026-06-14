///|
test "research bootstrap source screening policy keeps web-first fallback explicit" {
  let prompt = research_bootstrap_sources_prompt()
  assert_true(prompt.contains("Use native web_search first"))
  assert_true(prompt.contains("bounded execute_command discovery"))
  assert_true(prompt.contains(@research_policy.command_fetch_pattern()))
  assert_true(prompt.contains("ready_for_12k_dossier"))
  assert_true(prompt.contains("Never return a missing-input"))
  assert_true(prompt.contains(@research_policy.search_log_path()))
  assert_true(prompt.contains(@research_policy.source_screen_path()))
  assert_true(prompt.contains(@research_policy.tool_blockers_path()))
  assert_true(
    prompt.contains(
      "fewer than \{@research_policy.min_included_sources()} included inspected sources",
    ),
  )
}

///|
test "research bootstrap repair policy separates review from churn" {
  let prompt = research_bootstrap_quality_repair_prompt()
  assert_true(prompt.contains("First judge whether the report already passes"))
  assert_true(prompt.contains("record a no-op review"))
  assert_true(prompt.contains("repair in-place"))
  assert_true(prompt.contains(@research_policy.deep_report_path()))
  assert_true(prompt.contains(@research_policy.marketing_brief_path()))
  assert_true(
    prompt.contains("\{@research_policy.repair_dossier_word_target()} dossier"),
  )
  assert_true(
    prompt.contains(
      "hard acceptance floor of \{@research_policy.repair_acceptance_floor()}",
    ),
  )
  assert_true(prompt.contains("rather than creating v2/v3/v4 files"))
}

///|
test "research bootstrap report prompts use shared artifact lists" {
  assert_eq(
    @research_policy.bootstrap_report_input_artifacts().join("|"),
    [
      @research_policy.source_screen_path(),
      @research_policy.search_log_path(),
      @research_policy.tool_blockers_path(),
      @research_policy.question_path(),
    ].join("|"),
  )
  assert_eq(
    @research_policy.bootstrap_report_artifact_targets().join("|"),
    [
      @research_policy.local_sources_path(),
      @research_policy.evidence_matrix_path(),
      @research_policy.synthesis_brief_path(),
      @research_policy.deep_report_path(),
      @research_policy.marketing_brief_path(),
    ].join("|"),
  )
  let prompt = research_bootstrap_report_prompt()
  assert_true(prompt.contains(@research_policy.question_path()))
  assert_true(prompt.contains(@research_policy.deep_report_path()))
  assert_true(prompt.contains(@research_policy.marketing_brief_path()))
}

///|
test "research bootstrap quality repair inputs use shared artifacts" {
  let inputs = @research_policy.bootstrap_quality_repair_input_artifacts()
  assert_true(inputs.contains(@research_policy.source_screen_path()))
  assert_true(inputs.contains(@research_policy.evidence_matrix_path()))
  assert_true(inputs.contains(@research_policy.synthesis_brief_path()))
  assert_true(inputs.contains(@research_policy.deep_report_path()))
  assert_true(inputs.contains(@research_policy.marketing_brief_path()))
  let prompt = research_bootstrap_quality_repair_inputs_prompt()
  assert_true(prompt.contains(@research_policy.source_screen_path()))
  assert_true(prompt.contains(@research_policy.deep_report_path()))
}

///|
test "research bootstrap profile uses shared source-depth and harvest policy" {
  assert_true(
    @research_policy.bootstrap_harvest_to_inspection_prompt().contains(
      "at least \{@research_policy.harvest_candidate_fetch_count()}",
    ),
  )
  assert_true(
    @research_policy.bootstrap_source_depth_policy_prompt().contains(
      @research_policy.preferred_included_source_range(),
    ),
  )
  assert_true(
    @research_policy.bootstrap_below_minimum_source_policy_prompt().contains(
      @research_policy.discovery_attempt_limit(),
    ),
  )
  assert_true(
    research_bootstrap_source_expansion_prompt().contains(
      @research_policy.deep_dossier_word_target(),
    ),
  )
  assert_true(
    research_bootstrap_source_expansion_inputs_prompt().contains(
      @research_policy.search_log_path(),
    ),
  )
  assert_true(
    research_bootstrap_source_expansion_prompt().contains(
      @research_policy.source_screen_path(),
    ),
  )
}

///|
test "research bootstrap source-screening target prompt uses shared artifacts" {
  let prompt = research_bootstrap_source_screening_write_targets_prompt()
  assert_true(prompt.contains(@research_policy.search_log_path()))
  assert_true(prompt.contains(@research_policy.source_screen_path()))
  assert_true(prompt.contains(@research_policy.tool_blockers_path()))
}

///|
test "research bootstrap worker context lists required raw artifacts" {
  let contract = @research_policy.bootstrap_required_artifacts_contract()
  assert_true(contract.contains("research-question.md"))
  assert_true(contract.contains("source-screen.md"))
  assert_true(contract.contains("evidence-matrix.md"))
  assert_true(contract.contains("deep-report.md"))
  assert_true(contract.contains("marketing-brief.md"))
}
