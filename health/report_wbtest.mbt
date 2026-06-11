///|
test "superseded standing watch failure does not keep town degraded" {
  let state = health_report_state_with_book(
    id="research-opc",
    name="Research OPC",
    purpose="Watch OPC",
    workspace_root="/tmp/research-opc",
  )
  register_health_report_executions(state, [
    health_report_execution(
      task_id="standing-watch-opc-news-tick-2",
      book_id="research-opc",
      status=@core.TaskExecutionStatus::Failed,
      summary="no eligible worker",
      output_contract="test",
    ),
    health_report_execution(
      task_id="standing-watch-opc-news-tick-5",
      book_id="research-opc",
      status=@core.TaskExecutionStatus::ReviewQueued,
      summary="standing_goal_decision: no_change",
      output_contract="test",
    ),
  ])
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
  let state = health_report_state_with_book(
    id="research-llm",
    name="Research LLM",
    purpose="Watch LLM",
    workspace_root="/tmp/research-llm",
  )
  register_health_report_executions(state, [
    health_report_execution(
      task_id="standing-watch-llm-training-tick-8802",
      book_id="research-llm",
      status=@core.TaskExecutionStatus::Completed,
      summary="standing_goal_decision: no_change",
    ),
    health_report_execution(
      task_id="standing-watch-llm-training-tick-8803",
      book_id="research-llm",
      status=@core.TaskExecutionStatus::Failed,
      summary="Mayor could not dispatch: no eligible worker in the target book",
    ),
  ])
  let report = inspect_town(state)
  assert_true(
    !report.anomalies.any(fn(anomaly) {
      anomaly.detail.contains("standing-watch-llm-training-tick-8803")
    }),
  )
  assert_eq(report.book_health[0].level, HealthLevel::Healthy)
}

///|
test "standing watch stale execution is superseded by active retry" {
  let state = health_report_state_with_book(
    id="research-agents",
    name="Research Agents",
    purpose="Watch agent systems",
    workspace_root="/tmp/research-agents",
  )
  register_health_report_executions(state, [
    health_report_execution(
      task_id="standing-watch-ai-agents-tick-12994",
      book_id="research-agents",
      status=@core.TaskExecutionStatus::Stale,
      summary="missed heartbeat before retry",
    ),
    health_report_execution(
      task_id="standing-watch-ai-agents-tick-12995",
      book_id="research-agents",
      status=@core.TaskExecutionStatus::RunConfirmed,
      summary="retry is active",
    ),
  ])
  let report = inspect_town(state)
  assert_true(report.anomalies.is_empty())
  assert_eq(report.book_health[0].level, HealthLevel::Healthy)
}

///|
test "repaired context packet import failure does not keep town degraded when execution carries context" {
  let state = health_report_state_with_book(
    id="coding",
    name="Coding",
    purpose="Coding memory",
    workspace_root="/tmp/coding",
  )
  register_health_report_executions(state, [
    health_report_execution(
      task_id="coding-synthesis",
      book_id="coding",
      packet_id="keeper-coding-synthesis",
      packet_path="packet.json",
      status=@core.TaskExecutionStatus::Failed,
      summary="MoonClaw proposal import failed: ExternalProposalPacket: context_pages must not be empty",
      output_contract="keeper.plan.packet.v1",
      context_pages=["wiki/index.md"],
    ),
  ])
  let report = inspect_town(state)
  assert_true(report.anomalies.is_empty())
  assert_eq(report.book_health[0].level, HealthLevel::Healthy)
}

///|
test "health anomaly counter matches exact anomaly titles" {
  let state = health_report_state_with_book(
    id="research-opc",
    name="Research OPC",
    purpose="Watch OPC",
    workspace_root="/tmp/research-opc",
  )
  register_health_report_executions(state, [
    health_report_execution(
      task_id="research-opc-failed-a",
      book_id="research-opc",
      packet_id="packet-a",
      status=@core.TaskExecutionStatus::Failed,
      summary="first failure",
    ),
    health_report_execution(
      task_id="research-opc-failed-b",
      book_id="research-opc",
      packet_id="packet-b",
      status=@core.TaskExecutionStatus::Failed,
      summary="second failure",
    ),
  ])
  let report = inspect_town(state)
  assert_eq(count_health_anomalies_by_title(report, "execution-failed"), 2)
  assert_eq(count_health_anomalies_by_title(report, "worker-health"), 0)
  assert_eq(count_health_anomalies_by_title(report, "missing"), 0)
}
