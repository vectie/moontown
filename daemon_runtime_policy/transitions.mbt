///|
pub fn daemon_runtime_supervisor_started_state(
  previous : DaemonRuntimeState,
  supervisor_pid : Int,
  supervisor_run_id : String,
  now : UInt64,
  log_path : String,
) -> DaemonRuntimeState {
  {
    ..previous,
    status: "supervising",
    supervisor_pid,
    supervisor_run_id,
    started_at_ms: now,
    last_heartbeat_ms: now,
    stop_requested: false,
    last_error: "",
    log_path,
  }
}

///|
pub fn daemon_runtime_should_keep_supervisor(
  supervisor_pid : Int,
  clear_supervisor : Bool,
  supervisor_alive : Bool,
) -> Bool {
  !clear_supervisor || (supervisor_pid > 0 && supervisor_alive)
}

///|
pub fn daemon_runtime_worker_started_state(
  previous : DaemonRuntimeState,
  worker_pid : Int,
  worker_run_id : String,
  keep_supervisor : Bool,
  now : UInt64,
  log_path : String,
) -> DaemonRuntimeState {
  {
    ..previous,
    status: "running",
    supervisor_pid: if keep_supervisor {
      previous.supervisor_pid
    } else {
      0
    },
    supervisor_run_id: if keep_supervisor {
      previous.supervisor_run_id
    } else {
      ""
    },
    worker_pid,
    worker_run_id,
    started_at_ms: if previous.started_at_ms == 0UL {
      now
    } else {
      previous.started_at_ms
    },
    last_heartbeat_ms: now,
    stop_requested: false,
    last_error: "",
    log_path,
  }
}

///|
pub fn daemon_runtime_tick_started_state(
  previous : DaemonRuntimeState,
  worker_run_id : String,
  now : UInt64,
  log_path : String,
) -> DaemonRuntimeState {
  {
    ..previous,
    status: "ticking",
    worker_run_id,
    started_at_ms: if previous.started_at_ms == 0UL {
      now
    } else {
      previous.started_at_ms
    },
    last_heartbeat_ms: now,
    last_tick_started_ms: now,
    stop_requested: false,
    log_path,
  }
}

///|
pub fn daemon_runtime_heartbeat_state(
  previous : DaemonRuntimeState,
  status : String,
  now : UInt64,
  log_path : String,
) -> DaemonRuntimeState {
  { ..previous, status, last_heartbeat_ms: now, log_path }
}

///|
pub fn daemon_runtime_tick_finished_state(
  previous : DaemonRuntimeState,
  ok : Bool,
  summary : String,
  now : UInt64,
  log_path : String,
) -> DaemonRuntimeState {
  if ok {
    {
      ..previous,
      status: "running",
      last_heartbeat_ms: now,
      last_tick_finished_ms: now,
      last_success_ms: now,
      tick_success_count: previous.tick_success_count + 1,
      last_error: "",
      log_path,
    }
  } else {
    {
      ..previous,
      status: "running",
      last_heartbeat_ms: now,
      last_tick_finished_ms: now,
      last_failure_ms: now,
      tick_failure_count: previous.tick_failure_count + 1,
      last_error: summary,
      log_path,
    }
  }
}

///|
pub fn daemon_runtime_stopped_state(
  previous : DaemonRuntimeState,
  reason : String,
  now : UInt64,
  log_path : String,
) -> DaemonRuntimeState {
  {
    ..previous,
    status: "stopped",
    last_heartbeat_ms: now,
    stop_requested: false,
    last_error: reason,
    log_path,
  }
}

///|
pub fn daemon_runtime_worker_reload_requested_state(
  previous : DaemonRuntimeState,
  reason : String,
  now : UInt64,
  log_path : String,
) -> DaemonRuntimeState {
  {
    ..previous,
    status: if previous.supervisor_pid > 0 {
      "supervising"
    } else {
      "stopped"
    },
    worker_pid: 0,
    worker_run_id: "",
    last_heartbeat_ms: now,
    stop_requested: false,
    last_error: reason,
    log_path,
  }
}
