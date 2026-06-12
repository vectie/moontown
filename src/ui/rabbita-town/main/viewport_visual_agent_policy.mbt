///|
fn visual_agent_status_class(agent : VisualAgentSnapshot) -> String {
  match agent.status {
    "running" => "worker-running"
    "waiting" => "worker-waiting"
    "idle" => "worker-idle"
    "blocked" => "worker-blocked"
    "offline" => "worker-offline"
    _ =>
      if viewport_visual_phase_is_recovery(agent.phase) {
        "worker-blocked"
      } else if viewport_visual_phase_routes_to_module(agent.phase) {
        "worker-running"
      } else if viewport_visual_phase_is_handoff(agent.phase) {
        "worker-waiting"
      } else {
        "worker-idle"
      }
  }
}

///|
fn visual_agent_grid_x(agent : VisualAgentSnapshot) -> Int {
  match visual_agent_target_module(agent) {
    Some(civic) =>
      if visual_agent_should_route_to_module(agent) {
        clamp_visual_grid_x(civic.entrance_x + agent.z % 5 - 2)
      } else {
        clamp_visual_grid_x(agent.grid_x)
      }
    None => clamp_visual_grid_x(agent.grid_x)
  }
}

///|
fn visual_agent_grid_y(agent : VisualAgentSnapshot) -> Int {
  match visual_agent_target_module(agent) {
    Some(civic) =>
      if visual_agent_should_route_to_module(agent) {
        clamp_visual_grid_y(civic.entrance_y + agent.z / 5 % 5 - 2)
      } else {
        clamp_visual_grid_y(agent.grid_y)
      }
    None => clamp_visual_grid_y(agent.grid_y)
  }
}

///|
fn visual_agent_target_module(agent : VisualAgentSnapshot) -> WenyuTownModule? {
  find_module_for_book(agent.book_id)
}

///|
fn visual_agent_should_route_to_module(agent : VisualAgentSnapshot) -> Bool {
  viewport_visual_phase_routes_to_module(agent.phase)
}

///|
fn viewport_visual_phase_is_handoff(phase : String) -> Bool {
  phase == "packet" || phase == "importing"
}

///|
fn viewport_visual_phase_is_recovery(phase : String) -> Bool {
  phase == "failed" || phase == "stale" || phase == "blocked"
}

///|
fn viewport_visual_phase_routes_to_module(phase : String) -> Bool {
  phase == "running" || phase == "persisting" || phase == "review"
}

///|
fn viewport_visual_phase_is_active_for_module(phase : String) -> Bool {
  viewport_visual_phase_routes_to_module(phase) ||
  viewport_visual_phase_is_recovery(phase)
}

///|
fn clamp_visual_grid_x(value : Int) -> Int {
  if value < 0 {
    0
  } else if value > 255 {
    255
  } else {
    value
  }
}

///|
fn clamp_visual_grid_y(value : Int) -> Int {
  if value < 0 {
    0
  } else if value > 143 {
    143
  } else {
    value
  }
}
