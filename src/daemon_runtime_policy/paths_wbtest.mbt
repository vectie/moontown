///|
test "daemon runtime policy derives paths from snapshot directory" {
  assert_eq(
    daemon_runtime_path_for_snapshot("/tmp/moontown/town.json"),
    "/tmp/moontown/daemon-runtime.json",
  )
  assert_eq(
    daemon_runtime_path_for_snapshot("town.json"),
    ".moonsuite/products/moontown/daemon-runtime.json",
  )
  assert_eq(
    daemon_pid_path_for_snapshot(".moonsuite/products/moontown/town.json"),
    ".moonsuite/products/moontown/daemon.pid",
  )
  assert_eq(
    daemon_supervisor_pid_path_for_snapshot(
      ".moonsuite/products/moontown/town.json",
    ),
    ".moonsuite/products/moontown/daemon-supervisor.pid",
  )
  assert_eq(
    daemon_restart_path_for_snapshot(".moonsuite/products/moontown/town.json"),
    ".moonsuite/products/moontown/daemon.restart",
  )
}

///|
test "daemon runtime policy derives standing-goal path without storage coupling" {
  assert_eq(
    daemon_standing_goal_path_for_snapshot(
      ".moonsuite/products/moontown/town.json", ".moonsuite/products/moontown/standing-goals.json",
    ),
    ".moonsuite/products/moontown/standing-goals.json",
  )
  assert_eq(
    daemon_standing_goal_path_for_snapshot(
      "/tmp/moontown/town.json", ".moonsuite/products/moontown/standing-goals.json",
    ),
    "/tmp/moontown/standing-goals.json",
  )
}
