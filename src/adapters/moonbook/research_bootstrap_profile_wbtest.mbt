///|
test "research bootstrap source screening policy keeps web-first fallback explicit" {
  let prompt = research_bootstrap_sources_prompt()
  assert_true(prompt.contains("Use native web_search first"))
  assert_true(prompt.contains("bounded execute_command discovery"))
  assert_true(prompt.contains(research_policy_command_fetch_pattern()))
  assert_true(prompt.contains("ready_for_12k_dossier"))
  assert_true(prompt.contains("Never return a missing-input"))
  assert_true(prompt.contains(research_search_log_path()))
  assert_true(prompt.contains(research_source_screen_path()))
  assert_true(prompt.contains(research_tool_blockers_path()))
  assert_true(
    prompt.contains(
      "fewer than \{research_policy_min_included_sources()} included inspected sources",
    ),
  )
}

///|
test "research bootstrap repair policy separates review from churn" {
  let prompt = research_bootstrap_quality_repair_prompt()
  assert_true(prompt.contains("First judge whether the report already passes"))
  assert_true(prompt.contains("record a no-op review"))
  assert_true(prompt.contains("repair in-place"))
  assert_true(prompt.contains(research_deep_report_path()))
  assert_true(prompt.contains(research_marketing_brief_path()))
  assert_true(
    prompt.contains("\{research_policy_repair_dossier_word_target()} dossier"),
  )
  assert_true(
    prompt.contains(
      "hard acceptance floor of \{research_policy_repair_acceptance_floor()}",
    ),
  )
  assert_true(prompt.contains("rather than creating v2/v3/v4 files"))
}

///|
test "research bootstrap report prompts use shared artifact lists" {
  assert_eq(
    research_bootstrap_report_input_artifacts().join("|"),
    [
      research_source_screen_path(),
      research_search_log_path(),
      research_tool_blockers_path(),
      research_question_path(),
    ].join("|"),
  )
  assert_eq(
    research_bootstrap_report_artifact_targets().join("|"),
    [
      research_local_sources_path(),
      research_evidence_matrix_path(),
      research_synthesis_brief_path(),
      research_deep_report_path(),
      research_marketing_brief_path(),
    ].join("|"),
  )
  let prompt = research_bootstrap_report_prompt()
  assert_true(prompt.contains(research_question_path()))
  assert_true(prompt.contains(research_deep_report_path()))
  assert_true(prompt.contains(research_marketing_brief_path()))
}

///|
test "research bootstrap quality repair inputs use shared artifacts" {
  let inputs = research_bootstrap_quality_repair_input_artifacts()
  assert_true(inputs.contains(research_source_screen_path()))
  assert_true(inputs.contains(research_evidence_matrix_path()))
  assert_true(inputs.contains(research_synthesis_brief_path()))
  assert_true(inputs.contains(research_deep_report_path()))
  assert_true(inputs.contains(research_marketing_brief_path()))
  let prompt = research_bootstrap_quality_repair_inputs_prompt()
  assert_true(prompt.contains(research_source_screen_path()))
  assert_true(prompt.contains(research_deep_report_path()))
}

///|
test "research bootstrap profile uses shared source-depth and harvest policy" {
  assert_true(
    research_bootstrap_harvest_to_inspection_prompt().contains(
      "at least \{research_policy_harvest_candidate_fetch_count()}",
    ),
  )
  assert_true(
    research_bootstrap_source_depth_policy_prompt().contains(
      research_policy_preferred_included_source_range(),
    ),
  )
  assert_true(
    research_bootstrap_below_minimum_source_policy_prompt().contains(
      research_policy_discovery_attempt_limit(),
    ),
  )
  assert_true(
    research_bootstrap_source_expansion_prompt().contains(
      research_policy_deep_dossier_word_target(),
    ),
  )
  assert_true(
    research_bootstrap_source_expansion_inputs_prompt().contains(
      research_search_log_path(),
    ),
  )
  assert_true(
    research_bootstrap_source_expansion_prompt().contains(
      research_source_screen_path(),
    ),
  )
}

///|
test "research bootstrap source-screening target prompt uses shared artifacts" {
  let prompt = research_bootstrap_source_screening_write_targets_prompt()
  assert_true(prompt.contains(research_search_log_path()))
  assert_true(prompt.contains(research_source_screen_path()))
  assert_true(prompt.contains(research_tool_blockers_path()))
}

///|
test "research bootstrap worker context lists required raw artifacts" {
  let contract = research_bootstrap_required_artifacts_contract()
  assert_true(contract.contains("research-question.md"))
  assert_true(contract.contains("source-screen.md"))
  assert_true(contract.contains("evidence-matrix.md"))
  assert_true(contract.contains("deep-report.md"))
  assert_true(contract.contains("marketing-brief.md"))
}
