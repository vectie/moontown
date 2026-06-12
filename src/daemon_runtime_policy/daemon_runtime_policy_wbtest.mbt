///|
test "daemon runtime policy classifies active worker and supervisor modes" {
  assert_true(daemon_runtime_status_active("running"))
  assert_true(daemon_runtime_status_active("ticking"))
  assert_true(daemon_runtime_status_active("supervising"))
  assert_true(!daemon_runtime_status_active("stopped"))
  assert_true(daemon_runtime_mode("running") is WorkerRuntime)
  assert_true(daemon_runtime_mode("supervising") is SupervisorRuntime)
  assert_true(daemon_runtime_mode("missing") is InactiveRuntime)
}

///|
test "daemon runtime policy detects heartbeat staleness" {
  let state = DaemonRuntimeState::new(
    status="running",
    worker_pid=42,
    last_heartbeat_ms=1_000UL,
  )
  assert_eq(state.heartbeat_age_ms(1_500UL), 500UL)
  assert_true(!state.is_stale(1_500UL, 600UL))
  assert_true(state.is_stale(1_700UL, 600UL))
}

///|
test "daemon runtime policy requires supervisor for durable worker" {
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
  assert_true(
    daemon_runtime_start_already_active({
      ..lone_worker,
      supervisor_pid: 10,
      supervisor_alive: true,
    }),
  )
}

///|
test "daemon runtime policy renders health summary in stable order" {
  let health = {
    status: "running",
    supervisor_pid: 10,
    worker_pid: 11,
    supervisor_alive: true,
    worker_alive: true,
    heartbeat_age_ms: 50UL,
    stale: false,
    stop_requested: false,
    tick_success_count: 3,
    tick_failure_count: 1,
    last_error: "",
    log_path: ".moontown/daemon.log",
  }
  let summary = daemon_runtime_health_summary(health)
  assert_true(summary.contains("runtime=healthy"))
  let fields = daemon_runtime_health_summary_fields("healthy", health)
  assert_eq(fields[0], "runtime=healthy")
  assert_eq(fields[1], "status=running")
  assert_eq(fields[2], "supervisor_pid=10")
  assert_eq(fields[5], "worker_alive=true")
  assert_eq(fields[9], "failures=1")
  assert_eq(fields[10], "log=.moontown/daemon.log")
}

///|
test "daemon runtime policy builds supervisor and worker started states" {
  let previous = DaemonRuntimeState::new(
    supervisor_pid=9,
    supervisor_run_id="supervisor-old",
    started_at_ms=100UL,
    log_path="old.log",
  )
  let supervisor = daemon_runtime_supervisor_started_state(
    previous, 10, "supervisor-new", 200UL, "daemon.log",
  )
  assert_eq(supervisor.status, "supervising")
  assert_eq(supervisor.supervisor_pid, 10)
  assert_eq(supervisor.supervisor_run_id, "supervisor-new")
  assert_eq(supervisor.started_at_ms, 200UL)
  assert_eq(supervisor.last_heartbeat_ms, 200UL)
  assert_true(!supervisor.stop_requested)

  let worker = daemon_runtime_worker_started_state(
    supervisor, 20, "worker-new", true, 300UL, "daemon.log",
  )
  assert_eq(worker.status, "running")
  assert_eq(worker.supervisor_pid, 10)
  assert_eq(worker.supervisor_run_id, "supervisor-new")
  assert_eq(worker.worker_pid, 20)
  assert_eq(worker.worker_run_id, "worker-new")
  assert_eq(worker.started_at_ms, 200UL)
  assert_eq(worker.last_heartbeat_ms, 300UL)
}

///|
test "daemon runtime policy clears supervisor and records tick outcomes" {
  let previous = DaemonRuntimeState::new(
    supervisor_pid=10,
    supervisor_run_id="supervisor",
    worker_pid=20,
    worker_run_id="worker",
    tick_success_count=2,
    tick_failure_count=1,
  )
  assert_true(daemon_runtime_should_keep_supervisor(10, false, false))
  assert_true(daemon_runtime_should_keep_supervisor(10, true, true))
  assert_true(!daemon_runtime_should_keep_supervisor(10, true, false))

  let worker = daemon_runtime_worker_started_state(
    previous, 21, "worker-manual", false, 400UL, "daemon.log",
  )
  assert_eq(worker.supervisor_pid, 0)
  assert_eq(worker.supervisor_run_id, "")

  let tick = daemon_runtime_tick_started_state(
    worker, "worker-manual", 500UL, "daemon.log",
  )
  assert_eq(tick.status, "ticking")
  assert_eq(tick.last_tick_started_ms, 500UL)

  let success = daemon_runtime_tick_finished_state(
    tick, true, "", 600UL, "daemon.log",
  )
  assert_eq(success.status, "running")
  assert_eq(success.tick_success_count, 3)
  assert_eq(success.tick_failure_count, 1)
  assert_eq(success.last_success_ms, 600UL)
  assert_eq(success.last_error, "")

  let failure = daemon_runtime_tick_finished_state(
    success, false, "boom", 700UL, "daemon.log",
  )
  assert_eq(failure.tick_success_count, 3)
  assert_eq(failure.tick_failure_count, 2)
  assert_eq(failure.last_failure_ms, 700UL)
  assert_eq(failure.last_error, "boom")
}

///|
test "daemon runtime policy builds heartbeat stop and reload states" {
  let previous = DaemonRuntimeState::new(
    status="running",
    supervisor_pid=10,
    worker_pid=20,
    worker_run_id="worker",
    stop_requested=true,
  )
  let heartbeat = daemon_runtime_heartbeat_state(
    previous, "ticking", 800UL, "daemon.log",
  )
  assert_eq(heartbeat.status, "ticking")
  assert_eq(heartbeat.last_heartbeat_ms, 800UL)

  let reload = daemon_runtime_worker_reload_requested_state(
    heartbeat, "reload", 900UL, "daemon.log",
  )
  assert_eq(reload.status, "supervising")
  assert_eq(reload.worker_pid, 0)
  assert_eq(reload.worker_run_id, "")
  assert_true(!reload.stop_requested)
  assert_eq(reload.last_error, "reload")

  let stopped = daemon_runtime_stopped_state(
    reload, "stop", 1_000UL, "daemon.log",
  )
  assert_eq(stopped.status, "stopped")
  assert_eq(stopped.last_heartbeat_ms, 1_000UL)
  assert_true(!stopped.stop_requested)
  assert_eq(stopped.last_error, "stop")
}
