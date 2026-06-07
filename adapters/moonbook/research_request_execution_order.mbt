///|
fn research_execution_order(external_domain : Bool) -> Array[String] {
  [
    research_scope_step(),
    research_web_discovery_step(),
    research_web_search_result_fallback_step(),
    research_front_door_discovery_step(),
    research_command_fallback_log_step(),
    research_candidate_page_fetch_step(),
    research_source_class_exhaustion_step(),
    research_web_priority_step(external_domain),
    research_search_log_step(),
    research_source_screen_step(),
    research_evidence_matrix_step(),
    research_local_inspection_step(external_domain),
    research_local_sources_step(),
    research_synthesis_brief_step(),
    research_deep_report_step(),
    research_marketing_brief_step(),
    research_materialization_handoff_step(),
  ]
}

///|
fn research_scope_step() -> String {
  "1. Write `\{research_question_path()}` with scope, inclusion criteria, exclusion criteria, keywords, and known source classes."
}

///|
fn research_web_discovery_step() -> String {
  research_numbered_step(2, [
    "Run at least three targeted web-discovery attempts before local file discovery.",
    research_native_search_or_command_fallback_clause(),
  ])
}

///|
fn research_web_priority_step(external_domain : Bool) -> String {
  if external_domain {
    research_numbered_step(3, [
      "Fetch or otherwise inspect the highest-signal pages you found with the available web access path.",
      "Prioritize current reputable coverage, primary sources, official pages, regulatory or standards material, and well-sourced expert analysis.",
    ])
  } else {
    research_numbered_step(3, [
      "Fetch or otherwise inspect the highest-signal pages you found with the available web access path.",
      "prioritizing official repositories, maintainer docs, release docs, and project pages.",
    ])
  }
}

///|
fn research_search_log_step() -> String {
  "4. Write `\{research_search_log_path()}` with query strings, result counts if available, selected URLs, rejected URLs, and the reason for each decision."
}

///|
fn research_evidence_matrix_step() -> String {
  "6. Extract claims into `\{research_evidence_matrix_path()}` before synthesis. Use claim IDs like `C1`, `C2`, and cite source IDs like `W1` or `L1`."
}

///|
fn research_numbered_step(number : Int, clauses : Array[String]) -> String {
  "\{number}. \{clauses.join(" ")}"
}

///|
fn research_substep(clauses : Array[String]) -> String {
  "   - \{clauses.join(" ")}"
}

///|
fn research_native_search_or_command_fallback_clause() -> String {
  let native_first = "Use native `web_search` when available."
  let weak_native_gate = "If it returns only weak search pages, redirect shells, or fewer than \{research_policy_min_included_sources()} included inspected sources, use bounded command-line discovery."
  let command_fallback = "Use commands such as `\{research_policy_command_fetch_pattern()}` against LLM-chosen search pages and candidate URLs before closing the source-screening stage."
  [native_first, weak_native_gate, command_fallback].join(" ")
}
