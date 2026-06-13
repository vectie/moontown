///|
pub struct DaemonTickPaths {
  daemon_path : String
  log_path : String
  goal_path : String
}

///|
pub fn daemon_tick_paths(snapshot_path : String) -> DaemonTickPaths {
  {
    daemon_path: default_daemon_state_path(snapshot_path),
    log_path: default_daemon_log_path(snapshot_path~),
    goal_path: default_standing_goal_state_path(snapshot_path),
  }
}

///|
pub fn daemon_tick_log_line(phase : String, sequence : Int) -> String {
  "tick phase=\{phase} sequence=\{sequence}"
}

///|
pub async fn append_daemon_tick_phase_log(
  log_path : String,
  phase : String,
  sequence : Int,
) -> Unit {
  append_daemon_log(log_path, daemon_tick_log_line(phase, sequence))
}

///|
pub async fn daemon_tick_runtime_lock_active(snapshot_path : String) -> Bool {
  let runtime = inspect_daemon_runtime(snapshot_path~)
  runtime.status == "ticking" &&
  runtime.worker_alive &&
  !runtime.stale &&
  runtime.heartbeat_age_ms < 120_000UL
}
