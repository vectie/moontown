///|
fn acceptance_scheduler_execution(
  status : @core.TaskExecutionStatus,
) -> @core.TaskExecutionRecord {
  @core.TaskExecutionRecord::new(
    task_id="acceptance-task",
    book_id="book",
    packet_id="packet",
    packet_path="packet.json",
    status~,
    summary="Book review approved; goal acceptance remains unevaluated",
    output_contract="wenyu.build.native-result.v1",
    next_retry_tick=Some(1),
  )
}

///|
test "scheduler does not resume approved review while goal acceptance is pending" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="acceptance", name="Acceptance"),
  )
  let report = @health.inspect_town(state)
  let execution = acceptance_scheduler_execution(AwaitingAcceptance)
  state.register_execution(execution)
  state.enqueue_task(
    @core.TownTask::new(
      id="acceptance-task",
      book_id="book",
      title="Acceptance pending",
      prompt="Original goal",
      domain=Coding,
      status=Running,
    ),
  )
  assert_true(execution_action_kind(execution) is None)
  assert_eq(plan_tick(state, report).length(), 0)
  assert_true(
    execution_action_kind(acceptance_scheduler_execution(ReviewQueued))
    is Some(_),
  )
  assert_true(
    execution_action_kind(acceptance_scheduler_execution(Completed)) is Some(_),
  )
}
