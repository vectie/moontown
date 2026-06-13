///|
pub fn mark_stale_retry_directive_kind() -> String {
  "mark-stale-retry"
}

///|
pub fn mark_stale_failed_directive_kind() -> String {
  "mark-stale-failed"
}

///|
pub fn retry_execution_directive_kind() -> String {
  "retry-execution"
}

///|
pub fn supervision_directive_marks_stale(kind : String) -> Bool {
  kind == mark_stale_retry_directive_kind() ||
  kind == mark_stale_failed_directive_kind()
}

///|
pub fn supervision_directive_retries_execution(kind : String) -> Bool {
  kind == retry_execution_directive_kind()
}
