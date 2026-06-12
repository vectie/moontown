///|
async test "failed standing watch closes when MoonBook has terminal no-change marker" {
  let root = "/tmp/moontown-standing-watch-failed-marker-recovery"
  let snapshot_path = "\{root}/town.json"
  let book_root = "\{root}/book"
  let goal = standing_watch_goal_fixture(
    id="watch-failed-marker",
    title="Failed marker",
    prompt="watch failed marker",
    book_id="research-opc",
  )
  write_standing_watch_history_marker(
    book_root,
    "provider-standing-watch-recovered",
    "no_change",
    8,
    0,
    "no",
    checked_sources_count=10,
    new_sources_found=3,
    rejected_facts_count=3,
  )
  let entry = goal_supervision_book_entry(
    id="research-opc",
    name="Research OPC",
    purpose="watch opc",
    workspace_root=book_root,
  )
  let state = goal_supervision_test_state()
  state.register_execution(
    standing_watch_execution_fixture(
      task_id="standing-watch-failed-marker-tick-12",
      packet_path="packet.json",
      run_id=Some("run-recovered"),
      status=@core.TaskExecutionStatus::Failed,
      summary="MoonClaw run was indexed as Running, but no live process was found.",
    ),
  )
  run_supervision_cycle(state, @roles.Mayor::new(), [entry], snapshot_path~, standing_goals=[
    goal,
  ])
  assert_eq(state.executions[0].status, @core.TaskExecutionStatus::Completed)
  assert_true(
    state.executions[0].summary.contains("keeper_auto_recovery: accepted"),
  )
  assert_true(
    state.executions[0].summary.contains("standing_goal_decision: no_change"),
  )
  let records = @storage.load_watcher_run_records(
    "watch-failed-marker",
    dir="\{root}/watchers",
  )
  assert_true(
    records.any(fn(record) {
      record.task_id == Some("standing-watch-failed-marker-tick-12") &&
      record.decision == @core.WatcherDecisionKind::NoChange
    }),
  )
}
