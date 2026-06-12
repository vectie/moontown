///|
test "runtime status includes watcher ledger summary" {
  let state = runtime_status_test_state()
  let record = runtime_status_watcher_record(
    goal_id="watch-opc-news",
    tick=3,
    book_id="research-opc",
    decision=@core.WatcherDecisionKind::NoChange,
    detail="no useful delta",
    next_due_tick=15,
  )
  let status = runtime_status_from_state(state, "/tmp/town.json", watcher_records=[
    record,
  ])
  assert_eq(status.watcher_record_count, 1)
  assert_true(status.watcher_summary.contains("NoChange"))
  assert_true(status.summary.contains("watcher_records=1"))
}

///|
test "runtime status includes book template request inbox summary" {
  let state = runtime_status_test_state()
  let status = runtime_status_from_state(
    state,
    "/tmp/town.json",
    book_template_request_status=Some({
      request_path: "/tmp/book-template-requests.json",
      event_path: "/tmp/book-template-request-events.jsonl",
      request_count: 3,
      pending_count: 1,
      installed_count: 1,
      failed_count: 1,
      retry_count: 1,
      ready: false,
      summary: "book_template_requests=3 pending=1 retry=1 installed=1 failed=1",
      latest_event_summary: "failed: `request-3` tick=8",
    }),
  )
  assert_eq(status.book_template_request_count, 3)
  assert_eq(status.pending_book_template_request_count, 2)
  assert_eq(status.failed_book_template_request_count, 1)
  assert_eq(status.enabled_standing_goal_count, 0)
  assert_eq(status.disabled_standing_goal_count, 0)
  assert_eq(
    status.book_template_latest_event_summary,
    "failed: `request-3` tick=8",
  )
  assert_true(status.summary.contains("book_template_requests=3"))
  assert_true(status.summary.contains("pending_template_requests=2"))
}

///|
test "runtime status distinguishes historical and current watcher due ticks" {
  let state = runtime_status_test_state()
  let record = runtime_status_watcher_record(
    goal_id="watch-opc-news",
    tick=3,
    book_id="research-opc",
    decision=@core.WatcherDecisionKind::Deferred,
    detail="previous run active",
    next_due_tick=4,
  )
  let goal = runtime_status_standing_goal(
    id="watch-opc-news",
    title="Track OPC",
    prompt="Track OPC.",
    book_id="research-opc",
    next_due_tick=64,
  )
  let status = runtime_status_from_state(
    state,
    "/tmp/town.json",
    standing_goals=[goal],
    watcher_records=[record],
  )
  assert_true(status.watcher_summary.contains("recorded_next_due_tick=4"))
  assert_true(status.watcher_summary.contains("current_next_due_tick=64"))
}

///|
test "daemon tick floor uses observed watcher and standing goal time" {
  let records = [
    runtime_status_watcher_record(
      goal_id="watch-opc-news",
      tick=15877,
      book_id="research-opc",
      decision=@core.WatcherDecisionKind::Deferred,
      next_due_tick=15907,
    ),
  ]
  let goals = [
    runtime_status_standing_goal(
      id="watch-opc-news",
      title="Track OPC",
      prompt="track",
      book_id="research-opc",
      next_due_tick=15908,
      last_run_tick=Some(15888),
    ),
  ]
  assert_eq(latest_watcher_record_tick(records), 15877)
  assert_eq(latest_standing_goal_tick(goals), 15888)
}

///|
test "watcher status prefers parsed terminal record over generic duplicate" {
  let goal = runtime_status_standing_goal(
    id="watch-opc-news",
    title="Track OPC",
    prompt="track",
    book_id="research-opc",
    next_due_tick=18032,
  )
  let parsed = runtime_status_watcher_record(
    goal_id="watch-opc-news",
    tick=17972,
    book_id="research-opc",
    decision=@core.WatcherDecisionKind::NoChange,
    delta_score=8,
    detail="standing_goal_decision: no_change\ndelta_score: 8\nnew_source_count: 0\nbook_changed: no",
    task_id=Some("standing-watch-opc-news-tick-17972"),
    run_id=Some("run-opc"),
    next_due_tick=18032,
  )
  let generic = runtime_status_watcher_record(
    goal_id="watch-opc-news",
    tick=17972,
    book_id="research-opc",
    decision=@core.WatcherDecisionKind::NeedsReview,
    detail="MoonClaw run run-opc completed: Workflow completed",
    task_id=Some("standing-watch-opc-news-tick-17972"),
    run_id=Some("run-opc"),
    next_due_tick=18002,
  )
  let summary = watcher_status_summary([parsed, generic], [goal])
  assert_true(summary.contains("latest=watch-opc-news/NoChange"))
  assert_true(!summary.contains("NeedsReview"))
}

///|
test "daemon tick floor includes execution task tick" {
  let state = runtime_status_test_state()
  state.register_execution(
    runtime_status_standing_watch_execution(
      "standing-watch-opc-news-tick-15949",
      @core.TaskExecutionStatus::Running,
      "running",
    ),
  )
  assert_eq(
    @core.tick_from_task_id("standing-watch-opc-news-tick-15949"),
    15949,
  )
  assert_eq(latest_execution_task_tick(state), 15949)
}

///|
async test "daemon tick floor parses latest daemon log sequence" {
  let root = cleaned_runtime_status_test_root(
    "/tmp/moontown-daemon-log-sequence-test",
  )
  let log_path = "\{root}/daemon.log"
  @support.write_text_file(
    log_path, "[1780279335798] tick phase=standing-goals sequence=15888\n[1780279400000] tick phase=done sequence=15890\n",
  )
  assert_eq(@daemon_runtime.latest_daemon_log_sequence(log_path), 15890)
}

///|
async test "runtime status effective tick includes active execution task tick" {
  let state = runtime_status_test_state()
  state.register_execution(
    runtime_status_standing_watch_execution(
      "standing-watch-opc-news-tick-15951",
      @core.TaskExecutionStatus::Running,
      "running",
    ),
  )
  let daemon = @scheduler.DaemonState::new(tick_sequence=15900)
  let tick = effective_daemon_tick(
    "/tmp/moontown-status-tick-test/town.json",
    daemon,
    state,
    [],
    [],
  )
  assert_eq(tick, 15951)
}
