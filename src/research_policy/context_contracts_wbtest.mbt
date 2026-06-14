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
