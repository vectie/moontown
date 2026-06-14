///|
test "research policy owns bootstrap context and output contracts" {
  assert_eq(
    research_request_context_page(),
    "raw/bootstrap/RESEARCH_REQUEST.md",
  )
  assert_true(
    bootstrap_context_pages().contains(reference_style_context_page()),
  )
  assert_true(
    bootstrap_context_pages().contains(reference_source_hints_context_page()),
  )
  assert_true(enrichment_context_pages().contains(journey_context_page()))
  let contract = bootstrap_output_contract_lines().join("\n")
  assert_true(contract.contains("plain Markdown summaries"))
  assert_true(contract.contains("adaptive-planning JSON"))
  assert_true(contract.contains(raw_bootstrap_artifacts_sentence()))
}

///|
test "research policy owns bootstrap reference context policy wording" {
  assert_true(
    bootstrap_context_reference_style_policy().contains(
      reference_style_context_page(),
    ),
  )
  assert_true(
    bootstrap_context_reference_style_policy().contains(
      reference_output_context_page(),
    ),
  )
  assert_true(
    bootstrap_context_reference_style_policy().contains(
      "style, length, language, and quality target",
    ),
  )
  assert_true(
    bootstrap_context_reference_source_policy().contains(
      reference_source_hints_context_page(),
    ),
  )
  assert_true(
    bootstrap_context_reference_source_policy().contains(
      "Never cite it as evidence by itself",
    ),
  )
}

///|
test "research policy owns request source-screen policy wording" {
  assert_true(
    request_included_source_depth_target().contains(min_included_sources()),
  )
  assert_true(
    request_discovery_artifact_exclusion().contains("discovery artifacts"),
  )
  assert_true(
    request_source_depth_blocker_requirement().contains(
      "ready_for_12k_dossier: false",
    ),
  )
  assert_true(request_source_screen_row_fields().contains("authority"))
}

///|
test "research policy owns request discovery fallback policy wording" {
  assert_true(
    request_native_search_or_command_fallback_policy().contains(
      command_fetch_pattern(),
    ),
  )
  assert_true(
    request_native_search_or_command_fallback_policy().contains(
      min_included_sources(),
    ),
  )
  assert_true(
    request_web_search_result_fallback_policy().contains(
      "extract result URLs and titles",
    ),
  )
  assert_true(request_command_fallback_log_policy().contains(search_log_path()))
  assert_true(
    request_candidate_page_fetch_policy().contains(
      harvest_candidate_fetch_count(),
    ),
  )
  assert_true(
    request_source_class_exhaustion_policy().contains("one guessed 404"),
  )
}

///|
test "research policy owns request output policy bullets" {
  assert_true(request_quality_bar_bullet().contains("every major claim"))
  assert_true(request_depth_target_bullet().contains(deep_report_path()))
  assert_true(
    request_depth_target_bullet().contains(deep_dossier_word_target()),
  )
  assert_true(
    request_depth_target_bullet().contains("exact source-class blocker"),
  )
  let reference = request_reference_style_bullet("EUV")
  assert_true(reference.contains(reference_style_context_page()))
  assert_true(reference.contains(reference_output_context_page()))
  assert_true(reference.contains("not evidence for EUV"))
}
