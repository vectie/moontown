///|
async fn cleanup_stale_daemon_runtime(
  snapshot_path : String,
  health : DaemonRuntimeHealth,
  reason : String,
) -> Unit {
  if health.worker_alive {
    ignore(kill_daemon_pid_force(health.worker_pid))
  }
  if health.supervisor_alive {
    ignore(kill_daemon_pid_force(health.supervisor_pid))
  }
  mark_daemon_stopped(snapshot_path, reason)
  append_daemon_log(
    default_daemon_log_path(snapshot_path~),
    "cleaned stale daemon runtime reason=\{reason} worker_pid=\{health.worker_pid} supervisor_pid=\{health.supervisor_pid}",
  )
}

///|
pub async fn inspect_daemon_runtime(
  snapshot_path? : String = @storage.default_snapshot_path(),
  stale_after_ms? : UInt64 = 900_000UL,
) -> DaemonRuntimeHealth {
  let path = default_daemon_runtime_path(snapshot_path~)
  let stop_requested = daemon_stop_requested(snapshot_path)
  match load_daemon_runtime_state(path) {
    None =>
      {
        status: "missing",
        supervisor_pid: 0,
        worker_pid: 0,
        supervisor_alive: false,
        worker_alive: false,
        heartbeat_age_ms: 0UL,
        stale: false,
        stop_requested,
        tick_success_count: 0,
        tick_failure_count: 0,
        last_error: "",
        log_path: default_daemon_log_path(snapshot_path~),
      }
    Some(state) => {
      let now = @env.now()
      let heartbeat_stale = state.is_stale(now, stale_after_ms)
      let heartbeat_fresh = !heartbeat_stale
      let runtime_active = daemon_runtime_status_active(state.status)
      let supervisor_alive = daemon_pid_effectively_alive(
        daemon_pid_alive(state.supervisor_pid),
        state.supervisor_pid,
        heartbeat_fresh,
        runtime_active,
      )
      let worker_alive = daemon_pid_effectively_alive(
        daemon_pid_alive(state.worker_pid),
        state.worker_pid,
        heartbeat_fresh,
        runtime_active,
      )
      let stale = heartbeat_stale ||
        (
          daemon_runtime_status_requires_worker(state.status) &&
          state.worker_pid > 0 &&
          !worker_alive
        ) ||
        (
          daemon_runtime_status_requires_supervisor(state.status) &&
          state.supervisor_pid > 0 &&
          !supervisor_alive
        )
      {
        status: state.status,
        supervisor_pid: state.supervisor_pid,
        worker_pid: state.worker_pid,
        supervisor_alive,
        worker_alive,
        heartbeat_age_ms: state.heartbeat_age_ms(now),
        stale,
        stop_requested: stop_requested || state.stop_requested,
        tick_success_count: state.tick_success_count,
        tick_failure_count: state.tick_failure_count,
        last_error: state.last_error,
        log_path: state.log_path,
      }
    }
  }
}
