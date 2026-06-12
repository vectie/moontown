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

///|
test "build pipeline owns Wenyu civic service task merge" {
  let entry = @moonbook.BookCatalogEntry::new(
    id="wenyu-policy-hall",
    name="Wenyu Valley / Policy Hall",
    purpose="Build the policy service.",
    workspace_root="/tmp/wenyu-policy-hall",
  )
  let bootstrap_like_task = @moonbook.BookTask::new(
    id="goal-wenyu-policy-hall-research-bootstrap-ingest",
    title="Bootstrap Wenyu Valley module coverage",
    kind="research-bootstrap-ingest",
    prompt="bootstrap",
    priority=100,
    requires_review=true,
  )
  let plan_tasks = wenyu_civic_service_plan_tasks(
    entry,
    "Build Wenyu Valley AI Innovation Town",
    [bootstrap_like_task],
  )
  assert_eq(plan_tasks.length(), 1)
  assert_eq(plan_tasks[0].kind, "civic-service-workflow")
  assert_true(plan_tasks[0].prompt.contains("wenyu.civic.policy_service.v1"))
  assert_eq(positive_wenyu_task_limit(0), 1)
  assert_eq(positive_wenyu_task_limit(3), 3)
}
