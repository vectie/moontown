///|
pub async fn daemon_start_saved_town(
  snapshot_path? : String = @storage.default_snapshot_path(),
  command? : String = "",
  stale_after_ms? : UInt64 = 900_000UL,
) -> String {
  let command = daemon_command_or_current(command)
  let health = inspect_daemon_runtime(snapshot_path~, stale_after_ms~)
  if @daemon_runtime_policy.daemon_runtime_start_already_active(health) {
    return "Moontown daemon already active\n\{@daemon_runtime_policy.daemon_runtime_health_summary(health)}"
  }
  if health.stale || health.stop_requested {
    cleanup_stale_daemon_runtime(
      snapshot_path, health, "start cleaned stale or stopping runtime",
    )
  }
  clear_daemon_stop_request(snapshot_path)
  if daemon_launchd_preferred() && daemon_launchd_available() {
    append_daemon_log(
      default_daemon_log_path(snapshot_path~),
      "trying launchd daemon start",
    )
    if start_daemon_with_launchd(command) {
      let launchd = inspect_daemon_runtime_after_start(
        snapshot_path, stale_after_ms,
      )
      if @daemon_runtime_policy.daemon_runtime_start_already_active(launchd) {
        return "Moontown daemon launchd started\n\{@daemon_runtime_policy.daemon_runtime_health_summary(launchd)}"
      }
      append_daemon_log(
        default_daemon_log_path(snapshot_path~),
        "launchd daemon start degraded; trying detached fallback",
      )
    } else {
      append_daemon_log(
        default_daemon_log_path(snapshot_path~),
        "launchd daemon start failed; trying detached fallback",
      )
    }
  }
  let supervisor_run_id = daemon_run_id("supervisor")
  let pid = spawn_daemon_supervisor(command, snapshot_path) catch {
    error => {
      append_daemon_log(
        default_daemon_log_path(snapshot_path~),
        "supervisor spawn failed: \{error}",
      )
      return "Moontown daemon start failed: \{error}"
    }
  }
  if pid <= 0 {
    append_daemon_log(
      default_daemon_log_path(snapshot_path~),
      "supervisor spawn failed: pid unavailable",
    )
    return "Moontown daemon start failed: supervisor pid unavailable"
  }
  mark_daemon_supervisor_started(snapshot_path, pid, supervisor_run_id)
  append_daemon_log(
    default_daemon_log_path(snapshot_path~),
    "supervisor started pid=\{pid} run=\{supervisor_run_id}",
  )
  let next = inspect_daemon_runtime_after_start(snapshot_path, stale_after_ms)
  if @daemon_runtime_policy.daemon_runtime_start_already_active(next) {
    return "Moontown daemon supervisor started pid=\{pid}\n\{@daemon_runtime_policy.daemon_runtime_health_summary(next)}"
  }
  append_daemon_log(
    default_daemon_log_path(snapshot_path~),
    "detached supervisor degraded; trying launchd fallback",
  )
  if start_daemon_with_launchd(command) {
    let launchd = inspect_daemon_runtime_after_start(
      snapshot_path, stale_after_ms,
    )
    return "Moontown daemon launchd fallback started after detached pid=\{pid}\n\{@daemon_runtime_policy.daemon_runtime_health_summary(launchd)}"
  }
  "Moontown daemon supervisor started pid=\{pid} but degraded\n\{@daemon_runtime_policy.daemon_runtime_health_summary(next)}\nlaunchd_fallback=failed-or-unavailable"
}

///|
async fn inspect_daemon_runtime_after_start(
  snapshot_path : String,
  stale_after_ms : UInt64,
) -> DaemonRuntimeHealth {
  let mut latest = inspect_daemon_runtime(snapshot_path~, stale_after_ms~)
  let mut attempts = 0
  while attempts < 10 {
    if latest.healthy() || latest.stale {
      return latest
    }
    @async.sleep(500)
    latest = inspect_daemon_runtime(snapshot_path~, stale_after_ms~)
    attempts += 1
  }
  latest
}
