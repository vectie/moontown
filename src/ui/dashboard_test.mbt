///|
fn sample_dashboard_model() -> @ui.DashboardModel {
  let state = dashboard_test_state()
  dashboard_test_register_book(state)
  dashboard_test_register_harness_worker(state)
  dashboard_test_enqueue_task(
    state,
    id="task-town-layer",
    title="Implement town orchestration layer",
    prompt="Route coding work to the right claw worker.",
    required_role=Some(Harness),
  )
  dashboard_test_model(state)
}

///|
test "dashboard text is a non-spatial operations summary" {
  let text = @ui.render_dashboard(sample_dashboard_model())
  assert_true(text.contains("Dashboard / MoonTown / Moonrise"))
  assert_true(text.contains("## Overview"))
  assert_true(text.contains("- town: MoonTown / Moonrise"))
  assert_true(text.contains("## Book Activity"))
  assert_true(text.contains("## Books"))
  assert_true(text.contains("- coding: /workspace/coding"))
  assert_true(text.contains("## Workers"))
  assert_true(text.contains("- claw-harness: Idle"))
  assert_true(text.contains("## Tasks"))
  assert_true(text.contains("- task-town-layer:"))
  assert_true(text.contains("stage=Planning"))
  assert_true(text.contains("## Pipeline"))
  assert_true(
    text.contains("- coding / Planning / task-town-layer / not-started"),
  )
  assert_true(text.contains("## Executions"))
  assert_false(text.contains("## Town Map"))
  assert_false(text.contains("frame:"))
  assert_false(text.contains("tilemap/"))
}

///|
test "dashboard book activity preserves useful counts and stage" {
  let state = dashboard_test_state()
  dashboard_test_register_book(state)
  dashboard_test_register_harness_worker(state)
  dashboard_test_enqueue_task(
    state,
    id="task-bootstrap",
    title="Bootstrap sources",
    prompt="Bootstrap source population.",
  )
  dashboard_test_enqueue_task(
    state,
    id="task-research",
    title="Research pipeline",
    prompt="Research and analyze the result.",
    domain=Research,
  )
  dashboard_test_register_execution(
    state,
    task_id="task-research",
    packet_id="packet-research",
    status=Running,
    summary="running synthesis",
    output_contract="report",
  )
  let text = @ui.render_dashboard(dashboard_test_model(state))
  assert_true(text.contains("workers: 1"))
  assert_true(text.contains("tasks: 2"))
  assert_true(text.contains("executions: 1"))
  assert_true(text.contains("active stage: Bootstrap"))
}

///|
test "dashboard stage rules classify watch tasks in non-spatial sections" {
  let state = dashboard_test_state()
  dashboard_test_register_book(state)
  dashboard_test_enqueue_task(
    state,
    id="standing-watch-opc",
    title="Standing watch OPC",
    prompt="Check watcher sources.",
    domain=Research,
  )
  dashboard_test_enqueue_task(
    state,
    id="task-bootstrap",
    title="Bootstrap sources",
    prompt="Bootstrap source population.",
  )
  let text = @ui.render_dashboard(dashboard_test_model(state))
  assert_true(
    text.contains("- coding / Watch / standing-watch-opc / not-started"),
  )
  assert_true(text.contains("active stage: Bootstrap"))
}

///|
test "dashboard overview preserves execution lifecycle buckets" {
  let state = dashboard_test_state()
  dashboard_test_register_execution(
    state,
    task_id="task-packet",
    packet_id="packet-ready",
    status=PacketReady,
    summary="packet ready",
    output_contract="packet",
  )
  dashboard_test_register_execution(
    state,
    task_id="task-imported",
    packet_id="packet-imported",
    status=ProposalImported,
    summary="proposal imported",
    output_contract="proposal",
  )
  dashboard_test_register_execution(
    state,
    task_id="task-running",
    packet_id="packet-running",
    status=Running,
    summary="running work",
    output_contract="run",
  )
  dashboard_test_register_execution(
    state,
    task_id="task-review",
    packet_id="packet-review",
    status=ReviewQueued,
    summary="review queued",
    output_contract="review",
  )
  dashboard_test_register_execution(
    state,
    task_id="task-complete",
    packet_id="packet-complete",
    status=Completed,
    summary="done",
    output_contract="done",
  )
  let text = @ui.render_dashboard(dashboard_test_model(state))
  assert_true(text.contains("packets: 1 ready"))
  assert_true(text.contains("imports: 1 imported"))
  assert_true(text.contains("runs: 2 active lifecycle records"))
}

///|
test "dashboard activity omits mayor books and keeps dynamic research books" {
  let state = dashboard_test_state()
  dashboard_test_register_book(
    state,
    id="mayor",
    name="Mayor",
    purpose="Town-level reasoning.",
    workspace_root="/workspace/mayor",
  )
  dashboard_test_register_book(
    state,
    id="research-opc",
    name="Research / OPC",
    purpose="Research one-person company updates.",
    workspace_root="/workspace/research-opc",
  )
  let text = @ui.render_dashboard(dashboard_test_model(state))
  assert_false(text.contains("Mayor: workers:"))
  assert_true(text.contains("Research / OPC: workers:"))
}
