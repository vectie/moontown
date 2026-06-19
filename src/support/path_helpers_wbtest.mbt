///|
test "support absolute path from cwd preserves absolute and resolves relative paths" {
  assert_eq(
    absolute_path_from_cwd("/tmp/moontown-support-path"),
    "/tmp/moontown-support-path",
  )
  let expected = match @env.current_dir() {
    Some(dir) =>
      support_path(dir).join(support_path("relative/file.md")).to_string()
    None => "./relative/file.md"
  }
  assert_eq(absolute_path_from_cwd("relative/file.md"), expected)
}
