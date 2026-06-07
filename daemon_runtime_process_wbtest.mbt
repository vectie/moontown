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
  let windows_args = daemon_process_args("C:/Moon/bin/moon.exe", [
    "daemon", "run", "--worker",
  ]).join(" ")
  assert_true(windows_args == "run cmd/main -- daemon run --worker")
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
