///|
test "mayor keeper packet ids stay compact for long task ids" {
  let task_id = "goal-own-only-the-moonbook-research-lane-build-durable-source-entity-concept-and-synthesis-coverage-for-this-lane-cross-reference-other-lanes-only-through-durable-outputs-global-town-goal-research-moontown-moonbook-and-moonclaw-bootstrap_gather"
  let packet_id = keeper_packet_id("research-moonbook", task_id)
  assert_true(packet_id.has_prefix("keeper-"))
  assert_true(packet_id.length() < 96)
  assert_true(!packet_id.contains(task_id))
}

///|
test "mayor launches queued packet-ready execution when retry tick is due" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="test", name="Test Town"),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="queued-task",
      book_id="book",
      packet_id="queued",
      packet_path="",
      status=@core.TaskExecutionStatus::PacketReady,
      summary="queued by concurrency cap",
      output_contract="moontown.queued.execution.v1",
      next_retry_tick=Some(10),
    ),
  )
  let packet = Mayor::new().supervise(state, 10)
  assert_eq(packet.directives.length(), 1)
  assert_eq(packet.directives[0].kind, retry_execution_directive_kind())
  assert_eq(packet.directives[0].task_id, "queued-task")
}
