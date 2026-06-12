///|
test "build pipeline owns Wenyu build task contract" {
  let entry = @moonbook.BookCatalogEntry::new(
    id="wenyu-town-shell",
    name="Wenyu Valley / Town Shell",
    purpose="Build the town shell.",
    workspace_root="/tmp/wenyu-town-shell",
  )
  let tasks = wenyu_build_tasks(entry, "Build Wenyu Valley", "/repo")
  assert_eq(tasks.length(), 4)
  assert_true(tasks.any(fn(task) { task.kind == "civic-service-workflow" }))
  assert_true(tasks.any(fn(task) { task.kind == "implementation-backlog" }))
  assert_true(tasks.any(fn(task) { task.kind == "code-patch" }))
  assert_true(tasks.any(fn(task) { task.kind == "image-asset" }))
  let asset = tasks[tasks.length() - 1]
  assert_true(
    asset.target_pages.contains(
      @policy.default_generated_site_projection_path(),
    ),
  )
}
