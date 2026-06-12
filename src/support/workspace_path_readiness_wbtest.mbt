///|
async test "workspace relative path readiness reports missing paths" {
  let root = "/tmp/moontown-workspace-path-readiness-wbtest"
  ignore(@integration.run_checked("rm", ["-rf", root]))
  let required = ["wiki/index.md", "book/site/generated/index.html"]
  let missing_before = workspace_missing_relative_paths(root, required)
  assert_eq(missing_before.length(), 2)
  assert_false(workspace_relative_paths_ready(root, required))
  write_text_file("\{root}/wiki/index.md", "# Index")
  let missing_after = workspace_missing_relative_paths(root, required)
  assert_eq(missing_after.length(), 1)
  assert_true(!missing_after.contains("wiki/index.md"))
  assert_true(missing_after.contains("book/site/generated/index.html"))
  write_text_file("\{root}/book/site/generated/index.html", "<!doctype html>")
  assert_true(workspace_missing_relative_paths(root, required).is_empty())
  assert_true(workspace_relative_paths_ready(root, required))
  assert_true(workspace_relative_paths_ready(root, []))
}
