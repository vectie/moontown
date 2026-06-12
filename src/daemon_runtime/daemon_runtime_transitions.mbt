///|
pub async fn mark_daemon_supervisor_started(
  snapshot_path : String,
  supervisor_pid : Int,
  supervisor_run_id : String,
) -> Unit {
  let ctx = daemon_runtime_transition_context(snapshot_path)
  save_daemon_runtime_state(
    ctx.runtime_path,
    @daemon_runtime_policy.daemon_runtime_supervisor_started_state(
      ctx.previous,
      supervisor_pid,
      supervisor_run_id,
      ctx.now,
      ctx.log_path,
    ),
  )
  write_daemon_pid_file(
    default_daemon_supervisor_pid_path(snapshot_path~),
    supervisor_pid,
  )
}

///|
pub async fn mark_daemon_worker_started(
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
  save_daemon_runtime_state(
    ctx.runtime_path,
    @daemon_runtime_policy.daemon_runtime_worker_started_state(
      ctx.previous,
      worker_pid,
      worker_run_id,
      keep_supervisor,
      ctx.now,
      ctx.log_path,
    ),
  )
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
  @daemon_runtime_policy.daemon_runtime_should_keep_supervisor(
    supervisor_pid,
    clear_supervisor,
    supervisor_pid > 0 && daemon_pid_alive(supervisor_pid),
  )
}

///|
pub async fn mark_daemon_tick_started(
  snapshot_path : String,
  worker_run_id : String,
) -> Unit {
  let ctx = daemon_runtime_transition_context(snapshot_path)
  save_daemon_runtime_state(
    ctx.runtime_path,
    @daemon_runtime_policy.daemon_runtime_tick_started_state(
      ctx.previous,
      worker_run_id,
      ctx.now,
      ctx.log_path,
    ),
  )
}

///|
pub async fn touch_daemon_heartbeat(
  snapshot_path : String,
  status? : String = "ticking",
) -> Unit {
  let ctx = daemon_runtime_transition_context(snapshot_path)
  save_daemon_runtime_state(
    ctx.runtime_path,
    @daemon_runtime_policy.daemon_runtime_heartbeat_state(
      ctx.previous,
      status,
      ctx.now,
      ctx.log_path,
    ),
  )
}

///|
pub async fn mark_daemon_tick_finished(
  snapshot_path : String,
  ok : Bool,
  summary : String,
) -> Unit {
  let ctx = daemon_runtime_transition_context(snapshot_path)
  save_daemon_runtime_state(
    ctx.runtime_path,
    @daemon_runtime_policy.daemon_runtime_tick_finished_state(
      ctx.previous,
      ok,
      summary,
      ctx.now,
      ctx.log_path,
    ),
  )
}

///|
pub async fn mark_daemon_stopped(
  snapshot_path : String,
  reason : String,
) -> Unit {
  let ctx = daemon_runtime_transition_context(snapshot_path)
  save_daemon_runtime_state(
    ctx.runtime_path,
    @daemon_runtime_policy.daemon_runtime_stopped_state(
      ctx.previous,
      reason,
      ctx.now,
      ctx.log_path,
    ),
  )
  remove_file_if_exists(default_daemon_pid_path(snapshot_path~))
  remove_file_if_exists(default_daemon_supervisor_pid_path(snapshot_path~))
  clear_daemon_stop_request(snapshot_path)
}

///|
pub async fn mark_daemon_worker_reload_requested(
  snapshot_path : String,
  reason : String,
) -> Unit {
  let ctx = daemon_runtime_transition_context(snapshot_path)
  save_daemon_runtime_state(
    ctx.runtime_path,
    @daemon_runtime_policy.daemon_runtime_worker_reload_requested_state(
      ctx.previous,
      reason,
      ctx.now,
      ctx.log_path,
    ),
  )
  remove_file_if_exists(default_daemon_pid_path(snapshot_path~))
  clear_daemon_restart_request(snapshot_path)
}
