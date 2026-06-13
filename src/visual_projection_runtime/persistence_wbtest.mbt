///|
fn visual_projection_runtime_test_state() -> @core.TownState {
  let state = @core.empty_state(
    @core.TownConfig::new(id="visual-test-town", name="Visual Test Town"),
  )
  state.register_book(
    @core.BookRef::new(
      id="research-opc",
      name="One Person Company Research",
      purpose="Track OPC changes",
      workspace_root="/tmp/research-opc",
    ),
  )
  state.register_worker(
    @core.WorkerRef::new(
      id="worker-opc-researcher",
      name="OPC Researcher",
      book_id="research-opc",
      role=@core.WorkerRole::Watcher,
      status=@core.WorkerStatus::Running,
    ),
  )
  state.enqueue_task(
    @core.TownTask::new(
      id="task-opc-watch",
      book_id="research-opc",
      title="Check OPC updates",
      prompt="Find new OPC sources.",
      domain=@core.WorkDomain::Research,
      status=@core.TownTaskStatus::Running,
    ),
  )
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="task-opc-watch",
      book_id="research-opc",
      packet_id="packet-opc-watch",
      packet_path="/tmp/packet-opc-watch.json",
      run_id=Some("run-opc-watch"),
      status=@core.TaskExecutionStatus::Running,
      summary="Running OPC watch.",
      output_contract="moontown.watch.v1",
      assigned_worker_id=Some("worker-opc-researcher"),
      heartbeat_tick=42,
    ),
  )
  state
}

///|
async fn ignore_checked_command(command : String, args : Array[String]) -> Unit {
  let completed = @integration.run_checked(command, args) catch { _ => return }
  ignore(completed)
}

///|
async test "town checkpoint persists visual projection beside snapshot" {
  let root = "/tmp/moontown-visual-projection-check"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  persist_visual_projection(
    visual_projection_runtime_test_state(),
    snapshot_path,
  )
  let text = @fs.read_file(
    @visual_projection.default_visual_projection_path(snapshot_path),
  ).text()
  assert_true(text.contains("\"worker_id\":\"worker-opc-researcher\""))
  assert_true(text.contains("\"phase\":\"running\""))
  assert_true(text.contains("\"effect\":\"work-particles\""))
  assert_true(text.contains("\"modules\""))
  assert_true(text.contains("\"module_id\":\"research-opc\""))
}
