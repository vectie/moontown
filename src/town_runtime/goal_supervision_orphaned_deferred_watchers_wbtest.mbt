///|
async test "orphaned deferred watcher record rehydrates detached import supervision" {
  let root = cleaned_goal_supervision_test_root(
    "/tmp/moontown-orphaned-deferred-watch-rehydrate-wbtest",
  )
  let snapshot_path = "\{root}/town.json"
  let packet_path = "\{root}/packets/keeper-research-opc-standing-watch-opc-news-tick-50-abc.json"
  let receipt_path = packet_path + ".import.json"
  @support.write_text_file(
    receipt_path,
    detached_import_receipt_json(status="Pending"),
  )
  let goal = standing_watch_goal_fixture(
    id="watch-opc-news",
    title="Track OPC",
    prompt="watch opc",
    book_id="research-opc",
  )
  @storage.append_watcher_run_record(
    goal.id,
    @core.WatcherRunRecord::new(
      goal_id=goal.id,
      tick=50,
      target_book_id="research-opc",
      decision=@core.WatcherDecisionKind::Deferred,
      detail="Launched detached MoonClaw import for keeper-research-opc-standing-watch-opc-news-tick-50-abc; waiting for receipt \{receipt_path}.",
      task_id=Some("standing-watch-opc-news-tick-50"),
      next_due_tick=110,
    ),
    dir="\{root}/watchers",
  )
  let state = goal_supervision_test_state()
  state.register_book(research_opc_book_ref(root, purpose="watch opc"))
  rehydrate_orphaned_deferred_watcher_records(state, snapshot_path, [goal], 51)
  let execution = @core.find_execution(state, "standing-watch-opc-news-tick-50").unwrap()
  assert_eq(execution.status, @core.TaskExecutionStatus::RunConfirmed)
  assert_eq(
    execution.packet_id,
    "keeper-research-opc-standing-watch-opc-news-tick-50-abc",
  )
  assert_true(execution.run_id == Some("run-detached"))
  assert_true(execution.proposal_id == Some("proposal-detached"))
  assert_true(execution.summary.contains("run run-detached is ready"))
  assert_true(
    @core.find_task(state, "standing-watch-opc-news-tick-50") is Some(_),
  )
}

///|
async test "orphaned deferred watcher record ignores already superseded terminal ledger" {
  let root = cleaned_goal_supervision_test_root(
    "/tmp/moontown-orphaned-deferred-watch-superseded-wbtest",
  )
  let snapshot_path = "\{root}/town.json"
  let packet_path = "\{root}/packets/keeper-research-opc-standing-watch-opc-news-tick-50-abc.json"
  let receipt_path = packet_path + ".import.json"
  @support.write_text_file(
    receipt_path,
    detached_import_receipt_json(status="Pending"),
  )
  let goal = standing_watch_goal_fixture(
    id="watch-opc-news",
    title="Track OPC",
    prompt="watch opc",
    book_id="research-opc",
  )
  @storage.append_watcher_run_record(
    goal.id,
    @core.WatcherRunRecord::new(
      goal_id=goal.id,
      tick=50,
      target_book_id="research-opc",
      decision=@core.WatcherDecisionKind::Deferred,
      detail="Launched detached MoonClaw import; waiting for receipt \{receipt_path}.",
      task_id=Some("standing-watch-opc-news-tick-50"),
      next_due_tick=110,
    ),
    dir="\{root}/watchers",
  )
  @storage.append_watcher_run_record(
    goal.id,
    @core.WatcherRunRecord::new(
      goal_id=goal.id,
      tick=50,
      target_book_id="research-opc",
      decision=@core.WatcherDecisionKind::NoChange,
      detail="standing_goal_decision: no_change",
      task_id=Some("standing-watch-opc-news-tick-50"),
      run_id=Some("run-detached"),
      next_due_tick=110,
    ),
    dir="\{root}/watchers",
  )
  let state = goal_supervision_test_state()
  rehydrate_orphaned_deferred_watcher_records(state, snapshot_path, [goal], 51)
  assert_true(
    @core.find_execution(state, "standing-watch-opc-news-tick-50") is None,
  )
}
