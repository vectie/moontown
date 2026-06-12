///|
test "daemon runtime status helpers define active worker and supervisor modes" {
  assert_true(@daemon_runtime_policy.daemon_runtime_status_active("running"))
  assert_true(@daemon_runtime_policy.daemon_runtime_status_active("ticking"))
  assert_true(
    @daemon_runtime_policy.daemon_runtime_status_active("supervising"),
  )
  assert_true(!@daemon_runtime_policy.daemon_runtime_status_active("stopped"))
  assert_true(
    @daemon_runtime_policy.daemon_runtime_status_requires_worker("running"),
  )
  assert_true(
    @daemon_runtime_policy.daemon_runtime_status_requires_worker("ticking"),
  )
  assert_true(
    !@daemon_runtime_policy.daemon_runtime_status_requires_worker("supervising"),
  )
  assert_true(
    @daemon_runtime_policy.daemon_runtime_status_requires_supervisor(
      "supervising",
    ),
  )
  assert_true(
    !@daemon_runtime_policy.daemon_runtime_status_requires_supervisor("running"),
  )
}

///|
test "daemon runtime mode centralizes status classification" {
  assert_true(
    @daemon_runtime_policy.daemon_runtime_mode("running")
    is @daemon_runtime_policy.DaemonRuntimeMode::WorkerRuntime,
  )
  assert_true(
    @daemon_runtime_policy.daemon_runtime_mode("ticking")
    is @daemon_runtime_policy.DaemonRuntimeMode::WorkerRuntime,
  )
  assert_true(
    @daemon_runtime_policy.daemon_runtime_mode("supervising")
    is @daemon_runtime_policy.DaemonRuntimeMode::SupervisorRuntime,
  )
  assert_true(
    @daemon_runtime_policy.daemon_runtime_mode("stopped")
    is @daemon_runtime_policy.DaemonRuntimeMode::InactiveRuntime,
  )
  assert_true(
    @daemon_runtime_policy.daemon_runtime_mode("missing")
    is @daemon_runtime_policy.DaemonRuntimeMode::InactiveRuntime,
  )
}
