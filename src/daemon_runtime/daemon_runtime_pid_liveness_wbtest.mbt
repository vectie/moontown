///|
test "daemon pid liveness requires positive process probe" {
  assert_true(!daemon_pid_effectively_alive(false, 42, true, true))
  assert_true(!daemon_pid_effectively_alive(false, 42, false, true))
  assert_true(!daemon_pid_effectively_alive(false, 0, true, true))
  assert_true(!daemon_pid_effectively_alive(false, 42, true, false))
  assert_true(daemon_pid_effectively_alive(true, 42, false, false))
}
