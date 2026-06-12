///|
async test "standing watch retry completion appends corrected watcher record" {
  let root = "/tmp/moontown-standing-watch-retry-ledger-test"
  let snapshot_path = "\{root}/town.json"
  let goal = standing_watch_goal_fixture(
    id="watch-retry-ledger",
    title="Retry ledger",
    prompt="watch retry ledger",
    book_id="research-opc",
  )
  @storage.save_standing_goals_file("\{root}/standing-goals.json", [goal])
  @support.write_text_file("\{root}/watchers/watch-retry-ledger.jsonl", "")
  let book_root = "\{root}/book"
  write_standing_watch_history_marker(
    book_root,
    "provider-standing-watch-retry",
    "no_change",
    7,
    0,
    "no",
    checked_sources_count=4,
  )
  let entry = research_opc_book_entry(book_root)
  let state = goal_supervision_test_state()
  let execution = standing_watch_execution_fixture(
    task_id="standing-watch-retry-ledger-tick-12",
    packet_path="packet.json",
    run_id=Some("run-retry"),
    status=@core.TaskExecutionStatus::Completed,
    summary="Workflow completed",
  )
  let observed = finalize_standing_watch_supervision_record(
    state,
    entry,
    execution,
    [goal],
    snapshot_path,
  )
  assert_true(observed.summary.contains("standing_goal_decision: no_change"))
  let records = @storage.load_watcher_run_records(
    "watch-retry-ledger",
    dir="\{root}/watchers",
  )
  assert_true(
    records.any(fn(record) {
      record.task_id == Some("standing-watch-retry-ledger-tick-12") &&
      record.run_id == Some("run-retry") &&
      record.decision == @core.WatcherDecisionKind::NoChange
    }),
  )
  let goals = @storage.load_or_create_standing_goals(
    path="\{root}/standing-goals.json",
  )
  assert_eq(goals[0].next_due_tick, 72)
}

///|
async test "persisted watcher ledger closes stale snapshot execution" {
  let root = "/tmp/moontown-standing-watch-ledger-reconcile-test"
  let snapshot_path = "\{root}/town.json"
  let goal = standing_watch_goal_fixture(
    id="watch-ledger-reconcile",
    title="Ledger reconcile",
    prompt="watch",
    book_id="research-opc",
  )
  let record = @core.WatcherRunRecord::new(
    goal_id="watch-ledger-reconcile",
    tick=42,
    target_book_id="research-opc",
    decision=@core.WatcherDecisionKind::NoChange,
    detail="standing_goal_decision: no_change\ndelta_score: 0\nnew_source_count: 0\nnext_check_hint: slower",
    task_id=Some("standing-watch-ledger-reconcile-tick-42"),
    run_id=Some("run-ledger"),
    next_due_tick=102,
  )
  @storage.append_watcher_run_record_file(
    "\{root}/watchers/watch-ledger-reconcile.jsonl",
    record,
  )
  let state = goal_supervision_test_state()
  state.register_worker(
    @core.WorkerRef::new(
      id="watcher",
      name="Watcher",
      book_id="research-opc",
      role=@core.WorkerRole::Watcher,
      status=@core.WorkerStatus::Blocked,
    ),
  )
  state.register_execution(
    standing_watch_execution_fixture(
      task_id="standing-watch-ledger-reconcile-tick-42",
      packet_path="packet.json",
      run_id=Some("run-ledger"),
      status=@core.TaskExecutionStatus::Stale,
      summary="missed heartbeat",
      assigned_worker_id=Some("watcher"),
      next_retry_tick=Some(48),
    ),
  )
  run_supervision_cycle(state, @roles.Mayor::new(), [], snapshot_path~, standing_goals=[
    goal,
  ])
  assert_eq(state.executions[0].status, @core.TaskExecutionStatus::Completed)
  assert_true(
    state.executions[0].summary.contains("reconciled_from_watcher_ledger"),
  )
  assert_eq(state.workers[0].status, @core.WorkerStatus::Idle)
}

///|
async test "standing watch auto triage appends corrected ledger after review observation" {
  let root = "/tmp/moontown-standing-watch-auto-triage-corrected-ledger"
  let snapshot_path = "\{root}/town.json"
  let book_root = "\{root}/book"
  let goal = standing_watch_goal_fixture(
    id="watch-auto-correct",
    title="Auto correct",
    prompt="watch auto correct",
    book_id="research-opc",
  )
  let task_id = "standing-watch-auto-correct-tick-12"
  let run_id = "run-auto-correct"
  @storage.append_watcher_run_record_file(
    "\{root}/watchers/watch-auto-correct.jsonl",
    @core.WatcherRunRecord::new(
      goal_id="watch-auto-correct",
      tick=12,
      target_book_id="research-opc",
      decision=@core.WatcherDecisionKind::NeedsReview,
      delta_score=0,
      new_source_count=0,
      detail="MoonClaw run \{run_id} completed: Workflow completed workspace=/tmp/run",
      task_id=Some(task_id),
      run_id=Some(run_id),
      next_due_tick=42,
    ),
  )
  write_standing_watch_history_marker(
    book_root, "provider-standing-watch-auto-correct", "no_change", 0, 0, "no",
  )
  let entry = research_opc_book_entry(book_root)
  let state = goal_supervision_test_state()
  state.register_execution(
    standing_watch_execution_fixture(
      task_id~,
      packet_path="packet.json",
      run_id=Some(run_id),
      status=@core.TaskExecutionStatus::ReviewQueued,
      summary="Workflow completed",
    ),
  )
  run_supervision_cycle(state, @roles.Mayor::new(), [entry], snapshot_path~, standing_goals=[
    goal,
  ])
  let records = @storage.load_watcher_run_records(
    "watch-auto-correct",
    dir="\{root}/watchers",
  )
  assert_true(
    records.any(fn(record) {
      record.task_id == Some(task_id) &&
      record.run_id == Some(run_id) &&
      record.decision == @core.WatcherDecisionKind::NoChange
    }),
  )
}
