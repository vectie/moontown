///|
pub fn default_daemon_runtime_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{daemon_base_dir(snapshot_path)}/daemon-runtime.json"
}

///|
pub fn default_daemon_log_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{daemon_base_dir(snapshot_path)}/daemon.log"
}

///|
pub fn default_daemon_stop_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{daemon_base_dir(snapshot_path)}/daemon.stop"
}

///|
pub fn default_daemon_restart_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{daemon_base_dir(snapshot_path)}/daemon.restart"
}

///|
pub fn default_daemon_pid_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{daemon_base_dir(snapshot_path)}/daemon.pid"
}

///|
pub fn default_daemon_supervisor_pid_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{daemon_base_dir(snapshot_path)}/daemon-supervisor.pid"
}

///|
fn daemon_base_dir(snapshot_path : String) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  if base == "." || base == "" {
    ".moontown"
  } else {
    base
  }
}

///|
fn default_daemon_state_path(snapshot_path : String) -> String {
  "\{daemon_base_dir(snapshot_path)}/daemon.json"
}

///|
fn default_standing_goal_state_path(snapshot_path : String) -> String {
  let base = daemon_base_dir(snapshot_path)
  if base == ".moontown" {
    @storage.default_standing_goal_path()
  } else {
    "\{base}/standing-goals.json"
  }
}
