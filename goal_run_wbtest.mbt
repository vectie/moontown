///|
test "bootstrap planning keeps a single-task ingest-first limit" {
  assert_eq(research_bootstrap_task_limit(), 1)
}
