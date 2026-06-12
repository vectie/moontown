///|
test "research quality policy centralizes shared thresholds" {
  assert_eq(research_policy_deep_dossier_word_target(), "12k-15k English words")
  assert_eq(research_policy_quality_floor_words(), "12k English words")
  assert_eq(research_policy_quality_floor_count(), "12k")
  assert_eq(
    research_policy_repair_dossier_word_target(),
    "13k-15k English-word",
  )
  assert_eq(research_policy_repair_expansion_threshold(), "13k")
  assert_eq(research_policy_repair_acceptance_floor(), "12k words")
  assert_eq(research_policy_min_included_sources(), "six")
  assert_eq(research_policy_min_included_sources_sentence_start(), "Six")
  assert_eq(research_policy_preferred_included_sources(), "ten")
  assert_eq(
    research_policy_preferred_included_source_range(),
    "ten to fourteen",
  )
  assert_eq(research_policy_harvest_candidate_fetch_count(), "eight")
  assert_eq(research_policy_discovery_attempt_limit(), "twenty-four")
  assert_eq(research_policy_reference_line_ratio(), "60%")
  assert_eq(research_policy_reference_line_buffer(), "30-line safety buffer")
  assert_eq(research_policy_command_fetch_pattern(), "curl -L --max-time 12")
}
