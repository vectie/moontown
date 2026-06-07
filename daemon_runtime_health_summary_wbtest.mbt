///|
test "daemon runtime health summary marks healthy worker" {
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
    tick_failure_count: 0,
    last_error: "",
    log_path: ".moontown/daemon.log",
  }
  assert_true(health.healthy())
  let summary = daemon_runtime_health_summary(health)
  assert_true(summary.contains("runtime=healthy"))
  assert_true(summary.contains("worker_pid=11"))
  assert_true(summary.contains("successes=3"))
}

///|
test "daemon runtime health summary marks active supervisor" {
  let health = {
    status: "supervising",
    supervisor_pid: 10,
    worker_pid: 0,
    supervisor_alive: true,
    worker_alive: false,
    heartbeat_age_ms: 50UL,
    stale: false,
    stop_requested: false,
    tick_success_count: 0,
    tick_failure_count: 0,
    last_error: "",
    log_path: ".moontown/daemon.log",
  }
  assert_true(!health.healthy())
  assert_true(health.supervisor_active())
  let summary = daemon_runtime_health_summary(health)
  assert_true(summary.contains("runtime=supervising"))
  assert_true(summary.contains("supervisor_pid=10"))
}

///|
test "daemon runtime health summary marks stale worker" {
  let health = {
    status: "ticking",
    supervisor_pid: 10,
    worker_pid: 11,
    supervisor_alive: true,
    worker_alive: false,
    heartbeat_age_ms: 901_000UL,
    stale: true,
    stop_requested: false,
    tick_success_count: 3,
    tick_failure_count: 1,
    last_error: "timeout",
    log_path: ".moontown/daemon.log",
  }
  assert_true(!health.healthy())
  let summary = daemon_runtime_health_summary(health)
  assert_true(summary.contains("runtime=stale"))
  assert_true(summary.contains("failures=1"))
}

///|
test "daemon runtime health label precedence is explicit" {
  let running = {
    status: "running",
    supervisor_pid: 10,
    worker_pid: 11,
    supervisor_alive: true,
    worker_alive: true,
    heartbeat_age_ms: 50UL,
    stale: false,
    stop_requested: false,
    tick_success_count: 3,
    tick_failure_count: 0,
    last_error: "",
    log_path: ".moontown/daemon.log",
  }
  assert_eq(daemon_runtime_health_label(running), "healthy")
  assert_eq(
    daemon_runtime_health_label({ ..running, stop_requested: true }),
    "stopping",
  )
  assert_eq(daemon_runtime_health_label({ ..running, stale: true }), "stale")
  assert_eq(
    daemon_runtime_health_label({
      ..running,
      status: "missing",
      worker_alive: false,
    }),
    "missing",
  )
}

///|
test "daemon runtime health summary fields keep stable operator order" {
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
  let fields = daemon_runtime_health_summary_fields("healthy", health)
  assert_eq(fields[0], "runtime=healthy")
  assert_eq(fields[1], "status=running")
  assert_eq(fields[2], "supervisor_pid=10")
  assert_eq(fields[5], "worker_alive=true")
  assert_eq(fields[9], "failures=1")
  assert_eq(fields[10], "log=.moontown/daemon.log")
}
