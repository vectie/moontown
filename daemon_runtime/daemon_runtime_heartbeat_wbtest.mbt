///|
test "daemon runtime stale detection uses real heartbeat age" {
  let state = DaemonRuntimeState::new(
    status="running",
    worker_pid=42,
    last_heartbeat_ms=1_000UL,
  )
  assert_eq(state.heartbeat_age_ms(1_500UL), 500UL)
  assert_true(!state.is_stale(1_500UL, 600UL))
  assert_true(state.is_stale(1_700UL, 600UL))
}
