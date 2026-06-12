///|
pub fn default_daemon_runtime_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  @daemon_runtime_policy.daemon_runtime_path_for_snapshot(snapshot_path)
}

///|
pub fn default_daemon_log_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  @daemon_runtime_policy.daemon_log_path_for_snapshot(snapshot_path)
}

///|
pub fn default_daemon_stop_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  @daemon_runtime_policy.daemon_stop_path_for_snapshot(snapshot_path)
}

///|
pub fn default_daemon_restart_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  @daemon_runtime_policy.daemon_restart_path_for_snapshot(snapshot_path)
}

///|
pub fn default_daemon_pid_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  @daemon_runtime_policy.daemon_pid_path_for_snapshot(snapshot_path)
}

///|
pub fn default_daemon_supervisor_pid_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  @daemon_runtime_policy.daemon_supervisor_pid_path_for_snapshot(snapshot_path)
}

///|
pub fn default_daemon_state_path(snapshot_path : String) -> String {
  @daemon_runtime_policy.daemon_state_path_for_snapshot(snapshot_path)
}

///|
pub fn default_standing_goal_state_path(snapshot_path : String) -> String {
  @daemon_runtime_policy.daemon_standing_goal_path_for_snapshot(
    snapshot_path,
    @storage.default_standing_goal_path(),
  )
}
