///|
fn research_web_search_result_fallback_step() -> String {
  research_substep([
    @research_policy.request_web_search_result_fallback_policy(),
  ])
}

///|
fn research_front_door_discovery_step() -> String {
  research_substep([@research_policy.request_front_door_discovery_policy()])
}

///|
fn research_command_fallback_log_step() -> String {
  research_substep([@research_policy.request_command_fallback_log_policy()])
}

///|
fn research_candidate_page_fetch_step() -> String {
  research_substep([@research_policy.request_candidate_page_fetch_policy()])
}

///|
fn research_source_class_exhaustion_step() -> String {
  research_substep([@research_policy.request_source_class_exhaustion_policy()])
}
