///|
test "wiki ingest skill for external topics keeps domain guard and web first" {
  let skill = research_wiki_ingest_skill_text(
    moonbook_adapter_opc_research_entry(),
  )
  assert_true(skill.contains("name: wiki-ingest"))
  assert_true(skill.contains("## Domain Guard"))
  assert_true(skill.contains("external domain research"))
  assert_true(skill.contains("Do not reinterpret"))
  assert_true(skill.contains("web-first discovery"))
  assert_true(skill.contains("curl -L --max-time 12"))
  assert_true(skill.contains(research_tool_blockers_path()))
}

///|
test "wiki ingest skill for project topics omits external domain guard" {
  let entry = moonbook_adapter_catalog_entry(
    id="research-moonbook",
    name="MoonBook",
    purpose="Research MoonBook",
    workspace_root="/tmp/research-moonbook",
  )
  let skill = research_wiki_ingest_skill_text(entry)
  assert_true(skill.contains("# Wiki Ingest For MoonBook Research"))
  assert_true(!skill.contains("## Domain Guard"))
  assert_true(skill.contains("Inspect local files only after recording"))
  assert_true(
    skill.contains("screened web evidence makes local files relevant"),
  )
}

///|
test "wiki ingest skill preserves durable raw and wiki artifact contract" {
  let skill = research_wiki_ingest_skill_text(
    moonbook_adapter_external_research_entry(
      id="research-euv-lithography-machine-new-advantages-and-supplements",
      name="EUV lithography machine new advantages and supplements",
      purpose="Research EUV routes",
      workspace_root="/tmp/research-euv",
    ),
  )
  assert_true(skill.contains(research_question_path()))
  assert_true(skill.contains(research_source_screen_path()))
  assert_true(skill.contains(research_evidence_matrix_path()))
  assert_true(
    !research_ingest_required_raw_files_section()
    .join("\n")
    .contains("deep-report.md"),
  )
  assert_true(skill.contains("wiki/sources/"))
  assert_true(skill.contains("wiki/entities/"))
  assert_true(skill.contains("wiki/concepts/"))
  assert_true(skill.contains("wiki/synthesis/"))
}

///|
test "research bootstrap context uses full raw handoff artifact contract" {
  let contract = research_bootstrap_required_artifacts_contract()
  assert_true(contract.contains(research_question_path()))
  assert_true(contract.contains(research_deep_report_path()))
  assert_true(contract.contains(research_marketing_brief_path()))
}

///|
test "research ingest mandatory steps use shared raw artifact paths" {
  let method_text = research_ingest_mandatory_method_section().join("\n")
  assert_true(method_text.contains(research_question_path()))
  assert_true(method_text.contains(research_search_log_path()))
  assert_true(method_text.contains(research_source_screen_path()))
  assert_true(method_text.contains(research_evidence_matrix_path()))
  assert_true(method_text.contains(research_marketing_brief_path()))
  assert_true(method_text.contains(research_tool_blockers_path()))
}

///|
test "verified source page criteria reject candidate-only source pages" {
  let criteria = research_ingest_verified_source_page_section().join("\n")
  assert_true(criteria.contains("Source type: verified source digest"))
  assert_true(criteria.contains("source IDs such as `W1`, `W2`, `L1`"))
  assert_true(criteria.contains("inspected content summary"))
  assert_true(criteria.contains("extracted claim IDs"))
  assert_true(criteria.contains("explicit blockers"))
}

///|
test "source diarize skill keeps claim-level packet requirements" {
  let skill = research_source_diarize_skill_text(
    moonbook_adapter_catalog_entry(
      id="research-moonclaw",
      name="MoonClaw",
      purpose="Research MoonClaw",
      workspace_root="/tmp/research-moonclaw",
    ),
  )
  assert_true(skill.contains("name: source-diarize"))
  assert_true(skill.contains("W1`, `W2`, `W3"))
  assert_true(skill.contains("L1`, `L2`, `L3"))
  assert_true(skill.contains("B1`: blocker records"))
  assert_true(skill.contains("falsifiable sentence"))
  assert_true(
    skill.contains(
      "Do not create a verified source page from a candidate URL list alone",
    ),
  )
}
