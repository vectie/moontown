///|
async test "civic protocol schedule status uses communication boundary" {
  let output = render_civic_protocols_command(["schedules", "status"])
  assert_true(output.contains("Civic Communication Pattern Schedule Status"))
}
