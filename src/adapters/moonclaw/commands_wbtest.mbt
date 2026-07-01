///|
test "default MoonClaw command root uses Moontown product home" {
  let command = build_run_command("run-1")
  assert_true(
    command.contains(
      "-C " + @storage.moontown_product_artifact("external/moonclaw"),
    ),
  )
  assert_true(command.contains("--home ."))
  assert_false(command.contains("-C .moontown/external/moonclaw"))
  assert_false(command.contains("--home .moonclaw"))
}
