///|
test "research policy owns report length and reference rules" {
  assert_eq(report_target_words(), "12k-15k English words")
  assert_eq(report_quality_floor_words(), "12k English words")
  assert_eq(report_min_included_sources(), "six")
  assert_eq(report_preferred_included_sources(), "ten")
  assert_eq(report_reference_line_ratio(), "60%")
  assert_eq(report_reference_line_buffer(), "30-line safety buffer")
  assert_true(
    report_reference_inputs()
    .join("\n")
    .contains(reference_style_context_page()),
  )
  assert_true(report_reference_length_rule().contains("REFERENCE_STYLE.md"))
  assert_true(
    report_no_reference_rule_section().contains(
      "No-Reference Deep Research Rule",
    ),
  )
  assert_true(
    report_no_reference_rule_section().contains("source-depth blocker"),
  )
}
