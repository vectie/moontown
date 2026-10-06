///|
test "Wenyu no change option is explicit native only and preserves legacy parser" {
  assert_eq(
    parse_options(["Build", "Wenyu"]),
    (None, "native", "", "Build Wenyu", false),
  )
  assert_eq(
    parse_options([
      "--wenyu-allow-no-change", "--book", "wenyu", "--wenyu-model", "moongate/exact",
      "Check", "existing",
    ]),
    (Some("wenyu"), "native", "moongate/exact", "Check existing", true),
  )
  assert_eq(
    parse_options(["--", "--wenyu-allow-no-change"]),
    (None, "native", "", "--wenyu-allow-no-change", false),
  )
  assert_eq(
    parse_options(["--book", "--wenyu-allow-no-change", "goal"]),
    (Some("--wenyu-allow-no-change"), "native", "", "goal", false),
  )
  assert_eq(parse(["goal"]), (None, "native", "", "goal"))
  for
    args in [
      ["--wenyu-allow-no-change"],
      ["--wenyu-allow-no-change", "--wenyu-execution", "acp", "goal"],
      ["--unknown", "goal"],
    ] {
    try {
      ignore(parse_options(args))
      fail("expected invalid option")
    } catch {
      error =>
        assert_false(error.to_string().contains("expected invalid option"))
    }
  }
  try {
    ignore(parse(["--wenyu-allow-no-change", "goal"]))
    fail("legacy parser must reject new option")
  } catch {
    error =>
      assert_false(error.to_string().contains("legacy parser must reject"))
  }
}
