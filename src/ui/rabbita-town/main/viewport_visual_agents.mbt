///|
fn visual_overworld_agents(model : Model) -> Array[VisualAgentSnapshot] {
  match model.visual_projection {
    Some(projection) =>
      projection.agents.filter(fn(agent) { agent.visible_on_overworld })
    None => []
  }
}

///|
fn energy_valley_runtime_agent_module(
  agent : EnergyValleyRuntimeAgent,
) -> WenyuTownModule? {
  match agent.buildingModuleKey {
    Some("vitality-tower") => find_wenyu_module("vitality-dashboard")
    Some("story-radar") => find_wenyu_module("broadcast-tower")
    Some(module_key) => find_wenyu_module(module_key)
    None => None
  }
}

///|
fn energy_valley_runtime_agent_status_class(
  agent : EnergyValleyRuntimeAgent,
) -> String {
  match agent.status {
    "running" | "assigned" => "worker-running"
    "waiting" => "worker-waiting"
    "blocked" => "worker-blocked"
    "offline" => "worker-offline"
    _ => "worker-idle"
  }
}

///|
fn render_energy_valley_agent_avatar(
  agent : EnergyValleyRuntimeAgent,
  index : Int,
) -> @rabbita.Html {
  let civic = match energy_valley_runtime_agent_module(agent) {
    Some(civic) => civic
    None => return span(class="runtime-agent-unlocated", no_children())
  }
  let grid_x = clamp_visual_grid_x(civic.entrance_x + index % 5 - 2)
  let grid_y = clamp_visual_grid_y(civic.entrance_y + index / 5 % 5 - 2)
  let delay = (index * 211 + grid_x * 17) % 2600
  let style = [
    "left: \{iso_tile_left(grid_x, grid_y) + 9}px",
    "top: \{iso_tile_top(grid_x, grid_y) - 31}px",
    "z-index: \{120 + grid_y}",
    "--wander-x1: \{worker_wander_x1(index + 3)}px",
    "--wander-y1: \{worker_wander_y1(index + 3)}px",
    "--wander-x2: \{worker_wander_x2(index + 5)}px",
    "--wander-y2: \{worker_wander_y2(index + 5)}px",
    "--wander-x3: \{worker_wander_x3(index + 7)}px",
    "--wander-y3: \{worker_wander_y3(index + 7)}px",
    "--wander-duration: \{5600 + index % 7 * 420}ms",
    "--wander-delay: -\{delay}ms",
    "--worker-image: url('\{worker_roster_asset(index)}')",
  ]
  div(
    class="worker-avatar visual-agent \{energy_valley_runtime_agent_status_class(agent)} worker-sprite-roster agent-phase-\{agent.status} agent-effect-review-glow",
    style~,
    title="\{agent.name} · \{agent.role} · \{agent.status} · \{agent.runId.unwrap_or("no run")}",
    [
      span(class="worker-sprite", no_children()),
      span(class="worker-badge", worker_avatar_initials(agent.name)),
      span(class="worker-label", agent.name),
      span(class="worker-meta", "\{agent.status} / \{civic.title}"),
    ],
  )
}

///|
fn visual_agent_sprite_asset(
  agent : VisualAgentSnapshot,
  index : Int,
) -> String {
  if agent.sprite_key == "" {
    worker_roster_asset(index)
  } else {
    "tilemap/actors/roster/\{agent.sprite_key}_walk_strip.png"
  }
}

///|
fn visual_agent_tooltip(agent : VisualAgentSnapshot) -> String {
  let task = match agent.task_title {
    Some(title) => title
    None =>
      match agent.task_id {
        Some(id) => id
        None => "no active task"
      }
  }
  let run = match agent.run_id {
    Some(id) => id
    None => "no run"
  }
  "\{agent.message} Task: \{task}; run: \{run}; zone: \{agent.zone_key}; route: \{agent.location} -> \{agent.destination}; effect: \{agent.effect}."
}

///|
fn render_visual_agent_avatar(
  dispatch : Dispatch[Msg],
  agent : VisualAgentSnapshot,
  index : Int,
  selected : Bool,
) -> @rabbita.Html {
  let grid_x = visual_agent_grid_x(agent)
  let grid_y = visual_agent_grid_y(agent)
  let delay = (index * 211 + agent.z * 17) % 2600
  let style = [
    "left: \{iso_tile_left(grid_x, grid_y) + 9}px",
    "top: \{iso_tile_top(grid_x, grid_y) - 31}px",
    "z-index: \{120 + agent.z}",
    "--wander-x1: \{worker_wander_x1(index + 3)}px",
    "--wander-y1: \{worker_wander_y1(index + 3)}px",
    "--wander-x2: \{worker_wander_x2(index + 5)}px",
    "--wander-y2: \{worker_wander_y2(index + 5)}px",
    "--wander-x3: \{worker_wander_x3(index + 7)}px",
    "--wander-y3: \{worker_wander_y3(index + 7)}px",
    "--wander-duration: \{5600 + index % 7 * 420}ms",
    "--wander-delay: -\{delay}ms",
    "--worker-image: url('\{visual_agent_sprite_asset(agent, index)}')",
  ]
  let class_name = "worker-avatar visual-agent \{visual_agent_status_class(agent)}" +
    " worker-sprite-roster" +
    " agent-phase-\{agent.phase}" +
    " agent-behavior-\{agent.behavior}" +
    " agent-effect-\{agent.effect}" +
    class_suffix_when(selected, " selected")
  button(
    class=class_name,
    style~,
    title=visual_agent_tooltip(agent),
    on_click=dispatch(SelectWorker(agent.worker_id)),
    [
      span(class="worker-sprite", no_children()),
      span(class="worker-badge", worker_avatar_initials(agent.worker_name)),
      span(class="worker-label", agent.worker_name),
      span(class="worker-meta", "\{agent.phase} / \{agent.book_title}"),
    ],
  )
}
