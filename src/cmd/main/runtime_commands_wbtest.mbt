///|
async test "daemon status renders concise runtime status" {
  let output = render_cli_command(["daemon", "status"])
  assert_true(output.contains("Moontown status"))
  assert_true(!output.contains("## Town Map"))
}
