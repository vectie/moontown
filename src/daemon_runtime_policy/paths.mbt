///|
pub fn daemon_base_dir_for_snapshot(snapshot_path : String) -> String {
  @storage.snapshot_base_dir(snapshot_path)
}

///|
pub fn daemon_runtime_path_for_snapshot(snapshot_path : String) -> String {
  "\{daemon_base_dir_for_snapshot(snapshot_path)}/daemon-runtime.json"
}

///|
pub fn daemon_log_path_for_snapshot(snapshot_path : String) -> String {
  "\{daemon_base_dir_for_snapshot(snapshot_path)}/daemon.log"
}

///|
pub fn daemon_stop_path_for_snapshot(snapshot_path : String) -> String {
  "\{daemon_base_dir_for_snapshot(snapshot_path)}/daemon.stop"
}

///|
pub fn daemon_restart_path_for_snapshot(snapshot_path : String) -> String {
  "\{daemon_base_dir_for_snapshot(snapshot_path)}/daemon.restart"
}

///|
pub fn daemon_pid_path_for_snapshot(snapshot_path : String) -> String {
  "\{daemon_base_dir_for_snapshot(snapshot_path)}/daemon.pid"
}

///|
pub fn daemon_supervisor_pid_path_for_snapshot(
  snapshot_path : String,
) -> String {
  "\{daemon_base_dir_for_snapshot(snapshot_path)}/daemon-supervisor.pid"
}

///|
pub fn daemon_state_path_for_snapshot(snapshot_path : String) -> String {
  "\{daemon_base_dir_for_snapshot(snapshot_path)}/daemon.json"
}

///|
pub fn daemon_standing_goal_path_for_snapshot(
  snapshot_path : String,
  default_standing_goal_path : String,
) -> String {
  let base = daemon_base_dir_for_snapshot(snapshot_path)
  if base == ".moontown" {
    default_standing_goal_path
  } else {
    "\{base}/standing-goals.json"
  }
}
