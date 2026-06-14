///|
fn research_source_screen_step() -> String {
  [
    "5. Write `\{@research_policy.source_screen_path()}` with one row per inspected source:",
    research_source_screen_row_fields(),
    research_included_source_depth_target(),
    research_discovery_artifact_exclusion(),
    research_source_depth_blocker_requirement(),
  ].join(" ")
}

///|
fn research_source_screen_row_fields() -> String {
  "include/exclude, authority, recency, relevance, and risk."
}

///|
fn research_included_source_depth_target() -> String {
  "For complex external research, aim for at least \{@research_policy.min_included_sources()} included inspected evidence sources before synthesis;"
}

///|
fn research_discovery_artifact_exclusion() -> String {
  "search/index/hub pages are discovery artifacts and should not count unless they contain substantive inspected claims."
}

///|
fn research_source_depth_blocker_requirement() -> String {
  "If impossible after bounded source-domain discovery, write `ready_for_12k_dossier: false` and the exact source-depth blocker."
}
