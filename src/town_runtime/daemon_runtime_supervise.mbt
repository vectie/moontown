///|
pub async fn daemon_supervise_saved_town(
  snapshot_path? : String = @storage.default_snapshot_path(),
  command? : String = "",
  max_checks? : Int = 0,
  sleep_ms? : Int = 30_000,
  stale_after_ms? : UInt64 = 900_000UL,
) -> String {
  let command = @daemon_runtime.daemon_command_or_current(command)
  let run_id = @daemon_runtime.daemon_run_id("supervisor")
  let supervisor_pid = @daemon_runtime.daemon_current_process_pid(snapshot_path)
  if supervisor_pid > 0 {
    @daemon_runtime.mark_daemon_supervisor_started(
      snapshot_path, supervisor_pid, run_id,
    )
  }
  @daemon_runtime.append_daemon_log(
    @daemon_runtime.default_daemon_log_path(snapshot_path~),
    "supervisor loop entered run=\{run_id} pid=\{supervisor_pid}",
  )
  if @daemon_runtime.daemon_supervisor_should_run_inline_worker() {
    @daemon_runtime.append_daemon_log(
      @daemon_runtime.default_daemon_log_path(snapshot_path~),
      "launchd supervisor running worker loop inline",
    )
    return daemon_run_saved_town(
      snapshot_path~,
      max_ticks=0,
      sleep_ms~,
      preserve_supervisor=true,
      inline_under_supervisor=true,
    )
  }
  let mut checks = 0
  let mut latest = ""
  while max_checks <= 0 || checks < max_checks {
    if @daemon_runtime.daemon_stop_requested(snapshot_path) {
      latest = "stop requested"
      break
    }
    let health = @daemon_runtime.inspect_daemon_runtime(
      snapshot_path~,
      stale_after_ms~,
    )
    if !health.worker_alive ||
      health.stale ||
      health.status == "missing" ||
      health.status == "stopped" {
      let worker_run_id = @daemon_runtime.daemon_run_id("worker")
      let pid = @daemon_runtime.spawn_daemon_worker(command, snapshot_path) catch {
        error => {
          @daemon_runtime.append_daemon_log(
            @daemon_runtime.default_daemon_log_path(snapshot_path~),
            "worker spawn failed: \{error}",
          )
          latest = "worker spawn failed: \{error}"
          checks += 1
          @async.sleep(sleep_ms)
          continue
        }
      }
      if pid <= 0 {
        @daemon_runtime.append_daemon_log(
          @daemon_runtime.default_daemon_log_path(snapshot_path~),
          "worker spawn failed: pid unavailable",
        )
        latest = "worker spawn failed: pid unavailable"
        checks += 1
        @async.sleep(sleep_ms)
        continue
      }
      @daemon_runtime.mark_daemon_worker_started(
        snapshot_path, pid, worker_run_id,
      )
      @daemon_runtime.append_daemon_log(
        @daemon_runtime.default_daemon_log_path(snapshot_path~),
        "worker started pid=\{pid} run=\{worker_run_id}",
      )
      latest = "worker started pid=\{pid}"
    } else {
      latest = @daemon_runtime_policy.daemon_runtime_health_summary(health)
    }
    checks += 1
    if max_checks > 0 && checks >= max_checks {
      break
    }
    @async.sleep(sleep_ms)
  }
  if latest == "stop requested" {
    @daemon_runtime.mark_daemon_stopped(
      snapshot_path, "supervisor stopped by request",
    )
    @daemon_runtime.append_daemon_log(
      @daemon_runtime.default_daemon_log_path(snapshot_path~),
      "supervisor stopped",
    )
  }
  "Moontown daemon supervisor completed checks=\{checks}\n\{latest}"
}
