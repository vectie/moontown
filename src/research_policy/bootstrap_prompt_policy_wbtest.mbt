///|
test "research policy owns bootstrap web and fallback prompt policy" {
  assert_true(
    bootstrap_native_web_policy_prompt().contains("Use native web_search first"),
  )
  assert_true(bootstrap_native_web_policy_prompt().contains("{bad request}"))
  assert_true(
    bootstrap_command_fallback_policy_prompt().contains(command_fetch_pattern()),
  )
  assert_true(
    bootstrap_command_fallback_policy_prompt().contains(search_log_path()),
  )
  assert_true(
    bootstrap_harvest_to_inspection_prompt().contains(
      harvest_candidate_fetch_count(),
    ),
  )
}

///|
test "research policy owns bootstrap reference and source-depth prompt policy" {
  assert_true(
    bootstrap_reference_policy_prompt().contains(
      "Reference source hints are not evidence",
    ),
  )
  assert_true(
    bootstrap_source_depth_policy_prompt().contains(
      preferred_included_source_range(),
    ),
  )
  assert_true(
    bootstrap_source_depth_policy_prompt().contains(deep_dossier_word_target()),
  )
  assert_true(
    bootstrap_below_minimum_source_policy_prompt().contains(
      discovery_attempt_limit(),
    ),
  )
  assert_true(
    bootstrap_plain_markdown_no_json_fields_prompt().contains("not JSON"),
  )
}

///|
test "research policy owns bootstrap report-stage prompt policy" {
  assert_true(
    bootstrap_report_repair_policy_prompt().contains("historical audit context"),
  )
  assert_true(
    bootstrap_active_repair_policy_prompt().contains(deep_report_path()),
  )
  assert_true(
    bootstrap_report_evidence_policy_prompt().contains(
      "screened sources and blockers",
    ),
  )
  assert_true(
    bootstrap_no_reference_quality_authority_prompt().contains(
      research_report_skill_path(),
    ),
  )
  assert_true(
    bootstrap_report_quality_target_prompt().contains(
      repair_dossier_word_target(),
    ),
  )
  assert_true(
    bootstrap_report_self_review_prompt().contains("process-log leakage"),
  )
}
