///|
fn physical_bridge_signal(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_projected_execution_signal_label(
    model.state_source,
    execution,
    physical_bridge_signal_phrases(),
    fallback="Bridge staged",
  )
}

///|
fn physical_bridge_signal_phrases() -> CivicExecutionSignalPhrases {
  civic_signal_phrases(
    packet="Sync dispatch",
    running="Bridge sync live",
    persisting="Telemetry awaiting persistence",
    review="Bridge review queued",
    completed="District link live",
  )
}

///|
fn physical_bridge_signal_class(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_module_signal_class(model, execution, running_is_live=true)
}

///|
fn physical_bridge_next_action(
  model : Model,
  task : @core.TownTask?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_execution_action_label(
    execution,
    physical_bridge_next_action_phrases(),
    fallback=physical_bridge_next_action_fallback(model, task),
  )
}

///|
fn physical_bridge_next_action_phrases() -> CivicExecutionActionPhrases {
  {
    packet: "Confirm dispatch and open the next virtual-to-physical handoff.",
    running: "Finish the room-and-robot sync and keep next action legible for the mayor loop.",
    persisting: "Persist the reviewed telemetry and booking slice so Moontown can project a trustworthy district state.",
    review: "Clear keeper review before exposing proxy attendance or room status beyond projection-safe summaries.",
    completed: "Refresh the town tile with the latest room, robot, and telemetry counters instead of the generic bridge placeholder.",
    recovery: "Recover the stalled bridge run before offline status drifts away from the visible town.",
  }
}

///|
fn physical_bridge_next_action_fallback(
  model : Model,
  task : @core.TownTask?,
) -> String {
  civic_task_prompt_or_projected_fallback(
    model.state_source,
    task,
    projection_fallback="Connect the projection bridge so Physical Bridge stops relying on demo-only telemetry.",
    fallback="Keep robot calls, room holds, and district telemetry visible without leaking private execution state.",
  )
}

///|
fn physical_bridge_stage(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_projected_execution_stage_label(
    model.state_source,
    execution,
    physical_bridge_stage_phrases(),
    projection_fallback="Projection bridge pending",
    fallback=physical_bridge_stage_fallback(model),
  )
}

///|
fn physical_bridge_stage_phrases() -> CivicExecutionStagePhrases {
  {
    packet: "Bridge packet prepared",
    running: "Room and robot sync running",
    persisting: "Telemetry awaiting persistence",
    review: "Projection review queued",
    completed: "District tile ready",
    recovery: "Recovery required",
  }
}

///|
fn physical_bridge_stage_fallback(model : Model) -> String {
  if mayor_recovery_active(model) {
    "Recovery patrol handoff"
  } else {
    "Live district sync"
  }
}

///|
fn physical_bridge_handoff_label(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_projected_execution_stage_label(
    model.state_source,
    execution,
    physical_bridge_handoff_phrases(),
    projection_fallback="Projection-safe room and robot feed",
    fallback="Warm handoff between venue, robot, and telemetry lanes",
  )
}

///|
fn physical_bridge_handoff_phrases() -> CivicExecutionStagePhrases {
  {
    packet: "Mayor dispatch opened for bridge run",
    running: "Room hold and robot sync in motion",
    persisting: "Telemetry and booking slice persisting",
    review: "Proxy attendance waiting for keeper review",
    completed: "Room, robot, and proxy counters ready",
    recovery: "Offline bridge handoff stalled",
  }
}
