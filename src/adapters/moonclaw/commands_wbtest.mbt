///|
test "default MoonClaw command root uses MoonTown product home" {
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

///|
async test "configured installed MoonClaw binary bypasses source compilation" {
  let previous = @env.get_env_var("MOONTOWN_MOONCLAW_BIN")
  @env.set_env_var("MOONTOWN_MOONCLAW_BIN", "/opt/moonsuite/bin/moonclaw")
  let (command, args) = moonclaw_runtime_invocation("/opt/moonclaw-source", [
    "proposal", "run", "run-1",
  ])
  assert_eq(command, "/opt/moonsuite/bin/moonclaw")
  assert_eq(args, ["proposal", "run", "run-1"])
  match previous {
    Some(value) => @env.set_env_var("MOONTOWN_MOONCLAW_BIN", value)
    None => @env.unset_env_var("MOONTOWN_MOONCLAW_BIN")
  }
}
