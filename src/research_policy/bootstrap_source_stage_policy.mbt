///|
pub fn bootstrap_missing_source_policy_prompt() -> String {
  bootstrap_prompt_text([
    "If something feels missing, write the missing source class into \{tool_blockers_path()}.",
    "Complete the best research pass from available screened leads.",
    "Never return a missing-input/adaptive-planning response.",
  ])
}

///|
pub fn bootstrap_source_expansion_harvest_policy_prompt() -> String {
  bootstrap_prompt_text([
    "When sitemaps or front doors harvest candidate content URLs, fetch at least \{harvest_candidate_fetch_count()} high-signal candidate pages.",
    "If fewer than \{harvest_candidate_fetch_count()} candidates are harvested, fetch all of them unless the domain blocks access.",
  ])
}
