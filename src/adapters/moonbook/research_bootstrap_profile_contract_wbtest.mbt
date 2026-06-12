///|
test "research bootstrap profile is direct MoonClaw execution" {
  let profile_text = moontown_research_bootstrap_profile_json().stringify(
    indent=2,
  )
  assert_true(profile_text.contains("moontown_research_bootstrap_worker"))
  assert_true(profile_text.contains("\"role\": \"worker\""))
  assert_true(profile_text.contains("research_bootstrap_sources"))
  assert_true(profile_text.contains("research_bootstrap_source_expansion"))
  assert_true(profile_text.contains("research_bootstrap_report"))
  assert_true(profile_text.contains("research_bootstrap_quality_repair"))
  assert_true(profile_text.contains("Use native web_search first"))
  assert_true(profile_text.contains("focused source-expansion stage"))
  assert_true(profile_text.contains("optional raw/bootstrap/QUALITY_REPAIR.md"))
  assert_true(profile_text.contains("tool-backed self-review"))
  assert_true(profile_text.contains("No active quality repair"))
  assert_true(profile_text.contains("treat this as repair mode"))
  assert_true(profile_text.contains("preserve the existing report"))
  assert_true(profile_text.contains("review gate"))
  assert_true(profile_text.contains("repair in-place"))
  assert_true(profile_text.contains("REFERENCE_SOURCE_HINTS.md"))
  assert_true(
    profile_text.contains(
      "Do not load the full reference report in this source-screening stage",
    ),
  )
  assert_true(profile_text.contains("final deep-research review gate"))
  assert_true(profile_text.contains("Six included sources is the minimum"))
  assert_true(profile_text.contains("ten to fourteen"))
  assert_true(profile_text.contains("extract candidate result URLs"))
  assert_true(profile_text.contains("13k-15k English-word"))
  assert_true(profile_text.contains("hard acceptance floor of 12k words"))
  assert_true(profile_text.contains("reference line-count target"))
  assert_true(profile_text.contains("\"disable_adaptive\": true"))
  assert_true(profile_text.contains("\"disable_waiting_for_input\": true"))
  assert_true(profile_text.contains("\"best_effort_on_missing_input\": true"))
  assert_true(profile_text.contains("\"web_search\": true"))
  assert_true(profile_text.contains("\"retry_max_attempts\": 3"))
  assert_true(profile_text.contains("\"retry_backoff_ms\": 4000"))
  assert_true(profile_text.contains("\"timeout_ms\": 900000"))
  assert_true(profile_text.contains("\"best_effort_on_timeout\": true"))
  assert_true(profile_text.contains("curl -L --max-time 12"))
  assert_true(profile_text.contains("Return plain Markdown, not JSON"))
  assert_true(profile_text.contains("raw/bootstrap/deep-report.md"))
  assert_true(
    profile_text.contains("Do not update wiki pages in this worker stage"),
  )
  assert_true(!profile_text.contains("research_bootstrap_question"))
  assert_true(!profile_text.contains("\"execution_mode\": \"provider\""))
}
