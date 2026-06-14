///|
fn web_first_rules_section(topic : String) -> Array[String] {
  [
    "## Rules",
    "",
    "- Start with web discovery before local file discovery. Use native `web_search` when it is available.",
    web_first_native_search_rule(),
    web_first_command_discovery_rule(),
    "- Run at least three web queries for this topic.",
    web_first_source_depth_rule(),
    web_first_discovery_artifact_rule(),
    web_first_front_door_rule(),
    web_first_harvest_rule(),
    web_first_source_depth_blocker_rule(),
    web_first_authority_rule(topic),
    "- After search, inspect at least two highest-signal pages before writing conclusions. Use native `web_fetch` if available; otherwise use bounded command-line fetches.",
    web_first_result_page_rule(),
    "- Write durable notes into `\{@research_policy.search_log_path()}` and `\{@research_policy.source_screen_path()}` before inspecting the local repo.",
    web_first_local_rule(topic),
    "- If all web access paths are unavailable, write `\{@research_policy.tool_blockers_path()}` and continue only with clearly provisional evidence instead of silently skipping the phase.",
    "- Do not cite search snippets as verified evidence unless fetch is blocked and the source is clearly labeled provisional.",
    "- Do not mark a source page verified unless it contains inspected source content, extracted claims, and provenance.",
    "",
  ]
}

///|
fn web_first_native_search_rule() -> String {
  web_first_text([
    "- If native `web_search` or `web_fetch` is disabled, unavailable, stalls,",
    "returns only search-engine/redirect pages, or leaves the source base below",
    "\{@research_policy.min_included_sources()} included inspected sources, use bounded `execute_command` discovery",
    "such as `curl -L --max-time 12` against LLM-chosen search-result pages",
    "and candidate URLs before local file discovery.",
  ])
}

///|
fn web_first_command_discovery_rule() -> String {
  web_first_text([
    "- In command-line discovery mode, first write the planned",
    "query/source-screening strategy to `\{@research_policy.search_log_path()}`, then",
    "run a small bounded command batch. Do not spend a long model turn",
    "planning before the first durable write or command.",
  ])
}

///|
fn web_first_source_depth_rule() -> String {
  web_first_text([
    "- For comparative or technology-route research, try to cover at least",
    "\{@research_policy.min_included_sources()} high-signal sources across",
    "\{@research_policy.core_source_classes()} classes before",
    "synthesis. \{@research_policy.preferred_included_sources()} or more included sources is preferred for a 12k-15k",
    "dossier.",
  ])
}

///|
fn web_first_discovery_artifact_rule() -> String {
  web_first_text([
    "- Do not count search pages, site search pages, hub pages, or index pages",
    "as included evidence just because they were fetched. Use", "`discovery_only`, `candidate`, or `exclude` unless the page itself",
    "contains substantive inspected claims.",
  ])
}

///|
fn web_first_front_door_rule() -> String {
  web_first_text([
    "- Keep discovery bounded but serious. Do not stop below \{@research_policy.min_included_sources()} included",
    "inspected sources merely because generic search-result pages are blocked.",
    "First try source-class front-door discovery, domain sitemaps, on-site",
    "search/index pages, and link harvesting.",
  ])
}

///|
fn web_first_harvest_rule() -> String {
  web_first_text([
    "- When sitemap/front-door harvesting yields candidate content URLs:",
    "convert the harvest into inspected sources, fetch at least \{@research_policy.harvest_candidate_fetch_count()}",
    "high-signal candidates, or every harvested candidate when fewer than",
    "\{@research_policy.harvest_candidate_fetch_count()}, before declaring the source base thin.",
  ])
}

///|
fn web_first_source_depth_blocker_rule() -> String {
  web_first_text([
    "- Stop below \{@research_policy.min_included_sources()} included sources only after \{@research_policy.discovery_attempt_limit()} web/discovery",
    "attempts and an explicit source-depth blocker. In that case write",
    "`ready_for_12k_dossier: false` into `\{@research_policy.source_screen_path()}`.",
  ])
}

///|
fn web_first_result_page_rule() -> String {
  web_first_text([
    "- If native `web_search` returns only a search-engine URL or weak result", "page, fetch the result page with native fetch; if that cannot extract",
    "candidates, use `execute_command`/`curl`, extract candidates when", "possible, and retry query variants before writing a blocker.",
  ])
}

///|
fn web_first_authority_rule(topic : String) -> String {
  if is_external_domain_research_topic(topic) {
    web_first_text([
      "- Prefer reputable current coverage, primary-source pages,", "official/regulatory material, research reports, expert essays, and",
      "clearly dated news. Do not prefer code repositories unless the topic is",
      "actually a software project.",
    ])
  } else {
    "- Prefer authoritative pages: official docs, repo pages, maintainer docs, and project READMEs."
  }
}

///|
fn web_first_local_rule(topic : String) -> String {
  if is_external_domain_research_topic(topic) {
    web_first_text([
      "- Do not inspect a local repository by guessing from the topic name.", "Use local files only when explicitly listed in `SOURCE_HINTS.md` or",
      "when web evidence points to a concrete local artifact.",
    ])
  } else {
    "- Only then inspect the local repo to corroborate architecture, implementation, and file-level details."
  }
}
