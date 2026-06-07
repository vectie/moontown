///|
async fn mark_daemon_supervisor_started(
  snapshot_path : String,
  supervisor_pid : Int,
  supervisor_run_id : String,
) -> Unit {
  let ctx = daemon_runtime_transition_context(snapshot_path)
  save_daemon_runtime_state(ctx.runtime_path, {
    ..ctx.previous,
    status: "supervising",
    supervisor_pid,
    supervisor_run_id,
    started_at_ms: ctx.now,
    last_heartbeat_ms: ctx.now,
    stop_requested: false,
    last_error: "",
    log_path: ctx.log_path,
  })
  write_daemon_pid_file(
    default_daemon_supervisor_pid_path(snapshot_path~),
    supervisor_pid,
  )
}

///|
async fn mark_daemon_worker_started(
  snapshot_path : String,
  worker_pid : Int,
  worker_run_id : String,
  clear_supervisor? : Bool = false,
) -> Unit {
  let ctx = daemon_runtime_transition_context(snapshot_path)
  let keep_supervisor = daemon_worker_should_keep_supervisor(
    ctx.previous.supervisor_pid,
    clear_supervisor,
  )
  save_daemon_runtime_state(ctx.runtime_path, {
    ..ctx.previous,
    status: "running",
    supervisor_pid: if keep_supervisor {
      ctx.previous.supervisor_pid
    } else {
      0
    },
    supervisor_run_id: if keep_supervisor {
      ctx.previous.supervisor_run_id
    } else {
      ""
    },
    worker_pid,
    worker_run_id,
    started_at_ms: if ctx.previous.started_at_ms == 0UL {
      ctx.now
    } else {
      ctx.previous.started_at_ms
    },
    last_heartbeat_ms: ctx.now,
    stop_requested: false,
    last_error: "",
    log_path: ctx.log_path,
  })
  write_daemon_pid_file(default_daemon_pid_path(snapshot_path~), worker_pid)
  if !keep_supervisor {
    remove_file_if_exists(default_daemon_supervisor_pid_path(snapshot_path~))
  }
}

///|
async fn daemon_worker_should_keep_supervisor(
  supervisor_pid : Int,
  clear_supervisor : Bool,
) -> Bool {
  !clear_supervisor || (supervisor_pid > 0 && daemon_pid_alive(supervisor_pid))
}

///|
async fn mark_daemon_tick_started(
  snapshot_path : String,
  worker_run_id : String,
) -> Unit {
  let ctx = daemon_runtime_transition_context(snapshot_path)
  save_daemon_runtime_state(ctx.runtime_path, {
    ..ctx.previous,
    status: "ticking",
    worker_run_id,
    started_at_ms: if ctx.previous.started_at_ms == 0UL {
      ctx.now
    } else {
      ctx.previous.started_at_ms
    },
    last_heartbeat_ms: ctx.now,
    last_tick_started_ms: ctx.now,
    stop_requested: false,
    log_path: ctx.log_path,
  })
}

///|
async fn touch_daemon_heartbeat(
  snapshot_path : String,
  status? : String = "ticking",
) -> Unit {
  let ctx = daemon_runtime_transition_context(snapshot_path)
  save_daemon_runtime_state(ctx.runtime_path, {
    ..ctx.previous,
    status,
    last_heartbeat_ms: ctx.now,
    log_path: ctx.log_path,
  })
}

///|
async fn mark_daemon_tick_finished(
  snapshot_path : String,
  ok : Bool,
  summary : String,
) -> Unit {
  let ctx = daemon_runtime_transition_context(snapshot_path)
  let next = if ok {
    {
      ..ctx.previous,
      status: "running",
      last_heartbeat_ms: ctx.now,
      last_tick_finished_ms: ctx.now,
      last_success_ms: ctx.now,
      tick_success_count: ctx.previous.tick_success_count + 1,
      last_error: "",
      log_path: ctx.log_path,
    }
  } else {
    {
      ..ctx.previous,
      status: "running",
      last_heartbeat_ms: ctx.now,
      last_tick_finished_ms: ctx.now,
      last_failure_ms: ctx.now,
      tick_failure_count: ctx.previous.tick_failure_count + 1,
      last_error: summary,
      log_path: ctx.log_path,
    }
  }
  save_daemon_runtime_state(ctx.runtime_path, next)
}

///|
async fn mark_daemon_stopped(snapshot_path : String, reason : String) -> Unit {
  let ctx = daemon_runtime_transition_context(snapshot_path)
  save_daemon_runtime_state(ctx.runtime_path, {
    ..ctx.previous,
    status: "stopped",
    last_heartbeat_ms: ctx.now,
    stop_requested: false,
    last_error: reason,
    log_path: ctx.log_path,
  })
  remove_file_if_exists(default_daemon_pid_path(snapshot_path~))
  remove_file_if_exists(default_daemon_supervisor_pid_path(snapshot_path~))
  clear_daemon_stop_request(snapshot_path)
}

///|
async fn mark_daemon_worker_reload_requested(
  snapshot_path : String,
  reason : String,
) -> Unit {
  let ctx = daemon_runtime_transition_context(snapshot_path)
  save_daemon_runtime_state(ctx.runtime_path, {
    ..ctx.previous,
    status: if ctx.previous.supervisor_pid > 0 {
      "supervising"
    } else {
      "stopped"
    },
    worker_pid: 0,
    worker_run_id: "",
    last_heartbeat_ms: ctx.now,
    stop_requested: false,
    last_error: reason,
    log_path: ctx.log_path,
  })
  remove_file_if_exists(default_daemon_pid_path(snapshot_path~))
  clear_daemon_restart_request(snapshot_path)
}
