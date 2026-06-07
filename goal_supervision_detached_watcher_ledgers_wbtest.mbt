///|
async test "late detached receipt appends terminal watcher ledger record" {
  let root = cleaned_goal_supervision_test_root(
    "/tmp/moontown-late-detached-watch-ledger-wbtest",
  )
  let snapshot_path = "\{root}/town.json"
  let packet_path = "\{root}/packets/packet.json"
  let task_id = "standing-watch-late-ledger-tick-10"
  let receipt =
    $|{
    $|  "proposal_id": "proposal-detached",
    $|  "run_id": "run-detached",
    $|  "status": "Succeeded"
    $|}

  write_text_file(packet_path + ".import.json", receipt)
  let book_root = "\{root}/book"
  write_standing_watch_history_marker(
    book_root, "provider-standing-watch-late-ledger", "no_change", 0, 0, "no",
  )
  let goal = standing_watch_goal_fixture(
    id="watch-late-ledger",
    title="Watch late ledger",
    prompt="watch late ledger",
    book_id="research-opc",
  )
  @storage.save_standing_goals_file("\{root}/standing-goals.json", [goal])
  append_standing_watch_record(
    goal.id,
    "\{root}/watchers",
    @core.WatcherRunRecord::new(
      goal_id=goal.id,
      tick=10,
      target_book_id="research-opc",
      decision=@core.WatcherDecisionKind::Deferred,
      detail="Mayor deferred while detached import was pending.",
      task_id=Some(task_id),
      next_due_tick=70,
    ),
  )
  let entry = research_opc_book_entry(book_root)
  let state = goal_supervision_test_state()
  let execution = standing_watch_execution_fixture(
    task_id~,
    packet_path~,
    status=@core.TaskExecutionStatus::Completed,
    summary="closed as deferred before receipt arrived",
    heartbeat_tick=10,
    stale_after_tick=12,
    result_decision="deferred-transient-infrastructure",
    last_command=Some(
      "moon proposal import > \{packet_path}.import.json 2> \{packet_path}.import.json.err",
    ),
  )
  state.register_execution(execution)
  reconcile_late_detached_import_receipts(
    state,
    13,
    catalog=[entry],
    snapshot_path~,
    standing_goals=[goal],
  )
  let records = @storage.load_watcher_run_records(
    "watch-late-ledger",
    dir="\{root}/watchers",
  )
  assert_true(
    records.any(fn(record) {
      record.task_id == Some(task_id) &&
      record.run_id == Some("run-detached") &&
      record.decision == @core.WatcherDecisionKind::NoChange
    }),
  )
  assert_true(
    state.executions[0].summary.contains("standing_goal_decision: no_change"),
  )
}

///|
async test "terminal detached watcher ledger reconciliation handles already completed receipt" {
  let root = cleaned_goal_supervision_test_root(
    "/tmp/moontown-terminal-detached-watch-ledger-wbtest",
  )
  let snapshot_path = "\{root}/town.json"
  let packet_path = "\{root}/packets/packet.json"
  let task_id = "standing-watch-terminal-ledger-tick-10"
  write_text_file(
    packet_path + ".import.json",
    detached_import_receipt_json(status="Succeeded"),
  )
  let book_root = "\{root}/book"
  write_standing_watch_history_marker(
    book_root, "provider-standing-watch-terminal-ledger", "no_change", 0, 0, "no",
  )
  let goal = standing_watch_goal_fixture(
    id="watch-terminal-ledger",
    title="Watch terminal ledger",
    prompt="watch terminal ledger",
    book_id="research-opc",
  )
  append_standing_watch_record(
    goal.id,
    "\{root}/watchers",
    @core.WatcherRunRecord::new(
      goal_id=goal.id,
      tick=10,
      target_book_id="research-opc",
      decision=@core.WatcherDecisionKind::Deferred,
      detail="Mayor deferred while detached import was pending.",
      task_id=Some(task_id),
      next_due_tick=70,
    ),
  )
  let entry = research_opc_book_entry(book_root)
  let state = goal_supervision_test_state()
  state.register_execution(
    standing_watch_execution_fixture(
      task_id~,
      packet_path~,
      run_id=Some("run-detached"),
      status=@core.TaskExecutionStatus::Completed,
      summary="Detached MoonClaw import completed; inline run finished.",
      result_decision="completed",
    ),
  )
  reconcile_terminal_detached_watcher_ledgers(state, [entry], snapshot_path, [
    goal,
  ])
  let records = @storage.load_watcher_run_records(
    "watch-terminal-ledger",
    dir="\{root}/watchers",
  )
  assert_true(
    records.any(fn(record) {
      record.task_id == Some(task_id) &&
      record.run_id == Some("run-detached") &&
      record.decision == @core.WatcherDecisionKind::NoChange
    }),
  )
  state.replace_execution(
    copy_execution_with(
      state.executions[0],
      summary="MoonClaw run run-detached completed: Workflow completed",
      requires_review=true,
    ),
  )
  reconcile_terminal_detached_watcher_ledgers(state, [entry], snapshot_path, [
    goal,
  ])
  let after_duplicate_attempt = @storage.load_watcher_run_records(
    "watch-terminal-ledger",
    dir="\{root}/watchers",
  )
  let mut terminal_count = 0
  for record in after_duplicate_attempt {
    if record.task_id == Some(task_id) &&
      record.run_id == Some("run-detached") &&
      record.decision != @core.WatcherDecisionKind::Deferred {
      terminal_count += 1
      assert_eq(record.decision, @core.WatcherDecisionKind::NoChange)
    }
  }
  assert_eq(terminal_count, 1)
}
