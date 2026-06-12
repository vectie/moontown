///|
pub fn visual_projection_test_state(
  worker_status? : @core.WorkerStatus = @core.WorkerStatus::Running,
  execution_status? : @core.TaskExecutionStatus = @core.TaskExecutionStatus::Running,
) -> @core.TownState {
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
      status=worker_status,
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
      status=execution_status,
      summary="Running OPC watch.",
      output_contract="moontown.watch.v1",
      assigned_worker_id=Some("worker-opc-researcher"),
      heartbeat_tick=42,
    ),
  )
  state
}
