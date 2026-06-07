///|
fn vitality_dashboard_signal(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  if mayor_recovery_active(model) &&
    model.state_source != StateSourceKind::SnapshotFile {
    "Recovery loop"
  } else {
    civic_projected_execution_signal_label(
      model.state_source,
      execution,
      vitality_dashboard_signal_phrases(),
      fallback="Pulse active",
    )
  }
}

///|
fn vitality_dashboard_signal_phrases() -> CivicExecutionSignalPhrases {
  {
    packet: "Sync queued",
    running: "Pulse syncing",
    persisting: "Pulse persisting",
    review: "Pulse review",
    completed: "Pulse live",
    recovery: "Needs recovery",
  }
}

///|
fn vitality_dashboard_signal_class(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  if mayor_recovery_active(model) &&
    model.state_source != StateSourceKind::SnapshotFile {
    "module-signal-alert"
  } else {
    civic_module_signal_class(model, execution, running_is_live=true)
  }
}

///|
fn vitality_dashboard_next_action(
  model : Model,
  task : @core.TownTask?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_execution_action_label(
    execution,
    vitality_dashboard_next_action_phrases(),
    fallback=vitality_dashboard_next_action_fallback(model, task),
  )
}

///|
fn vitality_dashboard_next_action_phrases() -> CivicExecutionActionPhrases {
  {
    packet: "Confirm the code-patch dispatch and keep the vitality lane visible in the town square.",
    running: "Finish the UI slice while keeping queue pressure, health, and next action legible.",
    persisting: "Persist the validated vitality slice so Moontown can project it beyond demo simulation.",
    review: "Clear keeper review and keep the district pulse visible while MoonBook absorbs the record.",
    completed: "Wire the next projection snapshot so joins, quests, and retention stop depending on local simulation.",
    recovery: "Recover the stalled vitality run before the district pulse drifts out of sync.",
  }
}

///|
fn vitality_dashboard_next_action_fallback(
  model : Model,
  task : @core.TownTask?,
) -> String {
  civic_task_prompt_or_projected_fallback(
    model.state_source,
    task,
    projection_fallback="Connect the projection bridge so the vitality lane reads persisted town state.",
    fallback="Keep the district pulse aligned with Moontown projection, MoonBook counters, and MoonClaw events.",
  )
}
