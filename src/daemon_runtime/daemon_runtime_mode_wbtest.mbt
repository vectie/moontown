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
    @daemon_runtime_policy.daemon_runtime_mode("running") is WorkerRuntime,
  )
  assert_true(
    @daemon_runtime_policy.daemon_runtime_mode("ticking") is WorkerRuntime,
  )
  assert_true(
    @daemon_runtime_policy.daemon_runtime_mode("supervising")
    is SupervisorRuntime,
  )
  assert_true(
    @daemon_runtime_policy.daemon_runtime_mode("stopped") is InactiveRuntime,
  )
  assert_true(
    @daemon_runtime_policy.daemon_runtime_mode("missing") is InactiveRuntime,
  )
}
