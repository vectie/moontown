///|
fn research_web_search_result_fallback_step() -> String {
  research_substep([
    "If native search only returns search-engine pages, fetch those result pages with `execute_command`/`curl` when native fetch cannot extract results.",
    "Then extract result URLs and titles, and then inspect selected result URLs before guessing direct source URLs.",
  ])
}

///|
fn research_front_door_discovery_step() -> String {
  research_substep([
    "If search-result extraction is blocked, switch to source-domain front-door discovery.",
    "Choose authoritative organizations for each source class, fetch home pages, robots/sitemaps, on-site search/index pages, and navigation pages.",
    "Harvest candidate links, then fetch selected pages.",
  ])
}

///|
fn research_command_fallback_log_step() -> String {
  research_substep([
    "Record a `Command Fallback Attempts` table in `\{research_search_log_path()}` whenever native search is weak.",
    "Use it when the source screen remains below \{@research_policy.min_included_sources()} included inspected sources.",
  ])
}

///|
fn research_candidate_page_fetch_step() -> String {
  research_substep([
    "If sitemaps or front-door pages harvest candidate content URLs, fetch at least \{@research_policy.harvest_candidate_fetch_count()} high-signal candidate pages.",
    "Fetch all harvested candidate pages when fewer than \{@research_policy.harvest_candidate_fetch_count()} before declaring source depth blocked.",
  ])
}

///|
fn research_source_class_exhaustion_step() -> String {
  "   - Do not treat one guessed 404 as a failed source class. A source class is only exhausted after front-door discovery and bounded link harvesting fail."
}
