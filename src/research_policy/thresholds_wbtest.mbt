///|
test "research policy centralizes shared research-depth thresholds" {
  assert_eq(deep_dossier_word_target(), "12k-15k English words")
  assert_eq(quality_floor_words(), "12k English words")
  assert_eq(quality_floor_count(), "12k")
  assert_eq(repair_dossier_word_target(), "13k-15k English-word")
  assert_eq(repair_expansion_threshold(), "13k")
  assert_eq(repair_acceptance_floor(), "12k words")
  assert_eq(min_included_sources(), "six")
  assert_eq(min_included_sources_sentence_start(), "Six")
  assert_eq(preferred_included_sources(), "ten")
  assert_eq(preferred_included_source_range(), "ten to fourteen")
  assert_eq(harvest_candidate_fetch_count(), "eight")
  assert_eq(discovery_attempt_limit(), "twenty-four")
  assert_eq(reference_line_ratio(), "60%")
  assert_eq(reference_line_buffer(), "30-line safety buffer")
  assert_eq(command_fetch_pattern(), "curl -L --max-time 12")
}
