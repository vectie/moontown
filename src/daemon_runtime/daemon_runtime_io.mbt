///|
pub fn daemon_run_id(prefix : String) -> String {
  "\{prefix}-\{@env.now()}"
}
