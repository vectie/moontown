///|
priv struct DaemonRuntimeTransitionContext {
  runtime_path : String
  log_path : String
  now : UInt64
  previous : DaemonRuntimeState
}

///|
async fn daemon_runtime_transition_context(
  snapshot_path : String,
) -> DaemonRuntimeTransitionContext {
  let runtime_path = default_daemon_runtime_path(snapshot_path~)
  let log_path = default_daemon_log_path(snapshot_path~)
  {
    runtime_path,
    log_path,
    now: @env.now(),
    previous: load_daemon_runtime_state(runtime_path).unwrap_or(
      DaemonRuntimeState::new(log_path~),
    ),
  }
}
