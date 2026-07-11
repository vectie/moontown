///|
pub async fn daemon_stop_requested(snapshot_path : String) -> Bool {
  @fs.exists(default_daemon_stop_path(snapshot_path~))
}

///|
pub async fn daemon_restart_requested(snapshot_path : String) -> Bool {
  @fs.exists(default_daemon_restart_path(snapshot_path~))
}

///|
async fn clear_daemon_stop_request(snapshot_path : String) -> Unit {
  remove_file_if_exists(default_daemon_stop_path(snapshot_path~))
}

///|
async fn clear_daemon_restart_request(snapshot_path : String) -> Unit {
  remove_file_if_exists(default_daemon_restart_path(snapshot_path~))
}

///|
async fn write_daemon_stop_request(snapshot_path : String) -> Unit {
  @support.write_text_file(
    default_daemon_stop_path(snapshot_path~),
    "stop requested at \{@env.now()}\n",
  ) catch {
    _ => ()
  }
}

///|
pub async fn write_daemon_restart_request(
  snapshot_path? : String = @storage.default_snapshot_path(),
  reason? : String = "reload requested",
) -> String {
  @support.write_text_file(
    default_daemon_restart_path(snapshot_path~),
    "restart requested at \{@env.now()}\nreason: \{reason}\n",
  ) catch {
    error => return "MoonTown daemon restart request failed: \{error}"
  }
  append_daemon_log(
    default_daemon_log_path(snapshot_path~),
    "restart requested reason=\{reason}",
  )
  "MoonTown daemon restart requested\npath=\{default_daemon_restart_path(snapshot_path~)}\nreason=\{reason}"
}
