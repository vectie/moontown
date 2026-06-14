///|
fn research_blocking_rules() -> Array[String] {
  [
    research_tool_blocker_rule(),
    research_native_result_page_rule(),
    research_native_disabled_rule(),
    research_missing_web_evidence_rule(),
  ]
}

///|
fn research_tool_blocker_rule() -> String {
  [
    "If a tool is unavailable, record the exact blocker in `\{@research_policy.tool_blockers_path()}`.",
    "Continue with the remaining permitted path and still create the durable bootstrap notes that explain what happened.",
  ].join(" ")
}

///|
fn research_native_result_page_rule() -> String {
  [
    "If native `web_search` returns only a search-engine result page or query URL, fetch that page.",
    "Extract candidate URLs if possible, and retry with broader or narrower query variants before declaring the web pass blocked.",
  ].join(" ")
}

///|
fn research_native_disabled_rule() -> String {
  [
    "If native `web_search` is disabled, stalls, or only returns weak search pages, use bounded command-line web discovery.",
    "Use commands such as `\{@research_policy.command_fetch_pattern()}` against LLM-chosen search-result pages and candidate URLs.",
    "Retry `{bad request}` once with a simpler query or URL before recording a blocker.",
  ].join(" ")
}

///|
fn research_missing_web_evidence_rule() -> String {
  let no_fake_evidence = "If web search or fetch fails, do not pretend web evidence exists."
  let blocked_status = "Mark the source status as `blocked`, use local sources only as provisional evidence, and make the wiki page say what is missing."
  [no_fake_evidence, blocked_status].join(" ")
}
