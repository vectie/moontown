///|
test "runtime status summarizes execution lifecycle counts" {
  let state = runtime_status_test_state()
  state.register_execution(
    runtime_status_test_execution(
      "task-running",
      "research-moontown",
      "packet-running",
      @core.TaskExecutionStatus::Running,
      "running",
    ),
  )
  state.register_execution(
    runtime_status_test_execution(
      "task-review",
      "research-moonbook",
      "packet-review",
      @core.TaskExecutionStatus::ReviewQueued,
      "review",
    ),
  )
  let status = runtime_status_from_state(state, "/tmp/town.json")
  assert_eq(status.running_count, 1)
  assert_eq(status.review_count, 1)
  assert_eq(status.execution_count, 2)
  assert_eq(status.standing_goal_count, 0)
}

///|
test "runtime status summary composes stable metric groups" {
  let state = runtime_status_test_state()
  let summary = @runtime_status_policy.runtime_status_summary(
    state,
    { running: 1, review: 2, failed: 3, stale: 4, completed: 5 },
    { total: 6, enabled: 5, disabled: 1, due: 2 },
    7,
    { total: 8, pending: 9, failed: 10 },
    11,
  )
  assert_true(summary.contains("books=\{state.books.length()}"))
  assert_true(summary.contains("running=1 review=2 failed=3 stale=4"))
  assert_true(
    summary.contains(
      "standing_goals=6 enabled_standing_goals=5 disabled_standing_goals=1 due_goals=2",
    ),
  )
  assert_true(
    summary.contains(
      "book_template_requests=8 pending_template_requests=9 failed_template_requests=10",
    ),
  )
  assert_true(summary.contains("watcher_records=7 planned_actions=11"))
}

///|
test "runtime status ignores stale duplicate running record for terminal task" {
  let state = runtime_status_test_state()
  state.register_execution(
    runtime_status_test_execution(
      "task-dup",
      "research-opc",
      "packet-final",
      @core.TaskExecutionStatus::ReviewQueued,
      "terminal",
    ),
  )
  state.register_execution(
    runtime_status_test_execution(
      "task-dup",
      "research-opc",
      "packet-running",
      @core.TaskExecutionStatus::Running,
      "old live snapshot",
    ),
  )
  let status = runtime_status_from_state(state, "/tmp/town.json")
  assert_eq(status.running_count, 0)
  assert_eq(status.review_count, 1)
}

///|
test "runtime status keeps later duplicate when lifecycle rank ties" {
  let state = runtime_status_test_state()
  state.register_execution(
    runtime_status_test_execution(
      "task-dup",
      "research-opc",
      "packet-first",
      @core.TaskExecutionStatus::Running,
      "first live snapshot",
    ),
  )
  state.register_execution(
    runtime_status_test_execution(
      "task-dup",
      "research-opc",
      "packet-second",
      @core.TaskExecutionStatus::AwaitingPersistence,
      "later live snapshot with the same lifecycle rank",
    ),
  )
  let status = runtime_status_from_state(state, "/tmp/town.json")
  assert_eq(status.running_count, 1)
  assert_eq(status.execution_count, 2)
}

///|
test "runtime execution counts use effective execution indexes" {
  let state = runtime_status_test_state()
  state.register_execution(
    runtime_status_test_execution(
      "task-one",
      "research-opc",
      "packet-one",
      @core.TaskExecutionStatus::Running,
      "running",
    ),
  )
  state.register_execution(
    runtime_status_test_execution(
      "task-two",
      "research-opc",
      "packet-two",
      @core.TaskExecutionStatus::Completed,
      "completed",
    ),
  )
  let status = runtime_status_from_state(state, "/tmp/town.json")
  assert_eq(status.running_count, 1)
  assert_eq(status.completed_count, 1)
}

///|
test "runtime status suppresses superseded standing watch failures" {
  let state = runtime_status_test_state()
  state.register_book(
    @core.BookRef::new(
      id="research-opc",
      name="Research OPC",
      purpose="Watch OPC",
      workspace_root="/tmp/research-opc",
    ),
  )
  state.register_execution(
    runtime_status_test_execution(
      "standing-watch-opc-news-tick-2",
      "research-opc",
      "packet-2",
      @core.TaskExecutionStatus::Failed,
      "no eligible worker",
    ),
  )
  state.register_execution(
    runtime_status_test_execution(
      "standing-watch-opc-news-tick-5",
      "research-opc",
      "packet-5",
      @core.TaskExecutionStatus::ReviewQueued,
      "standing_goal_decision: no_change",
    ),
  )
  let status = runtime_status_from_state(state, "/tmp/town.json")
  assert_eq(status.failed_count, 0)
  assert_eq(status.daemon_actions.length(), 0)
}
