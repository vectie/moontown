///|
test "wenyu run defaults native and parses explicit route without adding flags to goal" {
  assert_eq(
    @goal_run_arguments.parse(["Build", "Wenyu"]),
    (None, "native", "", "Build Wenyu"),
  )
  assert_eq(
    @goal_run_arguments.parse([
      "--book", "wenyu-code", "--wenyu-execution", "native", "--wenyu-model", "moongate/exact",
      "Build", "district",
    ]),
    (Some("wenyu-code"), "native", "moongate/exact", "Build district"),
  )
  assert_eq(
    @goal_run_arguments.parse(["--wenyu-execution", "acp", "old goal"]),
    (None, "acp", "", "old goal"),
  )
  assert_eq(
    @goal_run_arguments.parse(["--", "--literal"]),
    (None, "native", "", "--literal"),
  )
}

///|
test "wenyu run rejects missing unknown or contradictory flags" {
  for
    args in [
      ["--wenyu-execution"],
      ["--wenyu-execution", "automatic", "goal"],
      ["--unknown", "goal"],
      ["--wenyu-execution", "acp", "--wenyu-model", "moongate/exact", "goal"],
    ] {
    let failed = try {
      ignore(@goal_run_arguments.parse(args))
      false
    } catch {
      _ => true
    }
    assert_true(failed)
  }
}
