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
