///|
fn visual_projection_test_state(
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

///|
test "visual projection connects active worker to execution task" {
  let projection = build_visual_projection(visual_projection_test_state())
  assert_eq(projection.tick, 42)
  assert_eq(projection.agents.length(), 1)
  let agent = projection.agents[0]
  assert_eq(agent.worker_id, "worker-opc-researcher")
  assert_eq(agent.book_id, "research-opc")
  assert_eq(agent.phase, "running")
  assert_eq(agent.task_id, Some("task-opc-watch"))
  assert_eq(agent.task_title, Some("Check OPC updates"))
  assert_eq(agent.run_id, Some("run-opc-watch"))
  assert_eq(agent.effect, "work-particles")
  assert_eq(agent.behavior, "working")
  assert_eq(agent.visible_on_overworld, true)
  assert_true(agent.sprite_key.contains("resident_"))
  assert_true(agent.message.contains("actively working"))
}

///|
test "visual projection hides completed and idle workers inside buildings" {
  let agent = build_visual_projection(
      visual_projection_test_state(
        worker_status=@core.WorkerStatus::Idle,
        execution_status=@core.TaskExecutionStatus::Completed,
      ),
    ).agents[0]
  assert_eq(agent.phase, "completed")
  assert_eq(agent.effect, "none")
  assert_eq(agent.visible_on_overworld, false)
  assert_eq(agent.zone_key, "book-research-opc")
}

///|
test "visual projection routes failed workers to anomaly recovery" {
  let agent = build_visual_projection(
      visual_projection_test_state(
        execution_status=@core.TaskExecutionStatus::Failed,
      ),
    ).agents[0]
  assert_eq(agent.phase, "failed")
  assert_eq(agent.effect, "alert-pulse")
  assert_eq(agent.zone_key, "anomaly-corner")
  assert_eq(agent.visible_on_overworld, true)
}

///|
test "visual projection keeps review work visible on the overworld" {
  let agent = build_visual_projection(
      visual_projection_test_state(
        worker_status=@core.WorkerStatus::Idle,
        execution_status=@core.TaskExecutionStatus::ReviewQueued,
      ),
    ).agents[0]
  assert_eq(agent.phase, "review")
  assert_eq(agent.behavior, "reviewing")
  assert_eq(agent.effect, "review-glow")
  assert_eq(agent.visible_on_overworld, true)
}

///|
test "visual projection summarizes book building activity" {
  let projection = build_visual_projection(visual_projection_test_state())
  assert_eq(projection.buildings.length(), 1)
  let building = projection.buildings[0]
  assert_eq(building.book_id, "research-opc")
  assert_eq(building.running_count, 1)
  assert_eq(building.review_count, 0)
  assert_eq(building.effect, "work-particles")
  assert_true(building.message.contains("active worker"))
}

///|
async test "town checkpoint persists visual projection beside snapshot" {
  let root = "/tmp/moontown-visual-projection-check"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  persist_town_checkpoint(visual_projection_test_state(), snapshot_path)
  let text = read_text_or_empty(default_visual_projection_path(snapshot_path))
  assert_true(text.contains("\"worker_id\":\"worker-opc-researcher\""))
  assert_true(text.contains("\"phase\":\"running\""))
  assert_true(text.contains("\"effect\":\"work-particles\""))
}
