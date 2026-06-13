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
