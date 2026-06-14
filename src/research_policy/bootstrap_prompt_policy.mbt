///|
fn bootstrap_prompt_text(lines : Array[String]) -> String {
  lines.join(" ")
}

///|
pub fn bootstrap_plain_markdown_no_json_fields_prompt() -> String {
  "Return plain Markdown, not JSON; do not use fields named verdict, substeps, suggested_substeps, or needs_subplan."
}

///|
pub fn bootstrap_reference_policy_prompt() -> String {
  bootstrap_prompt_text([
    bootstrap_reference_route_policy_prompt(),
    "Reference source hints are not evidence; they are candidate leads that must be fetched, screened, accepted, rejected, or marked blocked.",
    "Verify every adopted route independently.",
  ])
}

///|
pub fn bootstrap_reference_route_policy_prompt() -> String {
  bootstrap_prompt_text([
    "Reference output is not evidence.", "Its route names, comparison axes, diagrams, and section taxonomy may be used as hypothesis/search leads only when summarized by REFERENCE_STYLE.md or SOURCE_HINTS.md.",
    "Use those leads only when they are relevant to the user objective.",
  ])
}

///|
pub fn bootstrap_native_web_policy_prompt() -> String {
  bootstrap_prompt_text([
    "Use native web_search first when it is available, then use web_fetch on high-signal candidate pages.",
    "If a native web tool returns {bad request}, retry once with a simpler query or URL.",
    "If native web tools are unavailable, blocked, or return only weak search pages, fall back to bounded execute_command discovery.",
    bootstrap_weak_native_search_definition_prompt(),
  ])
}

///|
pub fn bootstrap_weak_native_search_definition_prompt() -> String {
  bootstrap_prompt_text([
    "Weak native search means search-engine result URLs, redirect shells, snippets without source URLs, generic index pages, or thin inspected-source coverage.",
    "Coverage is thin when native discovery yields fewer than \{min_included_sources()} included inspected sources.",
  ])
}

///|
pub fn bootstrap_command_fallback_policy_prompt() -> String {
  bootstrap_prompt_text([
    "In fallback mode, you must call execute_command with bounded curl/front-door commands before closing source screening below \{min_included_sources()} included sources.",
    bootstrap_search_result_fetch_prompt(),
    bootstrap_front_door_discovery_prompt(),
    bootstrap_harvest_to_inspection_prompt(),
    "Do not stop at a sitemap/index harvest; harvested URLs are only leads until fetched and screened.",
    "In fallback/front-door mode, write a Command Fallback Attempts table with each command target, source class, harvested candidate count, fetched candidate count, and result.",
    "Do not treat the first guessed 404 URL as exhausting a source class.",
    bootstrap_curl_target_prompt(),
    "First update \{search_log_path()} with a source-screening plan, then immediately run the web-discovery tool path; do not spend a long model turn planning.",
  ])
}

///|
pub fn bootstrap_search_result_fetch_prompt() -> String {
  bootstrap_prompt_text([
    "Fetch the search-result page itself.", "extract candidate result URLs and titles, then fetch selected result URLs.",
    "Do not skip directly to guessed URLs unless search-result extraction is blocked.",
  ])
}

///|
pub fn bootstrap_front_door_discovery_prompt() -> String {
  bootstrap_prompt_text([
    "If search-result extraction is blocked, pivot to source-class front-door discovery.",
    "Choose authoritative organizations for the topic.", "Fetch their home pages, robots.txt, sitemap files, visible search/index pages, and navigation pages.",
    "Harvest candidate links with topic keywords, then fetch selected candidates.",
  ])
}

///|
pub fn bootstrap_harvest_to_inspection_prompt() -> String {
  bootstrap_prompt_text([
    "When any front-door or sitemap step harvests candidate content URLs, convert the harvest into inspection.",
    "Fetch at least \{harvest_candidate_fetch_count()} high-signal candidate pages.",
    "If fewer than \{harvest_candidate_fetch_count()} candidate pages are harvested, fetch all of them unless each unfetched class is explicitly blocked.",
  ])
}

///|
pub fn bootstrap_curl_target_prompt() -> String {
  bootstrap_prompt_text([
    "Use commands such as \{command_fetch_pattern()} against LLM-chosen search-result pages, source-domain front doors, robots.txt, sitemaps, index pages, and selected source URLs.",
  ])
}

///|
pub fn bootstrap_source_depth_policy_prompt() -> String {
  bootstrap_prompt_text([
    bootstrap_preferred_source_mix_prompt(),
    "\{min_included_sources_sentence_start()} included sources is the minimum for a cautious report; \{preferred_included_sources()} or more is the preferred source base for a \{deep_dossier_word_target()} dossier.",
    bootstrap_discovery_artifact_policy_prompt(),
    bootstrap_below_minimum_source_policy_prompt(),
  ])
}

///|
pub fn bootstrap_preferred_source_mix_prompt() -> String {
  bootstrap_prompt_text([
    "Keep this pass bounded but serious.",
    "For comparative, route-map, or technology research, try to screen \{preferred_included_source_range()} accessible high-signal sources before synthesis.",
    "Cover \{extended_source_classes()} classes.",
  ])
}

///|
pub fn bootstrap_discovery_artifact_policy_prompt() -> String {
  bootstrap_prompt_text([
    "Search pages, site search pages, hub pages, and index pages are discovery artifacts, not included evidence sources.",
    "Only count them as evidence when the page itself contains substantive inspected claims.",
    "Normally mark them discovery_only/candidate rather than include.",
  ])
}

///|
pub fn bootstrap_below_minimum_source_policy_prompt() -> String {
  bootstrap_prompt_text([
    "Do not stop below \{min_included_sources()} included inspected evidence sources merely because generic search pages are blocked.",
    "Exhaust source-class front-door discovery and direct source-domain link harvesting first.",
    "Only proceed below \{min_included_sources()} after \{discovery_attempt_limit()} web/discovery attempts.",
    "Also require recorded command fallback attempts, candidate-harvest conversion attempts, and an explicit source-depth blocker with ready_for_12k_dossier=false.",
  ])
}
