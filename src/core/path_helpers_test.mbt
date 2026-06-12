///|
test "absolute path from base preserves absolute and resolves relative paths" {
  assert_eq(
    absolute_path_from_base("/tmp/moontown-base", "/tmp/already-absolute"),
    "/tmp/already-absolute",
  )
  assert_eq(
    absolute_path_from_base("/tmp/moontown-base", "relative/file.md"),
    "/tmp/moontown-base/relative/file.md",
  )
}

///|
test "absolute path from cwd preserves absolute and resolves relative paths" {
  assert_eq(
    absolute_path_from_cwd("/tmp/moontown-core-path"),
    "/tmp/moontown-core-path",
  )
  let expected = match @env.current_dir() {
    Some(dir) =>
      @path.Path(dir).join(@path.Path("relative/file.md")).to_string()
    None => "./relative/file.md"
  }
  assert_eq(absolute_path_from_cwd("relative/file.md"), expected)
}
