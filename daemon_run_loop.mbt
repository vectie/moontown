///|
pub async fn daemon_run_saved_town(
  snapshot_path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  max_ticks? : Int = 0,
  sleep_ms? : Int = 30_000,
  preserve_supervisor? : Bool = false,
  inline_under_supervisor? : Bool = false,
) -> String {
  let log_path = @daemon_runtime.default_daemon_log_path(snapshot_path~)
  let observed_worker_pid = @daemon_runtime.daemon_current_process_pid(
    snapshot_path,
  )
  let prior_health = @daemon_runtime.inspect_daemon_runtime(snapshot_path~)
  let prior_state = @daemon_runtime.load_daemon_runtime_state(
    @daemon_runtime.default_daemon_runtime_path(snapshot_path~),
  )
  let worker_pid = if inline_under_supervisor &&
    prior_health.supervisor_pid > 0 &&
    prior_health.supervisor_alive {
    prior_health.supervisor_pid
  } else if prior_health.worker_pid > 0 &&
    prior_health.worker_alive &&
    !prior_health.stale {
    prior_health.worker_pid
  } else {
    observed_worker_pid
  }
  let worker_run_id = match prior_state {
    Some(state) if worker_pid == state.worker_pid &&
      !state.worker_run_id.is_empty() => state.worker_run_id
    _ => @daemon_runtime.daemon_run_id("worker")
  }
  if inline_under_supervisor &&
    worker_pid > 0 &&
    prior_health.supervisor_pid == 0 {
    let supervisor_run_id = match prior_state {
      Some(state) if !state.supervisor_run_id.is_empty() =>
        state.supervisor_run_id
      _ => @daemon_runtime.daemon_run_id("supervisor")
    }
    @daemon_runtime.mark_daemon_supervisor_started(
      snapshot_path, worker_pid, supervisor_run_id,
    )
  }
  if worker_pid > 0 {
    @daemon_runtime.mark_daemon_worker_started(
      snapshot_path,
      worker_pid,
      worker_run_id,
      clear_supervisor=!preserve_supervisor,
    )
  }
  @daemon_runtime.append_daemon_log(
    log_path,
    "worker loop entered run=\{worker_run_id} pid=\{worker_pid} max_ticks=\{max_ticks} sleep_ms=\{sleep_ms}",
  )
  let mut ticks = 0
  let mut latest = ""
  while max_ticks <= 0 || ticks < max_ticks {
    if @daemon_runtime.daemon_stop_requested(snapshot_path) {
      latest = "daemon stop requested"
      break
    }
    if @daemon_runtime.daemon_restart_requested(snapshot_path) {
      latest = "daemon restart requested"
      break
    }
    @daemon_runtime.mark_daemon_tick_started(snapshot_path, worker_run_id)
    let (ok, tick_summary) = run_daemon_tick_with_heartbeat(
      snapshot_path, book_catalog_path,
    )
    latest = tick_summary
    @daemon_runtime.mark_daemon_tick_finished(snapshot_path, ok, latest)
    @daemon_runtime.append_daemon_log(
      log_path,
      if ok {
        "tick ok index=\{ticks + 1}"
      } else {
        "tick failed index=\{ticks + 1}: \{latest}"
      },
    )
    ticks += 1
    if max_ticks > 0 && ticks >= max_ticks {
      break
    }
    @async.sleep(sleep_ms)
  }
  if latest == "daemon stop requested" {
    @daemon_runtime.mark_daemon_stopped(
      snapshot_path, "worker stopped by request",
    )
    @daemon_runtime.append_daemon_log(
      log_path,
      "worker stopped run=\{worker_run_id}",
    )
  } else if latest == "daemon restart requested" {
    @daemon_runtime.mark_daemon_worker_reload_requested(
      snapshot_path, "worker reload requested by restart marker",
    )
    @daemon_runtime.append_daemon_log(
      log_path,
      "worker reload requested run=\{worker_run_id}",
    )
  } else if max_ticks > 0 {
    @daemon_runtime.mark_daemon_stopped(
      snapshot_path, "worker completed bounded run",
    )
    @daemon_runtime.append_daemon_log(
      log_path,
      "worker completed bounded run=\{worker_run_id}",
    )
  }
  "Moontown daemon run completed ticks=\{ticks}\n\{latest}"
}

///|
async fn run_daemon_tick_with_heartbeat(
  snapshot_path : String,
  book_catalog_path : String,
) -> (Bool, String) {
  @async.with_task_group(group => {
    let mut done = false
    let heartbeat = group.spawn(() => {
      while !done {
        @async.sleep(10_000)
        if !done {
          @daemon_runtime.touch_daemon_heartbeat(
            snapshot_path,
            status="ticking",
          )
        }
      }
    })
    let mut ok = true
    let summary = daemon_tick_saved_town(
      snapshot_path~,
      book_catalog_path~,
      respect_runtime_lock=false,
    ) catch {
      error => {
        ok = false
        "daemon tick failed: \{error}"
      }
    }
    done = true
    heartbeat.wait()
    (ok, summary)
  })
}
