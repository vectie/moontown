///|
test "runtime task priority keeps self-build work visible first" {
  assert_eq(runtime_task_priority_for_id("goal-book-code-patch"), 0)
  assert_eq(runtime_task_priority_for_id("goal-book-implementation-backlog"), 1)
  assert_eq(runtime_task_priority_for_id("goal-book-image-asset"), 2)
  assert_eq(runtime_task_priority_for_id("goal-book-asset-pack"), 2)
  assert_eq(runtime_task_priority_for_id("goal-book-civic-round"), 3)
}
