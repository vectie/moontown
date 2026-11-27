///|
test "awaiting acceptance is blocked inactive nonterminal and never retried" {
  assert_eq(@core.town_task_status_for_execution(AwaitingAcceptance), Blocked)
  assert_false(@core.terminal_execution_status(AwaitingAcceptance))
  assert_false(@core.live_execution_status(AwaitingAcceptance))
  assert_false(@core.active_work_execution_status(AwaitingAcceptance))
  assert_false(@core.pollable_execution_status(AwaitingAcceptance))
  assert_true(
    @core.execution_status_rank(AwaitingAcceptance) >
    @core.execution_status_rank(Running),
  )
  let state = @core.empty_state(
    @core.TownConfig::new(id="acceptance", name="Acceptance"),
  )
  let execution = @core.TaskExecutionRecord::new(
    task_id="task-acceptance",
    book_id="book",
    packet_id="packet",
    packet_path="packet.json",
    status=AwaitingAcceptance,
    summary="Book review approved; goal acceptance remains unevaluated",
    output_contract="wenyu.build.native-result.v1",
    run_id=Some("native-run"),
    next_retry_tick=Some(1),
  )
  state.register_execution(execution)
  assert_eq(@core.live_external_execution_count(state), 0)
  assert_false(@core.has_live_executions(state))
  assert_false(@core.has_active_work_executions(state))
  assert_false(@core.has_retry_pending_executions(state, 100))
  assert_false(@core.no_run_id_live_execution_stale(execution, 100))
}

///|
test "execution status JSON keeps every legacy string shape and adds acceptance" {
  let cases : Array[(@core.TaskExecutionStatus, String)] = [
    (PacketReady, "PacketReady"),
    (ProposalImported, "ProposalImported"),
    (RunConfirmed, "RunConfirmed"),
    (Running, "Running"),
    (AwaitingPersistence, "AwaitingPersistence"),
    (ReviewQueued, "ReviewQueued"),
    (Completed, "Completed"),
    (Stale, "Stale"),
    (Failed, "Failed"),
    (AwaitingAcceptance, "AwaitingAcceptance"),
  ]
  for pair in cases {
    let (status, name) = pair
    assert_eq(Show::to_string(status), name)
    assert_eq(ToJson::to_json(status), ToJson::to_json(name))
    let decoded : @core.TaskExecutionStatus = @json.from_json(
      ToJson::to_json(name),
    )
    assert_eq(decoded, status)
  }
}
