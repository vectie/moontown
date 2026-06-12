///|
test "legacy tick-domain stale standing watch is policy-owned" {
  let execution = @core.TaskExecutionRecord::new(
    task_id="standing-watch-opc-news-tick-42",
    book_id="research-opc",
    packet_id="packet",
    packet_path="packet.json",
    status=@core.TaskExecutionStatus::Stale,
    summary="standing watch missed its heartbeat window",
    output_contract="standing-watch-live-snapshot",
    heartbeat_tick=1,
    stale_after_tick=30,
  )
  assert_true(legacy_tick_domain_stale_standing_watch(execution))
}

///|
test "legacy review queued retry accounting recognizes transient zero-delta failures" {
  let execution = @core.TaskExecutionRecord::new(
    task_id="standing-watch-opc-news-tick-42",
    book_id="research-opc",
    packet_id="packet",
    packet_path="packet.json",
    status=@core.TaskExecutionStatus::ReviewQueued,
    summary="standing watch execution failed: bad request\nstanding_goal_decision: failed\ndelta_score: 0\nnew_source_count: 0\nbook_changed: no",
    output_contract="standing-watch-live-snapshot",
    heartbeat_tick=1,
    stale_after_tick=30,
  )
  assert_true(legacy_review_queued_retry_accounting_standing_watch(execution))
}
