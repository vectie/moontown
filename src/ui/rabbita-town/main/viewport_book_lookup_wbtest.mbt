///|
fn lookup_test_task(id : String, book_id : String) -> @core.TownTask {
  @core.TownTask::new(
    id~,
    book_id~,
    title=id,
    prompt="test",
    domain=@core.WorkDomain::SocialExperiment,
  )
}

///|
test "priority book task lookup across aliases ignores alias order" {
  let tasks = [
    lookup_test_task("implementation-backlog-social", "social-square"),
    lookup_test_task("code-patch-wenyu-social", "wenyu-social-square"),
    lookup_test_task("asset-pack-social", "social-square"),
  ]
  let selected = find_priority_book_task_by_ids(tasks, [
    "social-square", "wenyu-social-square",
  ])
  assert_eq(selected.unwrap().id, "code-patch-wenyu-social")
}

///|
test "priority book task lookup returns none when aliases do not match" {
  let tasks = [
    lookup_test_task("code-patch-wenyu-social", "wenyu-social-square"),
  ]
  let selected = find_priority_book_task_by_ids(tasks, ["policy-hall"])
  assert_true(selected is None)
}
