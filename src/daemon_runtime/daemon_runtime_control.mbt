///|
pub async fn daemon_stop_saved_town(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  let launchd_stopped = stop_daemon_with_launchd()
  write_daemon_stop_request(snapshot_path)
  let health = inspect_daemon_runtime(snapshot_path~)
  let worker_killed = kill_daemon_pid_force(health.worker_pid)
  let supervisor_killed = kill_daemon_pid_force(health.supervisor_pid)
  mark_daemon_stopped(snapshot_path, "stop requested")
  append_daemon_log(
    default_daemon_log_path(snapshot_path~),
    "stop requested launchd_stopped=\{launchd_stopped} worker_pid=\{health.worker_pid} worker_killed=\{worker_killed} supervisor_pid=\{health.supervisor_pid} supervisor_killed=\{supervisor_killed}",
  )
  "MoonTown daemon stop requested\nlaunchd_stopped=\{launchd_stopped}\nworker_pid=\{health.worker_pid} worker_killed=\{worker_killed}\nsupervisor_pid=\{health.supervisor_pid} supervisor_killed=\{supervisor_killed}"
}

///|
pub async fn daemon_doctor_saved_town(
  snapshot_path? : String = @storage.default_snapshot_path(),
  stale_after_ms? : UInt64 = 900_000UL,
) -> String {
  let health = inspect_daemon_runtime(snapshot_path~, stale_after_ms~)
  let builder = StringBuilder::new()
  builder.write_string("MoonTown daemon doctor\n")
  builder.write_string(
    "\{@daemon_runtime_policy.daemon_runtime_health_summary(health)}\n",
  )
  if health.healthy() && !health.supervisor_alive {
    builder.write_string("durable=false reason=worker-without-supervisor\n")
  }
  builder.write_string(
    "action=\{@daemon_runtime_policy.daemon_runtime_doctor_action(health)}\n",
  )
  if !health.last_error.is_empty() {
    builder.write_string("last_error=\{health.last_error}\n")
  }
  builder.to_string()
}
