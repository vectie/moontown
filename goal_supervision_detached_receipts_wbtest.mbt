///|
async test "detached import receipt promotes proposal imported execution to run confirmed" {
  let root = cleaned_goal_supervision_test_root(
    "/tmp/moontown-detached-import-receipt-wbtest",
  )
  let packet_path = "\{root}/packets/packet.json"
  @support.write_text_file(
    packet_path + ".import.json",
    detached_import_receipt_json(),
  )
  let state = goal_supervision_test_state()
  let execution = standing_watch_execution_fixture(
    task_id="standing-watch-opc-news-tick-10",
    packet_path~,
    status=@core.TaskExecutionStatus::ProposalImported,
    summary="waiting for detached import",
    heartbeat_tick=10,
    stale_after_tick=40,
  )
  state.register_execution(execution)
  reconcile_no_run_id_live_execution(
    state,
    execution,
    11,
    launch_confirmed_run=false,
  )
  assert_eq(state.executions[0].status, @core.TaskExecutionStatus::RunConfirmed)
  assert_true(state.executions[0].run_id == Some("run-detached"))
  assert_true(state.executions[0].proposal_id == Some("proposal-detached"))
  assert_false(state.executions[0].summary.contains("Detached runner:"))
}

///|
async test "detached import receipt can launch confirmed run command" {
  let root = cleaned_goal_supervision_test_root(
    "/tmp/moontown-detached-import-launch-wbtest",
  )
  let packet_path = "\{root}/packets/packet.json"
  @support.write_text_file(
    packet_path + ".import.json",
    detached_import_receipt_json(),
  )
  let state = goal_supervision_test_state()
  state.register_book(research_opc_book_ref(root))
  let execution = standing_watch_execution_fixture(
    task_id="standing-watch-opc-news-tick-10",
    packet_path~,
    status=@core.TaskExecutionStatus::ProposalImported,
    summary="waiting for detached import",
    heartbeat_tick=10,
    stale_after_tick=40,
  )
  state.register_execution(execution)
  reconcile_no_run_id_live_execution(
    state,
    execution,
    11,
    launch_command_override=Some(
      "moon -C ../moonclaw run cmd/main -- proposal run run-detached",
    ),
  )
  assert_eq(state.executions[0].status, @core.TaskExecutionStatus::RunConfirmed)
  assert_true(state.executions[0].summary.contains("Detached runner:"))
  assert_true(state.executions[0].summary.contains("proposal run run-detached"))
}
