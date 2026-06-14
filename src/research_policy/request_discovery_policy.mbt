///|
pub fn request_native_search_or_command_fallback_policy() -> String {
  [
    "Use native `web_search` when available.",
    "If it returns only weak search pages, redirect shells, or fewer than \{min_included_sources()} included inspected sources, use bounded command-line discovery.",
    "Use commands such as `\{command_fetch_pattern()}` against LLM-chosen search pages and candidate URLs before closing the source-screening stage.",
  ].join(" ")
}

///|
pub fn request_web_search_result_fallback_policy() -> String {
  [
    "If native search only returns search-engine pages, fetch those result pages with `execute_command`/`curl` when native fetch cannot extract results.",
    "Then extract result URLs and titles, and then inspect selected result URLs before guessing direct source URLs.",
  ].join(" ")
}

///|
pub fn request_front_door_discovery_policy() -> String {
  [
    "If search-result extraction is blocked, switch to source-domain front-door discovery.",
    "Choose authoritative organizations for each source class, fetch home pages, robots/sitemaps, on-site search/index pages, and navigation pages.",
    "Harvest candidate links, then fetch selected pages.",
  ].join(" ")
}

///|
pub fn request_command_fallback_log_policy() -> String {
  [
    "Record a `Command Fallback Attempts` table in `\{search_log_path()}` whenever native search is weak.",
    "Use it when the source screen remains below \{min_included_sources()} included inspected sources.",
  ].join(" ")
}

///|
pub fn request_candidate_page_fetch_policy() -> String {
  [
    "If sitemaps or front-door pages harvest candidate content URLs, fetch at least \{harvest_candidate_fetch_count()} high-signal candidate pages.",
    "Fetch all harvested candidate pages when fewer than \{harvest_candidate_fetch_count()} before declaring source depth blocked.",
  ].join(" ")
}

///|
pub fn request_source_class_exhaustion_policy() -> String {
  "Do not treat one guessed 404 as a failed source class. A source class is only exhausted after front-door discovery and bounded link harvesting fail."
}
