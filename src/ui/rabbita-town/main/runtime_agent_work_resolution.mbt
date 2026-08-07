///|
/// Rank work states only for the final legacy fallback where a projection has
/// neither an explicit workItemId nor an exact Run ID match. Active/review
/// records outrank terminal history; timestamps and ids make ties stable.
fn energy_valley_runtime_task_resolution_rank(status : String) -> Int {
  match status {
    "running" | "assigned" | "waiting_review" | "reviewing" => 3
    "queued" | "waiting" => 2
    "blocked" | "failed" => 1
    _ => 0
  }
}

///|
fn energy_valley_runtime_task_resolution_key(
  task : EnergyValleyRuntimeWorkItem,
) -> String {
  "\{task.updatedAt.unwrap_or("")}\{task.id}"
}

///|
/// Canonical Agent -> work-item resolution shared by movement, profiles,
/// phone handoff, and the town chronicle. New projections should always carry
/// workItemId; the remaining branches preserve older durable projections
/// without choosing an arbitrary first task for a long-lived Agent.
fn energy_valley_runtime_task_for_agent_in_projection(
  projection : EnergyValleyRuntimeProjection,
  agent : EnergyValleyRuntimeAgent,
) -> EnergyValleyRuntimeWorkItem? {
  match agent.workItemId {
    Some(work_item_id) =>
      for task in projection.tasks {
        if task.id == work_item_id {
          return Some(task)
        }
      }
    None => ()
  }
  match agent.runId {
    Some(run_id) if !run_id.is_empty() => {
      for task in projection.tasks {
        if task.runId == Some(run_id) {
          return Some(task)
        }
      }
      for task in projection.tasks {
        match task.collaboration {
          Some(collaboration) =>
            if collaboration.participants.any(participant => {
                participant.runId == run_id
              }) {
              return Some(task)
            }
          None => ()
        }
      }
    }
    _ => ()
  }
  let mut selected : EnergyValleyRuntimeWorkItem? = None
  for task in projection.tasks {
    if task.agentId != Some(agent.id) {
      continue
    }
    match selected {
      None => selected = Some(task)
      Some(current) => {
        let rank = energy_valley_runtime_task_resolution_rank(task.status)
        let current_rank = energy_valley_runtime_task_resolution_rank(
          current.status,
        )
        if rank > current_rank ||
          (
            rank == current_rank &&
            energy_valley_runtime_task_resolution_key(task).compare(
              energy_valley_runtime_task_resolution_key(current),
            ) >
            0
          ) {
          selected = Some(task)
        }
      }
    }
  }
  selected
}

///|
fn energy_valley_runtime_task_for_agent(
  state : EnergyValleyRuntimeState,
  agent : EnergyValleyRuntimeAgent,
) -> EnergyValleyRuntimeWorkItem? {
  match state.projection {
    Some(projection) =>
      energy_valley_runtime_task_for_agent_in_projection(projection, agent)
    None => None
  }
}

///|
/// Work states that still represent a current assignment. Terminal history is
/// never enough evidence to put an Agent on the live map or in a place ledger.
fn energy_valley_runtime_task_status_is_active(status : String) -> Bool {
  match status.to_lower() {
    "queued"
    | "assigned"
    | "running"
    | "waiting"
    | "waiting_review"
    | "reviewing"
    | "blocked" => true
    _ => false
  }
}

///|
fn energy_valley_runtime_canonical_building_key(key : String) -> String {
  match key {
    "vitality-dashboard" => "vitality-tower"
    "broadcast-tower" => "story-radar"
    other => other
  }
}

///|
fn energy_valley_runtime_building_keys_match(
  left : String,
  right : String,
) -> Bool {
  !left.trim().is_empty() &&
  !right.trim().is_empty() &&
  energy_valley_runtime_canonical_building_key(left) ==
  energy_valley_runtime_canonical_building_key(right)
}

///|
/// Confirms that the Agent's claimed building participates in the resolved
/// work item's route or destination. The task's semantic civic id keeps legacy
/// `energy-lab` work linked to its authored research building.
fn energy_valley_runtime_agent_building_matches_task(
  agent : EnergyValleyRuntimeAgent,
  task : EnergyValleyRuntimeWorkItem,
) -> Bool {
  let building = agent.buildingModuleKey.unwrap_or("")
  if building.trim().is_empty() {
    return false
  }
  if energy_valley_runtime_building_keys_match(building, task.buildingModuleKey) ||
    energy_valley_runtime_building_keys_match(
      building,
      energy_valley_runtime_task_civic_id(task),
    ) {
    return true
  }
  for
    candidate in [
      task.originBuildingModuleKey,
      task.destinationBuildingModuleKey,
    ] {
    match candidate {
      Some(key) if energy_valley_runtime_building_keys_match(building, key) =>
        return true
      _ => ()
    }
  }
  false
}

///|
/// Single evidence gate shared by canvas rendering, map hit testing and the
/// authoritative TownSnapshot. A projection row is not a live resident unless
/// the runtime is live, the Agent is active, and a current linked work item
/// places that Agent on a valid building route.
fn energy_valley_runtime_active_task_for_agent(
  state : EnergyValleyRuntimeState,
  agent : EnergyValleyRuntimeAgent,
) -> EnergyValleyRuntimeWorkItem? {
  if !energy_valley_runtime_can_claim_active_work(state) ||
    agent.status == "idle" ||
    agent.status == "offline" {
    return None
  }
  match energy_valley_runtime_task_for_agent(state, agent) {
    Some(task) if energy_valley_runtime_task_status_is_active(task.status) &&
      energy_valley_runtime_agent_building_matches_task(agent, task) =>
      Some(task)
    _ => None
  }
}
