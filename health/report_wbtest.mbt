///|
test "superseded standing watch failure does not keep town degraded" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="test-town", name="Test Town"),
  )
  state.register_book(
    @core.BookRef::new(
      id="research-opc",
      name="Research OPC",
      purpose="Watch OPC",
      workspace_root="/tmp/research-opc",
    ),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-watch-opc-news-tick-2",
      book_id="research-opc",
      packet_id="packet-2",
      packet_path="packet-2.json",
      status=@core.TaskExecutionStatus::Failed,
      summary="no eligible worker",
      output_contract="test",
    ),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-watch-opc-news-tick-5",
      book_id="research-opc",
      packet_id="packet-5",
      packet_path="packet-5.json",
      status=@core.TaskExecutionStatus::ReviewQueued,
      summary="standing_goal_decision: no_change",
      output_contract="test",
    ),
  )
  let report = inspect_town(state)
  assert_true(
    !report.anomalies.any(fn(anomaly) {
      anomaly.detail.contains("standing-watch-opc-news-tick-2")
    }),
  )
  assert_eq(report.book_health[0].level, HealthLevel::Healthy)
}

///|
test "standing watch no-eligible collision is superseded by neighboring active run" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="test-town", name="Test Town"),
  )
  state.register_book(
    @core.BookRef::new(
      id="research-llm",
      name="Research LLM",
      purpose="Watch LLM",
      workspace_root="/tmp/research-llm",
    ),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-watch-llm-training-tick-8802",
      book_id="research-llm",
      packet_id="packet-8802",
      packet_path="packet-8802.json",
      status=@core.TaskExecutionStatus::Completed,
      summary="standing_goal_decision: no_change",
      output_contract="standing-watch",
    ),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="standing-watch-llm-training-tick-8803",
      book_id="research-llm",
      packet_id="packet-8803",
      packet_path="packet-8803.json",
      status=@core.TaskExecutionStatus::Failed,
      summary="Mayor could not dispatch: no eligible worker in the target book",
      output_contract="standing-watch",
    ),
  )
  let report = inspect_town(state)
  assert_true(
    !report.anomalies.any(fn(anomaly) {
      anomaly.detail.contains("standing-watch-llm-training-tick-8803")
    }),
  )
  assert_eq(report.book_health[0].level, HealthLevel::Healthy)
}
