///|
fn visual_policy_test_agent(
  status? : String = "",
  phase? : String = "idle",
  book_id? : String = "unknown-book",
  grid_x? : Int = 12,
  grid_y? : Int = 18,
  z? : Int = 0,
) -> VisualAgentSnapshot {
  {
    worker_id: "worker",
    worker_name: "Worker",
    book_id,
    book_title: "Book",
    role: "role",
    status,
    phase,
    task_id: None,
    task_title: None,
    run_id: None,
    sprite_key: "",
    zone_key: "zone",
    location: "home",
    destination: "target",
    behavior: "walk",
    effect: "none",
    visible_on_overworld: true,
    message: "message",
    grid_x,
    grid_y,
    z,
  }
}

///|
test "visual phase policy groups handoff route and recovery states" {
  assert_true(viewport_visual_phase_is_handoff("packet"))
  assert_true(viewport_visual_phase_is_handoff("importing"))
  assert_true(viewport_visual_phase_routes_to_module("running"))
  assert_true(viewport_visual_phase_routes_to_module("persisting"))
  assert_true(viewport_visual_phase_routes_to_module("review"))
  assert_true(viewport_visual_phase_is_recovery("failed"))
  assert_true(viewport_visual_phase_is_recovery("stale"))
  assert_true(viewport_visual_phase_is_recovery("blocked"))
  assert_true(viewport_visual_phase_is_active_for_module("running"))
  assert_true(viewport_visual_phase_is_active_for_module("failed"))
  assert_true(!viewport_visual_phase_is_active_for_module("idle"))
}

///|
test "visual agent status class falls back to phase policy" {
  assert_eq(
    visual_agent_status_class(visual_policy_test_agent(status="running")),
    "worker-running",
  )
  assert_eq(
    visual_agent_status_class(visual_policy_test_agent(phase="blocked")),
    "worker-blocked",
  )
  assert_eq(
    visual_agent_status_class(visual_policy_test_agent(phase="running")),
    "worker-running",
  )
  assert_eq(
    visual_agent_status_class(visual_policy_test_agent(phase="packet")),
    "worker-waiting",
  )
  assert_eq(
    visual_agent_status_class(visual_policy_test_agent(phase="quiet")),
    "worker-idle",
  )
}

///|
test "visual grid policy clamps unknown module positions" {
  let low = visual_policy_test_agent(grid_x=-3, grid_y=-2)
  assert_eq(visual_agent_grid_x(low), 0)
  assert_eq(visual_agent_grid_y(low), 0)
  let high = visual_policy_test_agent(grid_x=300, grid_y=180)
  assert_eq(visual_agent_grid_x(high), 255)
  assert_eq(visual_agent_grid_y(high), 143)
}
