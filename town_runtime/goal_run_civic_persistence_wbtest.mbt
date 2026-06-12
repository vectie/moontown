///|
test "Wenyu civic persistence creates service and review candidates" {
  let service = @civic.wenyu_civic_service_for_book_id("wenyu-policy-hall").unwrap()
  let execution = goal_run_completed_civic_service_execution()
  let summary = civic_persist_summary(service, execution)
  assert_true(summary.contains("Decision: `update`"))
  assert_true(summary.contains("Changed pages: 2"))
  let artifacts = civic_persist_artifacts(service, execution)
  assert_true(artifacts.contains("run-civic"))
  assert_true(artifacts.contains("book/moonbook-ui-state.json"))
  let candidates = civic_persist_memory_candidates(service, execution)
  assert_eq(candidates.length(), 2)
  assert_true(candidates[0].target_page == Some("civic/policy-hall.md"))
  assert_true(candidates[1].target_page == Some("reviews/policy-citations.md"))
}
