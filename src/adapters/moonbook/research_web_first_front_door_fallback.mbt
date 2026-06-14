///|
fn web_first_front_door_fallback_section() -> Array[String] {
  [
    "## Source-Class Front-Door Fallback",
    "",
    web_first_front_door_fallback_intent(),
    "",
    web_first_source_class_derivation_step(),
    web_first_source_class_choice_step(),
    web_first_domain_front_door_step(),
    web_first_candidate_harvest_step(),
    web_first_harvested_candidate_fetch_step(),
    web_first_front_door_stop_rule(),
    "",
    "Concrete front-door command pattern:",
    "",
    "- fetch `https://<domain>/robots.txt` and look for `Sitemap:` entries",
    "- fetch likely sitemap URLs such as `https://<domain>/sitemap.xml` only when chosen by the worker for that domain",
    "- fetch the domain home page and one visible topic/search/index page",
    "- extract candidate links containing topic terms, route names, or source-class terms",
    "- fetch candidate article/report/product/paper pages; only these fetched content pages normally count as included evidence",
    "- write a `Front-Door Attempts` table in `\{@research_policy.search_log_path()}` with domain, command target, harvested candidates, fetched candidates, and result",
    "- write a `Command Fallback Attempts` table whenever native search was weak and command-line fetching was used",
    "",
  ]
}

///|
fn web_first_front_door_fallback_intent() -> String {
  web_first_text([
    "If generic search pages block extraction, shift from search-engine", "discovery to source-domain discovery instead of guessing article URLs",
    "from memory.",
  ])
}

///|
fn web_first_source_class_derivation_step() -> String {
  web_first_text([
    "1. Derive source classes for the topic:",
    "\{@research_policy.front_door_source_classes()}.",
  ])
}

///|
fn web_first_source_class_choice_step() -> String {
  web_first_text([
    "2. For each source class, choose candidate organizations or publications", "that a serious researcher would inspect for this topic.",
  ])
}

///|
fn web_first_domain_front_door_step() -> String {
  web_first_text([
    "3. For each chosen domain, fetch the home page, `robots.txt`, one or more",
    "sitemap URLs if exposed, visible search or index pages, and high-signal", "navigation pages.",
  ])
}

///|
fn web_first_candidate_harvest_step() -> String {
  web_first_text([
    "4. Harvest candidate links whose titles, paths, or snippets match the",
    "topic keywords; write them into `\{@research_policy.search_log_path()}` before",
    "fetching.",
  ])
}

///|
fn web_first_harvested_candidate_fetch_step() -> String {
  web_first_text([
    "5. Fetch at least \{@research_policy.harvest_candidate_fetch_count()} high-signal harvested candidate pages, or all",
    "harvested candidates when fewer than \{@research_policy.harvest_candidate_fetch_count()}, and screen them. A 404 on one",
    "guessed URL is a rejected candidate, not a rejected source class.",
  ])
}

///|
fn web_first_front_door_stop_rule() -> String {
  web_first_text([
    "6. Continue until the source screen has at least \{@research_policy.min_included_sources()} included inspected",
    "sources, \{@research_policy.preferred_included_sources()} preferred, or until \{@research_policy.discovery_attempt_limit()} bounded attempts plus a",
    "source-depth blocker make more discovery dishonest.",
  ])
}
