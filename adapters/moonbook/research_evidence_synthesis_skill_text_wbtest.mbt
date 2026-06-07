///|
test "research evidence synthesis skill preserves policy-backed depth contract" {
  let skill = research_evidence_synthesis_skill_text(
    moonbook_adapter_external_research_entry(
      id="research-euv-lithography-machine-new-advantages-and-supplements",
      name="EUV lithography machine new advantages and supplements",
      purpose="Research EUV routes",
      workspace_root="/tmp/research-euv",
    ),
  )
  assert_true(skill.contains("name: research-evidence-synthesis"))
  assert_true(skill.contains("## Reference-Aware Synthesis"))
  assert_true(skill.contains(research_policy_deep_dossier_word_target()))
  assert_true(skill.contains(research_policy_min_included_sources()))
  assert_true(skill.contains(research_policy_preferred_included_sources()))
  assert_true(skill.contains("do not pad with repeated definitions"))
}

///|
test "research evidence synthesis skill uses shared artifact paths" {
  let topic = "moonclaw"
  let section = research_evidence_wiki_materialization_section(topic)
  assert_true(section.contains(research_topic_source_page(topic)))
  assert_true(section.contains(research_topic_entity_page(topic)))
  assert_true(section.contains(research_topic_concept_page(topic)))
  assert_true(section.contains(research_topic_synthesis_page(topic)))
  assert_true(section.contains(research_marketing_brief_path()))
  assert_true(
    research_evidence_matrix_schema_section("MoonClaw").contains(
      research_evidence_matrix_path(),
    ),
  )
}

///|
test "research evidence synthesis sections keep failure and provenance rules" {
  let skill = research_evidence_synthesis_skill_text(
    moonbook_adapter_catalog_entry(
      id="research-moonbook",
      name="MoonBook",
      purpose="Research MoonBook",
      workspace_root="/tmp/research-moonbook",
    ),
  )
  assert_true(skill.contains("Every durable page must include provenance"))
  assert_true(skill.contains("Use claim IDs and source IDs"))
  assert_true(
    skill.contains(
      "Create provisional pages only when they are labeled provisional",
    ),
  )
  assert_true(skill.contains("explain the exact missing source or tool"))
}
