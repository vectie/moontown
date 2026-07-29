///|
fn golden_valley_building_module_key(building : GoldenValleyBuilding) -> String {
  match building.module_key {
    Some(key) => return key
    None => ()
  }
  match building.name {
    "市政厅" => "town-shell"
    "活力塔" => "vitality-tower"
    "政策大厅" => "policy-hall"
    "众创大厅" => "contest-express"
    "故事雷达" => "story-radar"
    "居民双子楼" => "resident-twins"
    "AI科学花园" => "ai-garden"
    "社交广场" => "social-square"
    "实验室" => "energy-lab"
    "人才大道" => "talent-avenue"
    "山谷市集" => "valley-market"
    "人才公寓" => "talent-flat"
    _ => ""
  }
}

///|
fn golden_valley_building_civic_id(building : GoldenValleyBuilding) -> String {
  match golden_valley_building_module_key(building) {
    "vitality-tower" => "vitality-dashboard"
    "story-radar" => "broadcast-tower"
    key => key
  }
}

///|
fn golden_valley_runtime_tasks_for_building(
  state : EnergyValleyRuntimeState,
  building : GoldenValleyBuilding,
) -> Array[EnergyValleyRuntimeWorkItem] {
  let key = golden_valley_building_module_key(building)
  if key.is_empty() {
    return []
  }
  match state.projection {
    Some(projection) =>
      projection.tasks.filter(task => task.buildingModuleKey == key)
    None => []
  }
}

///|
fn golden_valley_runtime_agents_for_building(
  state : EnergyValleyRuntimeState,
  building : GoldenValleyBuilding,
) -> Array[EnergyValleyRuntimeAgent] {
  let key = golden_valley_building_module_key(building)
  if key.is_empty() {
    return []
  }
  energy_valley_runtime_active_agents(state).filter(agent => {
    agent.buildingModuleKey.unwrap_or("") == key
  })
}

///|
fn golden_valley_runtime_known_agents_for_building(
  state : EnergyValleyRuntimeState,
  building : GoldenValleyBuilding,
) -> Array[EnergyValleyRuntimeAgent] {
  let key = golden_valley_building_module_key(building)
  if key.is_empty() {
    return []
  }
  match state.projection {
    Some(projection) =>
      projection.agents.filter(agent => {
        agent.buildingModuleKey.unwrap_or("") == key
      })
    None => []
  }
}

///|
fn golden_valley_building_for_runtime_key(
  buildings : Array[GoldenValleyBuilding],
  key : String,
) -> GoldenValleyBuilding? {
  for building in buildings {
    if golden_valley_building_module_key(building) == key {
      return Some(building)
    }
  }
  None
}

///|
fn golden_valley_work_status_color(status : String) -> String {
  match status {
    "running" => "#6ee7b7"
    "waiting_review" => "#fcd34d"
    "blocked" => "#fdba74"
    "failed" => "#fda4af"
    "completed" => "#86efac"
    "assigned" => "#7dd3fc"
    _ => "#94a3b8"
  }
}

///|
fn golden_valley_primary_building_status(
  tasks : Array[EnergyValleyRuntimeWorkItem],
) -> String {
  for
    status in [
      "running", "waiting_review", "blocked", "assigned", "queued", "failed", "completed",
    ] {
    if tasks.any(task => task.status == status) {
      return status
    }
  }
  ""
}

///|
fn golden_valley_runtime_agent_work_status(
  state : EnergyValleyRuntimeState,
  agent : EnergyValleyRuntimeAgent,
) -> String {
  match agent.workItemId {
    Some(work_item_id) =>
      match state.projection {
        Some(projection) => {
          for task in projection.tasks {
            if task.id == work_item_id {
              return task.status
            }
          }
          agent.status
        }
        None => agent.status
      }
    None => agent.status
  }
}
