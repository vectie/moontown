///|
fn web_first_output_contract_example_section() -> Array[String] {
  [
    "## Output Contract Example",
    "",
    "Return JSON only when the runtime asks for JSON:",
    "",
    "```json",
    "{",
    "  \"result_id\": \"goal-research-moonclaw-research-bootstrap-ingest\",",
    "  \"summary\": \"Created a web-first research dossier and verified wiki pages for MoonClaw.\",",
    "  \"artifacts\": [",
    web_first_output_contract_artifact_lines("moonclaw").join(",\n"),
    "  ],",
    "  \"memory_candidates\": [",
    web_first_output_contract_memory_candidate(),
    "  ],",
    "  \"requires_review\": true,",
    "  \"notify_town\": true",
    "}",
    "```",
  ]
}

///|
fn web_first_output_contract_artifact_lines(topic : String) -> Array[String] {
  let paths : Array[String] = [
    @research_policy.search_log_path(),
    @research_policy.evidence_matrix_path(),
    @research_policy.topic_source_page(topic),
    @research_policy.topic_entity_page(topic),
    @research_policy.topic_concept_page(topic),
    @research_policy.topic_synthesis_page(topic),
  ]
  let lines : Array[String] = []
  for path in paths {
    lines.push("    \"\{path}\"")
  }
  lines
}

///|
fn web_first_output_contract_memory_candidate() -> String {
  web_first_text([
    "    { \"kind\": \"finding\", \"text\": \"MoonClaw owns execution and result",
    "packaging; MoonBook owns durable memory promotion.\" }",
  ])
}
