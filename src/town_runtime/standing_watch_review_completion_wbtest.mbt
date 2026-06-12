///|
test "empty review completion summary reuses strict no-change accounting" {
  let observed = standing_watch_decision_execution(
    task_id="standing-watch-opc-tick-7",
    status=@core.TaskExecutionStatus::ReviewQueued,
    summary="Workflow completed without a decision marker.",
    requires_review=true,
    notify_town=true,
  )
  let summary = standing_watch_empty_review_completion_summary(observed)
  assert_true(
    summary.contains("keeper_auto_triage: empty_completion_no_change"),
  )
  assert_true(summary.contains("keeper_auto_triage_reason: watcher completed"))
  assert_true(summary.contains("standing_goal_decision: no_change"))
  assert_true(summary.contains("checked_sources_count: 0"))
  assert_true(summary.contains("accepted_facts_count: 0"))
  assert_true(summary.contains("book_changed: no"))
  assert_true(
    summary.contains("book_watch_record_id: standing-watch-opc-tick-7"),
  )
}
