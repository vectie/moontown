///|
test "awaiting acceptance is blocked inactive nonterminal and never retried" {
  assert_eq(town_task_status_for_execution(AwaitingAcceptance), Blocked)
  assert_false(terminal_execution_status(AwaitingAcceptance))
  assert_false(live_execution_status(AwaitingAcceptance))
  assert_false(active_work_execution_status(AwaitingAcceptance))
  assert_false(pollable_execution_status(AwaitingAcceptance))
  assert_true(
    execution_status_rank(AwaitingAcceptance) > execution_status_rank(Running),
  )
  let state = empty_state(TownConfig::new(id="acceptance", name="Acceptance"))
  let execution = TaskExecutionRecord::new(
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
  assert_eq(live_external_execution_count(state), 0)
  assert_false(has_live_executions(state))
  assert_false(has_active_work_executions(state))
  assert_false(has_retry_pending_executions(state, 100))
  assert_false(no_run_id_live_execution_stale(execution, 100))
}

///|
test "execution status JSON keeps every legacy string shape and adds acceptance" {
  let cases : Array[(TaskExecutionStatus, String)] = [
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
    assert_eq(status.to_string(), name)
    assert_eq(status.to_json(), name.to_json())
    let decoded : TaskExecutionStatus = @json.from_json(name.to_json())
    assert_eq(decoded, status)
  }
}
