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
test "daemon pid liveness trusts fresh heartbeat when process probe is blocked" {
  assert_true(daemon_pid_effectively_alive(false, 42, true, true))
  assert_true(!daemon_pid_effectively_alive(false, 42, false, true))
  assert_true(!daemon_pid_effectively_alive(false, 0, true, true))
  assert_true(!daemon_pid_effectively_alive(false, 42, true, false))
  assert_true(daemon_pid_effectively_alive(true, 42, false, false))
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

///|
test "launchd supervisor service runs worker inline" {
  assert_true(
    daemon_supervisor_should_run_inline_for_service_name(
      "com.vectie.moontown.daemon",
    ),
  )
  assert_true(
    !daemon_supervisor_should_run_inline_for_service_name(
      "com.apple.some-other-service",
    ),
  )
}

///|
async test "manual worker only clears missing supervisor when requested" {
  assert_true(daemon_worker_should_keep_supervisor(0, false))
  assert_true(!daemon_worker_should_keep_supervisor(0, true))
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
test "daemon shell quote escapes single quotes" {
  assert_eq(daemon_shell_quote("plain"), "'plain'")
  assert_eq(daemon_shell_quote("two words"), "'two words'")
  assert_eq(daemon_shell_quote("it's"), "'it'\\''s'")
}

///|
test "daemon detached shell line launches through nohup and captures pid" {
  let line = daemon_detached_shell_line(
    "/Users/kq/.moon/bin/moon",
    ["daemon", "supervise", "--worker"],
    "/tmp/moontown cwd",
    "/tmp/moontown.log",
    "/tmp/moontown.pid",
  )
  assert_true(line.contains("cd '/tmp/moontown cwd'"))
  assert_true(line.contains("&& { nohup '/Users/kq/.moon/bin/moon'"))
  assert_true(line.contains("'run' 'cmd/main' '--'"))
  assert_true(line.contains("'daemon' 'supervise' '--worker'"))
  assert_true(line.contains("echo $! > '/tmp/moontown.pid'"))
}

///|
test "daemon launchd install line passes moon command explicitly" {
  let line = daemon_launchd_install_shell_line("/Users/kq/.moon/bin/moon")
  assert_true(line.contains("MOON_BIN='/Users/kq/.moon/bin/moon'"))
  assert_true(line.contains("sh ./scripts/install-launchd-daemon.sh"))
}

///|
test "daemon launchd stop line uses uninstall script" {
  let line = daemon_launchd_stop_shell_line()
  assert_true(line == "sh ./scripts/uninstall-launchd-daemon.sh")
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
  assert_eq(
    default_daemon_restart_path(snapshot_path=".moontown/town.json"),
    ".moontown/daemon.restart",
  )
}

///|
async test "daemon restart request writes and clears reload marker" {
  let snapshot_path = "/tmp/moontown-daemon-restart-wbtest/town.json"
  let restart_path = default_daemon_restart_path(snapshot_path~)
  remove_file_if_exists(restart_path)
  assert_true(!daemon_restart_requested(snapshot_path))
  let message = write_daemon_restart_request(
    snapshot_path~,
    reason="unit test reload",
  )
  assert_true(message.contains("Moontown daemon restart requested"))
  assert_true(message.contains("unit test reload"))
  assert_true(daemon_restart_requested(snapshot_path))
  clear_daemon_restart_request(snapshot_path)
  assert_true(!daemon_restart_requested(snapshot_path))
}

///|
async test "daemon worker reload keeps supervisor state" {
  let snapshot_path = "/tmp/moontown-daemon-reload-state-wbtest/town.json"
  let runtime_path = default_daemon_runtime_path(snapshot_path~)
  save_daemon_runtime_state(
    runtime_path,
    DaemonRuntimeState::new(
      status="running",
      supervisor_pid=101,
      worker_pid=202,
      supervisor_run_id="supervisor-test",
      worker_run_id="worker-test",
      log_path=default_daemon_log_path(snapshot_path~),
    ),
  )
  write_daemon_pid_file(default_daemon_pid_path(snapshot_path~), 202)
  ignore(write_daemon_restart_request(snapshot_path~, reason="unit test"))
  mark_daemon_worker_reload_requested(snapshot_path, "unit test reload")
  let state = load_daemon_runtime_state(runtime_path).unwrap()
  assert_eq(state.status, "supervising")
  assert_eq(state.supervisor_pid, 101)
  assert_eq(state.worker_pid, 0)
  assert_eq(state.worker_run_id, "")
  assert_true(!@fs.exists(default_daemon_pid_path(snapshot_path~)))
  assert_true(!daemon_restart_requested(snapshot_path))
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

///|
test "daemon pid parser rejects noisy input" {
  assert_eq(daemon_parse_positive_int("12345"), 12345)
  assert_eq(daemon_parse_positive_int(" 42\n"), 42)
  assert_eq(daemon_parse_positive_int(""), 0)
  assert_eq(daemon_parse_positive_int("42x"), 0)
}
