///|
pub fn standing_watch_operational_no_change_summary(summary : String) -> Bool {
  if standing_watch_orphaned_running_failure_summary(summary) {
    return false
  }
  let lowered = summary.to_lower()
  (
    lowered.contains("persisted_result_review: false") ||
    lowered.contains("keeper_auto_triage: persisted_non_review_result") ||
    lowered.contains("keeper_auto_triage: transient_infrastructure_contention")
  ) &&
  standing_watch_summary_has_zero_material_delta(summary)
}

///|
pub fn standing_watch_orphaned_running_failure_summary(
  summary : String,
) -> Bool {
  let lowered = summary.to_lower()
  (
    lowered.contains("indexed as running") &&
    lowered.contains("no live proposal process was found")
  ) ||
  lowered.contains("treating it as failed for mayor recovery")
}

///|
pub fn standing_watch_infrastructure_failure_summary(summary : String) -> Bool {
  let lowered = summary.to_lower()
  lowered.contains("standing watch execution failed") &&
  (
    @runtime_error_policy.transient_external_dependency_error(lowered) ||
    lowered.contains("runtime error: abort() called") ||
    lowered.contains("stringbuilder::grow_if_necessary") ||
    lowered.contains("systemstore::save_job_proposals")
  )
}

///|
pub fn standing_watch_detached_import_log_noise_summary(
  detail : String,
) -> Bool {
  let lowered = detail.to_lower()
  let detached_import = lowered.contains("detached moonclaw import failed for")
  let startup_log = lowered.contains("\"tag\":\"model\"") ||
    lowered.contains("\"tag\":\"job-analysis\"") ||
    lowered.contains("loading skills from directory") ||
    lowered.contains("loaded skill")
  let terminal_signal = lowered.contains("failure(") ||
    lowered.contains(" failed:") ||
    lowered.contains("runtime error") ||
    lowered.contains("jsondecodeerror") ||
    lowered.contains("abort() called") ||
    lowered.contains("panic")
  detached_import && startup_log && !terminal_signal
}

///|
pub fn standing_watch_transient_dispatch_error(detail : String) -> Bool {
  @runtime_error_policy.transient_external_dependency_error(detail)
}

///|
pub fn standing_watch_stale_window_ticks() -> Int {
  120
}
