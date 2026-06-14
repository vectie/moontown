///|
pub fn request_source_screen_row_fields() -> String {
  "include/exclude, authority, recency, relevance, and risk."
}

///|
pub fn request_included_source_depth_target() -> String {
  "For complex external research, aim for at least \{min_included_sources()} included inspected evidence sources before synthesis;"
}

///|
pub fn request_discovery_artifact_exclusion() -> String {
  "search/index/hub pages are discovery artifacts and should not count unless they contain substantive inspected claims."
}

///|
pub fn request_source_depth_blocker_requirement() -> String {
  "If impossible after bounded source-domain discovery, write `ready_for_12k_dossier: false` and the exact source-depth blocker."
}
