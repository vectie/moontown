///|
pub fn task_status_from_run_status(status : String?) -> String {
  match status {
    Some(status) if moonclaw_status_is_pending(status) => "dispatched"
    Some(status) if moonclaw_status_is_running(status) => "running"
    Some(status) if moonclaw_status_is_succeeded(status) => "failed"
    Some(status) if moonclaw_status_is_failed_terminal(status) => "failed"
    _ => "dispatched"
  }
}

///|
pub fn moonclaw_status_needs_live_runner(status : String) -> Bool {
  moonclaw_status_is_pending(status) || moonclaw_status_is_running(status)
}

///|
pub fn moonclaw_status_is_pending(status : String) -> Bool {
  moonclaw_status_bucket(Some(status)) == "pending"
}

///|
pub fn moonclaw_status_is_running(status : String) -> Bool {
  moonclaw_status_bucket(Some(status)) == "running"
}

///|
pub fn moonclaw_status_is_succeeded(status : String) -> Bool {
  moonclaw_status_bucket(Some(status)) == "succeeded"
}

///|
pub fn moonclaw_status_is_failed_terminal(status : String) -> Bool {
  moonclaw_status_bucket(Some(status)) == "failed-terminal"
}

///|
pub fn moonclaw_status_bucket(status : String?) -> String {
  match status {
    Some("Pending") => "pending"
    Some("Running") | Some("WaitingForInput") => "running"
    Some("Succeeded") => "succeeded"
    Some("Failed") | Some("Cancelled") => "failed-terminal"
    _ => "unknown"
  }
}
