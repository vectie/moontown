///|
test "daemon runtime paths follow snapshot directory" {
  assert_eq(
    default_daemon_runtime_path(snapshot_path="/tmp/moontown/town.json"),
    "/tmp/moontown/daemon-runtime.json",
  )
  assert_eq(
    default_daemon_pid_path(
      snapshot_path=".moonsuite/products/moontown/town.json",
    ),
    ".moonsuite/products/moontown/daemon.pid",
  )
  assert_eq(
    default_daemon_supervisor_pid_path(
      snapshot_path=".moonsuite/products/moontown/town.json",
    ),
    ".moonsuite/products/moontown/daemon-supervisor.pid",
  )
  assert_eq(
    default_daemon_restart_path(
      snapshot_path=".moonsuite/products/moontown/town.json",
    ),
    ".moonsuite/products/moontown/daemon.restart",
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
