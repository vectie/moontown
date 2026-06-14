///|
test "web first skill for external topics avoids guessed local repos" {
  let entry = moonbook_adapter_opc_research_entry()
  let skill = web_first_research_skill_text(entry)
  assert_true(skill.contains("name: web-first-research"))
  assert_true(skill.contains("Do not inspect a local repository by guessing"))
  assert_true(skill.contains("SOURCE_HINTS.md"))
  assert_true(skill.contains("Do not prefer code repositories"))
  assert_true(!skill.contains("official docs, repo pages, maintainer docs"))
}

///|
test "web first skill for project topics allows local corroboration after web" {
  let entry = moonbook_adapter_catalog_entry(
    id="research-moonbook",
    name="MoonBook",
    purpose="Research MoonBook",
    workspace_root="/tmp/research-moonbook",
  )
  let skill = web_first_research_skill_text(entry)
  assert_true(skill.contains("official docs, repo pages, maintainer docs"))
  assert_true(skill.contains("Only then inspect the local repo"))
  assert_true(!skill.contains("Do not inspect a local repository by guessing"))
}

///|
test "web first skill preserves source depth and command fallback contract" {
  let skill = web_first_research_skill_text(
    moonbook_adapter_external_research_entry(
      id="research-euv-lithography-machine-new-advantages-and-supplements",
      name="EUV lithography machine new advantages and supplements",
      purpose="Research EUV routes",
      workspace_root="/tmp/research-euv",
    ),
  )
  assert_true(skill.contains("curl -L --max-time 12"))
  assert_true(skill.contains("{bad request}"))
  assert_true(skill.contains("twelve") || skill.contains("twenty-four"))
  assert_true(skill.contains("ready_for_12k_dossier: false"))
  assert_true(skill.contains("12k-15k English words"))
  assert_true(skill.contains("Front-Door Attempts"))
  assert_true(skill.contains("Command Fallback Attempts"))
}

///|
test "web first skill consumes centralized source-depth policy" {
  let skill = web_first_research_skill_text(
    moonbook_adapter_opc_research_entry(),
  )
  assert_true(skill.contains(@research_policy.min_included_sources()))
  assert_true(skill.contains(@research_policy.preferred_included_sources()))
  assert_true(skill.contains(@research_policy.harvest_candidate_fetch_count()))
  assert_true(skill.contains(@research_policy.discovery_attempt_limit()))
  assert_true(skill.contains(@research_policy.core_source_classes()))
  assert_true(skill.contains(@research_policy.front_door_source_classes()))
}

///|
test "web first required output uses shared bootstrap artifact paths" {
  let output = web_first_required_output_section("MoonClaw").join("\n")
  for path in @research_policy.raw_bootstrap_artifact_paths() {
    assert_true(output.contains("`\{path}`"))
  }
  assert_true(output.contains("Wiki-ready materialization notes"))
}

///|
test "web first json contract uses shared artifact and wiki page paths" {
  let topic = "moonclaw"
  let lines = web_first_output_contract_artifact_lines(topic).join("\n")
  assert_true(lines.contains("\"\{@research_policy.search_log_path()}\""))
  assert_true(lines.contains("\"\{@research_policy.evidence_matrix_path()}\""))
  assert_true(
    lines.contains("\"\{@research_policy.topic_source_page(topic)}\""),
  )
  assert_true(
    lines.contains("\"\{@research_policy.topic_entity_page(topic)}\""),
  )
  assert_true(
    lines.contains("\"\{@research_policy.topic_concept_page(topic)}\""),
  )
  assert_true(
    lines.contains("\"\{@research_policy.topic_synthesis_page(topic)}\""),
  )
}

///|
test "web first helper rules keep durable artifact boundaries visible" {
  assert_true(
    web_first_command_discovery_rule().contains(
      @research_policy.search_log_path(),
    ),
  )
  assert_true(web_first_discovery_artifact_rule().contains("discovery_only"))
  assert_true(web_first_source_depth_blocker_rule().contains("source-depth"))
  assert_true(
    web_first_source_depth_blocker_rule().contains(
      @research_policy.source_screen_path(),
    ),
  )
  assert_true(
    web_first_search_result_fetch_step().contains(
      "mandatory before closing below six",
    ),
  )
  assert_true(
    web_first_search_blocker_step().contains(
      @research_policy.tool_blockers_path(),
    ),
  )
  assert_true(web_first_source_depth_rule().contains("ten or more included"))
  assert_true(web_first_front_door_stop_rule().contains("twenty-four"))
}
