///|
fn civic_service_persist_completed_execution() -> @core.TaskExecutionRecord {
  @core.TaskExecutionRecord::new(
    task_id="goal-wenyu-policy-hall-civic-service",
    book_id="wenyu-policy-hall",
    packet_id="packet-civic",
    packet_path="packet-civic.json",
    run_id=Some("run-civic"),
    status=@core.TaskExecutionStatus::Completed,
    summary="civic_service_decision: update\nbook_changed: yes\nwiki_pages_changed_count: 2\naccepted_facts_count: 3\nreview_items_created_count: 1\nprojection_updated: yes\nnext_check_hint: normal\nThe policy hall reconciled citations and created a review item.",
    output_contract="wenyu.civic.policy_service.v1",
    requires_review=true,
  )
}

///|
test "Wenyu civic persistence creates service and review candidates" {
  let service = @civic.wenyu_civic_service_for_book_id("wenyu-policy-hall").unwrap()
  let execution = civic_service_persist_completed_execution()
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

///|
test "civic persistence detection recognizes task contract surfaces" {
  let execution = civic_service_persist_completed_execution()
  assert_true(is_civic_service_execution(execution))
  let context_execution = @core.TaskExecutionRecord::new(
    task_id="goal-wenyu-social-square-custom",
    book_id="wenyu-social-square",
    packet_id="packet-civic-context",
    packet_path="packet-civic-context.json",
    status=@core.TaskExecutionStatus::Completed,
    summary="completed",
    output_contract="custom",
    context_pages=["skills/wenyu-civic-service/SKILL.md"],
  )
  assert_true(is_civic_service_execution(context_execution))
}
