///|
fn town_shell_signal(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_projected_execution_signal_label(
    model.state_source,
    execution,
    town_shell_signal_phrases(),
    fallback="Build queued",
  )
}

///|
fn town_shell_signal_phrases() -> CivicExecutionSignalPhrases {
  civic_signal_phrases(
    packet="Build dispatch",
    running="Build live",
    persisting="Patch awaiting persistence",
    review="Patch review queued",
    completed="Patch landed",
  )
}

///|
fn town_shell_signal_class(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_module_signal_class(model, execution, running_is_live=true)
}

///|
fn town_shell_next_action(
  model : Model,
  task : @core.TownTask?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_execution_action_label(
    execution,
    town_shell_next_action_phrases(),
    fallback=town_shell_next_action_fallback(model, task),
  )
}

///|
fn town_shell_next_action_phrases() -> CivicExecutionActionPhrases {
  {
    packet:
      "Confirm the patch dispatch and keep the lane visible in the town dashboard.",
    running:
      "Finish the focused UI slice and keep the shell readable while the build runs.",
    persisting:
      "Persist the validated patch and refresh the book's code-patch record.",
    review:
      "Clear the queued review so the Town Shell lane can return to live build status.",
    completed:
      "Roll the updated district card into the next runtime projection snapshot.",
    recovery:
      "Recover the stalled build run before the shell drifts back to placeholder state.",
  }
}

///|
fn town_shell_next_action_fallback(
  model : Model,
  task : @core.TownTask?,
) -> String {
  civic_task_prompt_or_projected_fallback(
    model.state_source,
    task,
    projection_fallback="Connect the persisted browser bridge so Town Shell reads live projection state.",
    fallback="Keep the live district card aligned with runtime projection data.",
  )
}

///|
fn town_shell_build_stage(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_execution_stage_label(
    execution,
    town_shell_build_stage_phrases(),
    fallback=town_shell_build_stage_fallback(model),
  )
}

///|
fn town_shell_build_stage_phrases() -> CivicExecutionStagePhrases {
  {
    packet: "Patch packet prepared",
    running: "Code patch running",
    persisting: "Patch awaiting persistence",
    review: "Keeper review queued",
    completed: "District card updated",
    recovery: "Recovery required",
  }
}

///|
fn town_shell_build_stage_fallback(model : Model) -> String {
  if model.tick % 4 < 2 {
    "Backlog materialized"
  } else {
    "Asset prompts queued"
  }
}
