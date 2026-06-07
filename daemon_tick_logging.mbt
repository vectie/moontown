///|
async fn append_daemon_context_phase_log(
  context : DaemonTickContext,
  phase : String,
) -> Unit {
  append_daemon_tick_phase_log(
    context.paths.log_path,
    phase,
    context.next_tick_sequence,
  )
}

///|
fn daemon_tick_log_line(phase : String, sequence : Int) -> String {
  "tick phase=\{phase} sequence=\{sequence}"
}

///|
async fn append_daemon_tick_phase_log(
  log_path : String,
  phase : String,
  sequence : Int,
) -> Unit {
  append_daemon_log(log_path, daemon_tick_log_line(phase, sequence))
}

///|
async fn daemon_tick_runtime_lock_active(snapshot_path : String) -> Bool {
  let runtime = inspect_daemon_runtime(snapshot_path~)
  runtime.status == "ticking" &&
  runtime.worker_alive &&
  !runtime.stale &&
  runtime.heartbeat_age_ms < 120_000UL
}
