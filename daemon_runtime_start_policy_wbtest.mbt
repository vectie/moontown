///|
test "daemon start requires supervisor for durable worker" {
  let lone_worker = {
    status: "running",
    supervisor_pid: 0,
    worker_pid: 11,
    supervisor_alive: false,
    worker_alive: true,
    heartbeat_age_ms: 50UL,
    stale: false,
    stop_requested: false,
    tick_success_count: 3,
    tick_failure_count: 0,
    last_error: "",
    log_path: ".moontown/daemon.log",
  }
  assert_true(lone_worker.healthy())
  assert_true(!lone_worker.durable_worker_active())
  assert_true(!daemon_runtime_start_already_active(lone_worker))
  assert_eq(daemon_runtime_doctor_action(lone_worker), "daemon start")
  let supervised_worker = {
    ..lone_worker,
    supervisor_pid: 10,
    supervisor_alive: true,
  }
  assert_true(supervised_worker.durable_worker_active())
  assert_true(daemon_runtime_start_already_active(supervised_worker))
  assert_eq(daemon_runtime_doctor_action(supervised_worker), "none")
}
