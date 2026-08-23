///|
async test "civic protocol schedule status uses communication boundary" {
  let root = @fs.tmpdir(prefix="moontown-domain-command")
  let output = render_civic_protocols_command([
    "schedules",
    "status",
    root + "/town.json",
  ])
  assert_true(output.contains("Civic Communication Pattern Schedule Status"))
  @fs.rmdir(root, recursive=true)
}
