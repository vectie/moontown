///|
fn research_source_screen_step() -> String {
  [
    "5. Write `\{@research_policy.source_screen_path()}` with one row per inspected source:",
    @research_policy.request_source_screen_row_fields(),
    @research_policy.request_included_source_depth_target(),
    @research_policy.request_discovery_artifact_exclusion(),
    @research_policy.request_source_depth_blocker_requirement(),
  ].join(" ")
}
