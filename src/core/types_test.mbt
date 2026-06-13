///|
test "core state registers books workers and tasks" {
  let state = empty_state(TownConfig::new(id="town", name="Moontown"))
  state.register_book(
    BookRef::new(
      id="coding",
      name="Coding",
      purpose="code",
      workspace_root="/tmp/coding",
    ),
  )
  state.register_worker(
    WorkerRef::new(
      id="worker-1",
      name="Harness",
      book_id="coding",
      role=@core.WorkerRole::Harness,
    ),
  )
  state.enqueue_task(
    TownTask::new(
      id="task-1",
      book_id="coding",
      title="Implement",
      prompt="Build the router.",
      domain=@core.WorkDomain::Coding,
    ),
  )
  assert_eq(state.books.length(), 1)
  assert_eq(state.workers.length(), 1)
  assert_eq(state.tasks.length(), 1)
}

///|
test "core state replaces all duplicate execution records for same task" {
  let state = empty_state(TownConfig::new(id="town", name="Moontown"))
  state.register_execution(
    TaskExecutionRecord::new(
      task_id="task-1",
      book_id="coding",
      packet_id="packet-1",
      packet_path="packet-1.json",
      status=TaskExecutionStatus::Running,
      summary="old running",
      output_contract="test",
    ),
  )
  state.register_execution(
    TaskExecutionRecord::new(
      task_id="task-1",
      book_id="coding",
      packet_id="packet-1b",
      packet_path="packet-1b.json",
      status=TaskExecutionStatus::Running,
      summary="duplicate running",
      output_contract="test",
    ),
  )
  state.replace_execution(
    TaskExecutionRecord::new(
      task_id="task-1",
      book_id="coding",
      packet_id="packet-1-final",
      packet_path="packet-1-final.json",
      status=TaskExecutionStatus::ReviewQueued,
      summary="final",
      output_contract="test",
    ),
  )
  assert_eq(state.executions.length(), 2)
  assert_true(
    state.executions.all(fn(execution) {
      execution.status == TaskExecutionStatus::ReviewQueued
    }),
  )
}

///|
test "standing goal marks next dispatch window" {
  let goal = StandingGoal::new(
    id="watch-opc-news",
    title="Watch OPC news",
    prompt="Research latest one person company news.",
    target_book_id=Some("research-opc"),
    cadence_ticks=6,
    next_due_tick=2,
  )
  assert_true(!goal.is_due(1))
  assert_true(goal.is_due(2))
  assert_eq(goal.source_policy, "")
  let dispatched = goal.mark_dispatched(2)
  assert_true(dispatched.last_run_tick == Some(2))
  assert_eq(dispatched.next_due_tick, 8)
}

///|
test "standing goal watcher decisions keep normal half-hour cadence on no-change" {
  let goal = StandingGoal::new(
    id="watch-opc-news",
    title="Watch OPC news",
    prompt="Research latest one person company news.",
    target_book_id=Some("research-opc"),
    cadence_ticks=8,
    next_due_tick=2,
  )
  let updated = goal.mark_watcher_decision(10, WatcherDecisionKind::Update)
  assert_eq(updated.next_due_tick, 18)
  let no_change = goal.mark_watcher_decision(
    10,
    WatcherDecisionKind::NoChange,
    no_change_streak=2,
  )
  assert_eq(no_change.next_due_tick, 18)
  let failed = goal.mark_watcher_decision(10, WatcherDecisionKind::Failed)
  assert_eq(failed.next_due_tick, 12)
  let deferred = goal.mark_watcher_decision(10, WatcherDecisionKind::Deferred)
  assert_eq(deferred.next_due_tick, 18)
}
