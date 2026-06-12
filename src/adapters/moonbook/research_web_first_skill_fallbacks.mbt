///|
fn web_first_search_result_fallback_section() -> Array[String] {
  [
    "## Search-Result Fallback",
    "",
    web_first_search_result_fallback_intent(),
    "",
    web_first_search_result_fetch_step(),
    "2. Extract candidate result URLs, titles, snippets, and domains into `\{research_search_log_path()}`.",
    web_first_search_candidate_class_step(),
    web_first_search_candidate_fetch_step(),
    web_first_search_blocker_step(),
    "",
  ]
}

///|
fn web_first_search_result_fallback_intent() -> String {
  web_first_text([
    "When native `web_search` returns only a search-engine page, weak landing", "page, or `{bad request}`, do not guess a final source list from memory.",
  ])
}

///|
fn web_first_search_result_fetch_step() -> String {
  web_first_text([
    "1. Fetch the search-result page itself with a bounded command such as",
    "`curl -L --max-time 12`; this command fallback is mandatory before",
    "closing below \{web_first_minimum_included_sources_text()} included inspected sources when native search was weak.",
  ])
}

///|
fn web_first_search_candidate_class_step() -> String {
  web_first_text([
    "3. Choose candidates across source classes:",
    "\{web_first_candidate_source_classes()}.",
  ])
}

///|
fn web_first_search_candidate_fetch_step() -> String {
  web_first_text([
    "4. Fetch selected result URLs and only then include, reject, or block",
    "them in `\{research_source_screen_path()}`.",
  ])
}

///|
fn web_first_search_blocker_step() -> String {
  web_first_text([
    "5. If search-result extraction is blocked, record the exact blocked page,",
    "command target, and source class in `\{research_tool_blockers_path()}`.",
  ])
}
