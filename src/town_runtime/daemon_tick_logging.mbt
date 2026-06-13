///|
async fn append_daemon_context_phase_log(
  context : DaemonTickContext,
  phase : String,
) -> Unit {
  @daemon_runtime.append_daemon_tick_phase_log(
    context.paths.log_path,
    phase,
    context.next_tick_sequence,
  )
}
