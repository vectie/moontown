///|
test "activity identifiers cannot select filesystem paths" {
  assert_true(
    @activity_program.valid_activity_id(
      "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
    ),
  )
  for
    value in [
      "../private", "/absolute", "", "activity/one", "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ] {
    assert_false(@activity_program.valid_activity_id(value))
  }
}

///|
async test "the public service refuses an unconfigured legacy template before creating state" {
  let root = @fs.tmpdir(prefix="activity-program-api-")
  defer @fs.rmdir(root, recursive=true)
  let template = root + "/template.json"
  @fs.write_file(template, "{}", create_mode=CreateNew, permission=0o600)
  assert_true(
    try {
      ignore(
        @activity_program.execute(
          "save-application",
          { "title": "Untouched" },
          1000UL,
          Some("ordinary"),
          false,
          root,
          template,
        ),
      )
      false
    } catch {
      @activity_program.ProgramError::Unavailable => true
      _ => false
    },
  )
  assert_false(@fs.exists(root + "/registry.json"))
}
