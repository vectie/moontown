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
test "daemon runtime paths follow snapshot directory" {
  assert_eq(
    default_daemon_runtime_path(snapshot_path="/tmp/moontown/town.json"),
    "/tmp/moontown/daemon-runtime.json",
  )
  assert_eq(
    default_daemon_pid_path(snapshot_path=".moontown/town.json"),
    ".moontown/daemon.pid",
  )
  assert_eq(
    default_daemon_supervisor_pid_path(snapshot_path=".moontown/town.json"),
    ".moontown/daemon-supervisor.pid",
  )
}

///|
test "daemon process args launch through moon runner" {
  let worker_args = daemon_process_args("moon", ["daemon", "run", "--worker"]).join(
    " ",
  )
  assert_true(worker_args == "run cmd/main -- daemon run --worker")
  let supervisor_args = daemon_process_args("/Users/kq/.moon/bin/moon", [
    "daemon", "supervise", "--worker",
  ]).join(" ")
  assert_true(supervisor_args == "run cmd/main -- daemon supervise --worker")
}

///|
test "daemon process args keep direct executable clean" {
  let args = daemon_process_args("/tmp/moontown-main", [
    "daemon", "run", "--worker",
  ]).join(" ")
  assert_true(args == "daemon run --worker")
}
