///|
fn research_bootstrap_prompt(lines : Array[String]) -> String {
  lines.join(" ")
}

///|
fn research_bootstrap_plain_markdown_no_json_fields_prompt() -> String {
  "Return plain Markdown, not JSON; do not use fields named verdict, substeps, suggested_substeps, or needs_subplan."
}

///|
fn research_bootstrap_reference_policy_prompt() -> String {
  research_bootstrap_prompt([
    research_bootstrap_reference_route_policy_prompt(),
    "Reference source hints are not evidence; they are candidate leads that must be fetched, screened, accepted, rejected, or marked blocked.",
    "Verify every adopted route independently.",
  ])
}

///|
fn research_bootstrap_reference_route_policy_prompt() -> String {
  research_bootstrap_prompt([
    "Reference output is not evidence.", "Its route names, comparison axes, diagrams, and section taxonomy may be used as hypothesis/search leads only when summarized by REFERENCE_STYLE.md or SOURCE_HINTS.md.",
    "Use those leads only when they are relevant to the user objective.",
  ])
}

///|
fn research_bootstrap_native_web_policy_prompt() -> String {
  research_bootstrap_prompt([
    "Use native web_search first when it is available, then use web_fetch on high-signal candidate pages.",
    "If a native web tool returns {bad request}, retry once with a simpler query or URL.",
    "If native web tools are unavailable, blocked, or return only weak search pages, fall back to bounded execute_command discovery.",
    research_bootstrap_weak_native_search_definition_prompt(),
  ])
}

///|
fn research_bootstrap_weak_native_search_definition_prompt() -> String {
  research_bootstrap_prompt([
    "Weak native search means search-engine result URLs, redirect shells, snippets without source URLs, generic index pages, or thin inspected-source coverage.",
    "Coverage is thin when native discovery yields fewer than \{research_policy_min_included_sources()} included inspected sources.",
  ])
}

///|
fn research_bootstrap_command_fallback_policy_prompt() -> String {
  research_bootstrap_prompt([
    "In fallback mode, you must call execute_command with bounded curl/front-door commands before closing source screening below \{research_policy_min_included_sources()} included sources.",
    research_bootstrap_search_result_fetch_prompt(),
    research_bootstrap_front_door_discovery_prompt(),
    research_bootstrap_harvest_to_inspection_prompt(),
    "Do not stop at a sitemap/index harvest; harvested URLs are only leads until fetched and screened.",
    "In fallback/front-door mode, write a Command Fallback Attempts table with each command target, source class, harvested candidate count, fetched candidate count, and result.",
    "Do not treat the first guessed 404 URL as exhausting a source class.",
    research_bootstrap_curl_target_prompt(),
    "First update \{research_search_log_path()} with a source-screening plan, then immediately run the web-discovery tool path; do not spend a long model turn planning.",
  ])
}

///|
fn research_bootstrap_search_result_fetch_prompt() -> String {
  research_bootstrap_prompt([
    "Fetch the search-result page itself.", "extract candidate result URLs and titles, then fetch selected result URLs.",
    "Do not skip directly to guessed URLs unless search-result extraction is blocked.",
  ])
}

///|
fn research_bootstrap_front_door_discovery_prompt() -> String {
  research_bootstrap_prompt([
    "If search-result extraction is blocked, pivot to source-class front-door discovery.",
    "Choose authoritative organizations for the topic.", "Fetch their home pages, robots.txt, sitemap files, visible search/index pages, and navigation pages.",
    "Harvest candidate links with topic keywords, then fetch selected candidates.",
  ])
}

///|
fn research_bootstrap_harvest_to_inspection_prompt() -> String {
  research_bootstrap_prompt([
    "When any front-door or sitemap step harvests candidate content URLs, convert the harvest into inspection.",
    "Fetch at least \{research_policy_harvest_candidate_fetch_count()} high-signal candidate pages.",
    "If fewer than \{research_policy_harvest_candidate_fetch_count()} candidate pages are harvested, fetch all of them unless each unfetched class is explicitly blocked.",
  ])
}

///|
fn research_bootstrap_curl_target_prompt() -> String {
  research_bootstrap_prompt([
    "Use commands such as \{research_policy_command_fetch_pattern()} against LLM-chosen search-result pages, source-domain front doors, robots.txt, sitemaps, index pages, and selected source URLs.",
  ])
}

///|
fn research_bootstrap_source_depth_policy_prompt() -> String {
  research_bootstrap_prompt([
    research_bootstrap_preferred_source_mix_prompt(),
    "\{research_policy_min_included_sources_sentence_start()} included sources is the minimum for a cautious report; \{research_policy_preferred_included_sources()} or more is the preferred source base for a \{research_policy_deep_dossier_word_target()} dossier.",
    research_bootstrap_discovery_artifact_policy_prompt(),
    research_bootstrap_below_minimum_source_policy_prompt(),
  ])
}

///|
fn research_bootstrap_preferred_source_mix_prompt() -> String {
  research_bootstrap_prompt([
    "Keep this pass bounded but serious.",
    "For comparative, route-map, or technology research, try to screen \{research_policy_preferred_included_source_range()} accessible high-signal sources before synthesis.",
    "Cover primary, independent, research-institution, market/adoption, critique/risk, and primary-paper/source-data classes.",
  ])
}

///|
fn research_bootstrap_discovery_artifact_policy_prompt() -> String {
  research_bootstrap_prompt([
    "Search pages, site search pages, hub pages, and index pages are discovery artifacts, not included evidence sources.",
    "Only count them as evidence when the page itself contains substantive inspected claims.",
    "Normally mark them discovery_only/candidate rather than include.",
  ])
}

///|
fn research_bootstrap_below_minimum_source_policy_prompt() -> String {
  research_bootstrap_prompt([
    "Do not stop below \{research_policy_min_included_sources()} included inspected evidence sources merely because generic search pages are blocked.",
    "Exhaust source-class front-door discovery and direct source-domain link harvesting first.",
    "Only proceed below \{research_policy_min_included_sources()} after \{research_policy_discovery_attempt_limit()} web/discovery attempts.",
    "Also require recorded command fallback attempts, candidate-harvest conversion attempts, and an explicit source-depth blocker with ready_for_12k_dossier=false.",
  ])
}
