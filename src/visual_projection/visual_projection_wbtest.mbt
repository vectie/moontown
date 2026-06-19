///|
fn visual_projection_test_state(
  worker_status? : @core.WorkerStatus = Running,
  execution_status? : @core.TaskExecutionStatus = Running,
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
      role=Watcher,
      status=worker_status,
    ),
  )
  state.enqueue_task(
    @core.TownTask::new(
      id="task-opc-watch",
      book_id="research-opc",
      title="Check OPC updates",
      prompt="Find new OPC sources.",
      domain=Research,
      status=Running,
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
test "visual projection path uses storage snapshot base" {
  assert_eq(
    default_visual_projection_path("town.json"),
    ".moontown/visual-projection.json",
  )
  assert_eq(
    default_visual_projection_path("/tmp/moontown/town.json"),
    "/tmp/moontown/visual-projection.json",
  )
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
  assert_true(agent.task_id == Some("task-opc-watch"))
  assert_true(agent.task_title == Some("Check OPC updates"))
  assert_true(agent.run_id == Some("run-opc-watch"))
  assert_eq(agent.effect, "work-particles")
  assert_eq(agent.behavior, "working")
  assert_eq(agent.visible_on_overworld, true)
  assert_true(agent.sprite_key.contains("resident_"))
  assert_true(agent.message.contains("actively working"))
}

///|
test "visual phase taxonomy drives routing visibility and effects" {
  assert_true(visual_phase_is_handoff("packet"))
  assert_true(visual_phase_is_handoff("importing"))
  assert_true(!visual_phase_is_handoff("running"))
  assert_true(visual_phase_is_working("running"))
  assert_true(!visual_phase_is_working("persisting"))
  assert_true(visual_phase_is_keeper_bound("persisting"))
  assert_true(visual_phase_is_keeper_bound("review"))
  assert_true(visual_phase_is_recovery("failed"))
  assert_true(visual_phase_is_recovery("stale"))
  assert_true(visual_phase_is_recovery("blocked"))
  assert_true(visual_phase_is_completed_or_idle("completed"))
  assert_true(visual_phase_is_completed_or_idle("idle"))
  assert_true(visual_agent_visible_on_overworld("packet"))
  assert_true(visual_agent_visible_on_overworld("review"))
  assert_true(!visual_agent_visible_on_overworld("completed"))
  assert_eq(visual_location_label("research-opc", "packet"), "city-hall")
  assert_eq(
    visual_destination_label("research-opc", "review"),
    "keeper-desk-research-opc",
  )
  assert_eq(visual_effect_for_phase("blocked"), "alert-pulse")
}

///|
test "visual projection hides completed and idle workers inside buildings" {
  let agent = build_visual_projection(
      visual_projection_test_state(
        worker_status=Idle,
        execution_status=Completed,
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
      visual_projection_test_state(execution_status=Failed),
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
        worker_status=Idle,
        execution_status=ReviewQueued,
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
test "visual building activity owns effect status and message priority" {
  let activity : VisualBuildingActivity = {
    running_count: 2,
    waiting_count: 1,
    review_count: 1,
    blocked_count: 1,
    completed_count: 3,
  }
  let book = @core.BookRef::new(
    id="research-opc",
    name="One Person Company Research",
    purpose="Track OPC changes",
    workspace_root="/tmp/research-opc",
  )
  assert_eq(activity.effect(), "alert-pulse")
  assert_eq(activity.module_status(), "alert")
  assert_true(activity.message(book).contains("needs recovery"))
}

///|
test "visual projection emits module status from book runtime" {
  let projection = build_visual_projection(visual_projection_test_state())
  assert_eq(projection.modules.length(), 1)
  let module_status = projection.modules[0]
  assert_eq(module_status.module_id, "research-opc")
  assert_eq(module_status.book_id, "research-opc")
  assert_eq(module_status.status, "running")
  assert_eq(module_status.source, "runtime")
  assert_eq(module_status.running_count, 1)
  assert_eq(module_status.active_agent_count, 1)
  assert_eq(module_status.effect, "work-particles")
}

///|
test "visual projection strips wenyu prefix for module ids" {
  assert_eq(visual_module_id_from_book_id("wenyu-policy-hall"), "policy-hall")
  assert_eq(visual_module_id_from_book_id("research-opc"), "research-opc")
}
