///|
test "runtime status summarizes execution lifecycle counts" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="test-town", name="Test Town"),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="task-running",
      book_id="research-moontown",
      packet_id="packet-running",
      packet_path="packet-running.json",
      status=@core.TaskExecutionStatus::Running,
      summary="running",
      output_contract="test",
    ),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="task-review",
      book_id="research-moonbook",
      packet_id="packet-review",
      packet_path="packet-review.json",
      status=@core.TaskExecutionStatus::ReviewQueued,
      summary="review",
      output_contract="test",
    ),
  )
  let status = runtime_status_from_state(state, "/tmp/town.json")
  assert_eq(status.running_count, 1)
  assert_eq(status.review_count, 1)
  assert_eq(status.execution_count, 2)
}

///|
test "research readiness exposes typed coverage gaps" {
  let summary = @moonbook.BookStateSummary::new(
    book_id="research-moonclaw",
    root="/tmp/research-moonclaw",
    page_count=2,
    source_count=0,
    entity_count=0,
    concept_count=0,
    pending_review_count=0,
    keeper_memory_count=0,
    keeper_working_count=0,
    evidence_count=0,
    summary="empty",
  )
  let readiness = ResearchReadiness::from_summary(summary)
  assert_true(!readiness.substantive_coverage_ready)
  assert_true(readiness.gaps.length() >= 4)
}
