///|
async test "late inline detached receipt reconciles deferred no-run execution" {
  let root = cleaned_goal_supervision_test_root(
    "/tmp/moontown-late-detached-import-receipt-wbtest",
  )
  let packet_path = "\{root}/packets/packet.json"
  let receipt =
    $|{"level":"Info","msg":"noise before json"}
    $|{
    $|  "proposal_id": "proposal-detached",
    $|  "run_id": "run-detached",
    $|  "status": "Succeeded"
    $|}

  write_text_file(packet_path + ".import.json", receipt)
  let state = goal_supervision_test_state()
  state.register_book(research_opc_book_ref(root))
  let execution = standing_watch_execution_fixture(
    task_id="standing-watch-opc-news-tick-10",
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
  reconcile_late_detached_import_receipts(state, 13)
  assert_eq(state.executions[0].status, @core.TaskExecutionStatus::Completed)
  assert_true(state.executions[0].run_id == Some("run-detached"))
  assert_true(state.executions[0].proposal_id == Some("proposal-detached"))
  assert_true(state.executions[0].summary.contains("inline run finished"))
  assert_false(state.executions[0].summary.contains("Detached runner:"))
  assert_eq(state.executions[0].packet_path, packet_path)
}

///|
test "pending standing watch placeholder reconstructs keeper packet path" {
  let execution = standing_watch_execution_fixture(
    task_id="standing-book-quality-repair-research-opc-tick-17902",
    packet_id="pending-research-opc-standing-book-quality-repair-research-opc-tick-17902",
    packet_path="",
    status=@core.TaskExecutionStatus::Completed,
    summary="closed as deferred before receipt arrived",
    heartbeat_tick=10,
    stale_after_tick=12,
    result_decision="deferred-transient-infrastructure",
  )
  let packet_id = @roles.keeper_packet_id(execution.book_id, execution.task_id)
  assert_eq(detached_import_packet_id_for_execution(execution), packet_id)
  assert_eq(
    detached_import_packet_path_for_execution(execution),
    @moonclaw.packet_file_path(@moonclaw.default_packet_directory(), packet_id),
  )
}

///|
async test "late detached reconciliation hydrates missing packet handle without receipt" {
  let state = goal_supervision_test_state()
  let execution = standing_watch_execution_fixture(
    task_id="standing-book-quality-repair-research-opc-tick-17902",
    packet_id="pending-research-opc-standing-book-quality-repair-research-opc-tick-17902",
    packet_path="",
    status=@core.TaskExecutionStatus::Completed,
    summary="closed as deferred before receipt arrived",
    heartbeat_tick=10,
    stale_after_tick=12,
    result_decision="deferred-transient-infrastructure",
  )
  state.register_execution(execution)
  reconcile_late_detached_import_receipts(state, 13)
  let packet_id = @roles.keeper_packet_id(execution.book_id, execution.task_id)
  assert_eq(state.executions[0].packet_id, packet_id)
  assert_eq(
    state.executions[0].packet_path,
    @moonclaw.packet_file_path(@moonclaw.default_packet_directory(), packet_id),
  )
}
