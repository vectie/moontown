///|
test "lane status prefers review queued over complete" {
  let state = goal_run_test_state()
  state.register_execution(
    goal_run_lane_execution(
      task_id="task-a",
      book_id="research-moonbook",
      packet_id="packet-a",
      status=@core.TaskExecutionStatus::Completed,
      summary="completed",
    ),
  )
  state.register_execution(
    goal_run_lane_execution(
      task_id="task-b",
      book_id="research-moonbook",
      packet_id="packet-b",
      status=@core.TaskExecutionStatus::ReviewQueued,
      summary="quality gate",
    ),
  )
  assert_eq(lane_research_status(state, "research-moonbook"), "review queued")
}

///|
test "goal book finalization detects only new pending reviews" {
  let summary = goal_run_book_summary(
    book_id="research-moonbook",
    pending_review_count=2,
  )
  assert_true(goal_book_has_new_pending_reviews(summary, 1))
  assert_true(!goal_book_has_new_pending_reviews(summary, 2))
  assert_true(!goal_book_has_new_pending_reviews(summary, 3))
}

///|
test "goal book summary event detail separates domain and operational evidence" {
  let entry = goal_run_research_entry(
    id="research-opc",
    name="OPC Research",
    workspace_root="/tmp/research-opc",
  )
  let summary = goal_run_book_summary(
    book_id="research-opc",
    page_count=9,
    evidence_count=4,
    operational_evidence_count=3,
    total_evidence_count=7,
    pending_review_count=1,
  )
  let detail = goal_book_summary_event_detail(entry, summary, [
    "missing source-screen",
  ])
  assert_true(detail.contains("Book summary research-opc:"))
  assert_true(detail.contains("pages=9"))
  assert_true(detail.contains("domain_evidence=4"))
  assert_true(detail.contains("operational_evidence=3"))
  assert_true(detail.contains("total_evidence=7"))
  assert_true(detail.contains("pending_review=1"))
  assert_true(detail.contains("quality_gaps=1"))
  assert_true(detail.contains("readiness="))
}

///|
test "goal book projection event keeps book scoped identifiers" {
  let entry = goal_run_research_entry(
    id="research-llm-training",
    name="LLM Training",
    workspace_root="/tmp/research-llm-training",
  )
  let event = goal_book_projection_event(
    entry, "book/site/generated/index.html",
  )
  assert_eq(event.id, "event-build-research-llm-training")
  assert_eq(event.kind, "projection")
  assert_true(event.related_book_id is Some("research-llm-training"))
  assert_true(event.detail.contains("Generated site for research-llm-training"))
}
