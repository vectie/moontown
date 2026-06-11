///|
pub fn transient_external_dependency_error(detail : String) -> Bool {
  let lowered = detail.to_lower()
  lowered.contains("resource temporarily unavailable") ||
  lowered.contains("{bad request}") ||
  lowered.contains("bad request") ||
  lowered.contains("failed to resolve the module dependency graph") ||
  lowered.contains("unable to lock folder") ||
  lowered.contains("operation not permitted (os error 1)") ||
  lowered.contains("moontown external import timed out") ||
  lowered.contains("timed out while importing moonclaw proposal") ||
  lowered.contains("failed to load job definitions") ||
  lowered.contains("missing field workflows") ||
  lowered.contains(".mooncakes") ||
  (
    lowered.contains("runtime error: abort() called") &&
    (
      lowered.contains("stringbuilder::grow_if_necessary") ||
      lowered.contains("systemstore::save_job_proposals") ||
      lowered.contains("job/system_storage.mbt")
    )
  )
}
