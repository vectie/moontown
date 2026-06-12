///|
test "Wenyu build stage emits implementation code and asset tasks" {
  let entry = goal_run_wenyu_town_shell_entry()
  let tasks = @build_pipeline.wenyu_build_tasks(
    entry,
    "Build Wenyu Valley",
    current_repo_root(),
  )
  assert_eq(tasks.length(), 4)
  assert_true(tasks.any(fn(task) { task.kind == "civic-service-workflow" }))
  assert_true(tasks.any(fn(task) { task.kind == "implementation-backlog" }))
  assert_true(tasks.any(fn(task) { task.kind == "code-patch" }))
  assert_true(tasks.any(fn(task) { task.kind == "image-asset" }))
}

///|
test "Wenyu service code and asset tasks route to the expected domains" {
  let entry = goal_run_wenyu_town_shell_entry()
  let tasks = @build_pipeline.wenyu_build_tasks(
    entry,
    "Build Wenyu Valley",
    current_repo_root(),
  )
  let service = tasks[0]
  let code = tasks[2]
  let asset = tasks[3]
  assert_eq(
    domain_for_book_task(entry, service),
    @core.WorkDomain::SocialExperiment,
  )
  assert_eq(domain_for_book_task(entry, code), @core.WorkDomain::Coding)
  assert_eq(domain_for_book_task(entry, asset), @core.WorkDomain::Coding)
}
