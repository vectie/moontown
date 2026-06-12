///|
test "research request source screening policy is explicit and web first" {
  let entry = moonbook_adapter_external_research_entry(
    id="research-euv-lithography-machine-new-advantages-and-supplements",
    name="EUV lithography machine new advantages and supplements",
    purpose="Research EUV technology routes",
    workspace_root="/tmp/research-euv",
  )
  let request = research_request_text(entry)
  assert_true(
    request.contains("Run at least three targeted web-discovery attempts"),
  )
  assert_true(request.contains("Command Fallback Attempts"))
  assert_true(
    request.contains("fetch at least eight high-signal candidate pages"),
  )
  assert_true(request.contains("ready_for_12k_dossier: false"))
  assert_true(request.contains("exact source-depth blocker"))
  assert_true(request.contains("12k-15k English words"))
}

///|
test "external research request does not infer local repository from topic" {
  let entry = moonbook_adapter_opc_research_entry()
  let request = research_request_text(entry)
  assert_true(request.contains("Do not infer a local repository"))
  assert_true(request.contains("SOURCE_HINTS.md"))
  assert_true(
    request.contains(
      "fetched sources prove local implementation material is relevant",
    ),
  )
  assert_true(
    !request.contains("prioritizing official repositories, maintainer docs"),
  )
}

///|
test "project research request prefers repository sources after web discovery" {
  let entry = moonbook_adapter_catalog_entry(
    id="research-moonbook",
    name="MoonBook",
    purpose="Research MoonBook",
    workspace_root="/tmp/research-moonbook",
  )
  let request = research_request_text(entry)
  assert_true(
    request.contains("prioritizing official repositories, maintainer docs"),
  )
  assert_true(
    request.contains(
      "Only after web discovery, inspect high-signal local files",
    ),
  )
  assert_true(
    !request.contains("Do not infer a local repository from the topic name"),
  )
}

///|
test "research request helper bullets preserve quality and reference contracts" {
  let depth = research_depth_target_bullet()
  assert_true(depth.contains(research_policy_deep_dossier_word_target()))
  assert_true(depth.contains("screened source base"))
  assert_true(depth.contains("exact source-class blocker"))
  let reference = research_reference_style_bullet("EUV")
  assert_true(reference.contains("REFERENCE_STYLE.md"))
  assert_true(reference.contains("visualization standard"))
  assert_true(reference.contains("not evidence for EUV"))
}

///|
test "research request fallback helpers preserve web-first execution contract" {
  let web_step = research_web_discovery_step()
  assert_true(
    web_step.contains("Run at least three targeted web-discovery attempts"),
  )
  assert_true(web_step.contains("Use native `web_search` when available"))
  assert_true(web_step.contains("bounded command-line discovery"))
  assert_true(web_step.contains(research_policy_command_fetch_pattern()))
  let fallback = research_web_search_result_fallback_step()
  assert_true(fallback.contains("extract result URLs and titles"))
  assert_true(fallback.contains("before guessing direct source URLs"))
}

///|
test "research request execution helpers use shared quality policy" {
  assert_true(
    research_command_fallback_log_step().contains(
      research_policy_min_included_sources(),
    ),
  )
  assert_true(
    research_command_fallback_log_step().contains(research_search_log_path()),
  )
  assert_true(
    research_candidate_page_fetch_step().contains(
      research_policy_harvest_candidate_fetch_count(),
    ),
  )
  assert_true(
    research_included_source_depth_target().contains(
      research_policy_min_included_sources(),
    ),
  )
  assert_true(
    research_deep_report_step().contains(
      research_policy_deep_dossier_word_target(),
    ),
  )
  assert_true(research_deep_report_step().contains(research_deep_report_path()))
}

///|
test "research request blocking helpers keep evidence accounting strict" {
  let rules = research_blocking_rules().join("\n")
  assert_true(rules.contains(research_tool_blockers_path()))
  assert_true(rules.contains("search-engine result page"))
  assert_true(rules.contains("Retry `{bad request}` once"))
  assert_true(rules.contains("do not pretend web evidence exists"))
  assert_true(rules.contains("source status as `blocked`"))
}

///|
test "research request execution order uses shared artifact paths" {
  let order = research_execution_order(true).join("\n")
  assert_true(order.contains(research_question_path()))
  assert_true(order.contains(research_search_log_path()))
  assert_true(order.contains(research_source_screen_path()))
  assert_true(order.contains(research_evidence_matrix_path()))
  assert_true(order.contains(research_local_sources_path()))
  assert_true(order.contains(research_synthesis_brief_path()))
  assert_true(order.contains(research_deep_report_path()))
  assert_true(order.contains(research_marketing_brief_path()))
}
