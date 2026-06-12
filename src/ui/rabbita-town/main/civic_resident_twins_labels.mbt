///|
fn resident_twins_signal(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_projected_execution_signal_label(
    model.state_source,
    execution,
    resident_twins_signal_phrases(),
    fallback="Twin queued",
  )
}

///|
fn resident_twins_signal_phrases() -> CivicExecutionSignalPhrases {
  {
    packet: "Twin dispatch",
    running: "Reflection running",
    persisting: "Memory awaiting persistence",
    review: "Needs review",
    completed: "Twin live",
    recovery: "Recovery required",
  }
}

///|
fn resident_twins_signal_class(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_module_signal_class(model, execution, running_is_live=true)
}

///|
fn resident_twins_next_action(
  model : Model,
  task : @core.TownTask?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_execution_action_label(
    execution,
    resident_twins_next_action_phrases(),
    fallback=resident_twins_next_action_fallback(model, task),
  )
}

///|
fn resident_twins_next_action_phrases() -> CivicExecutionActionPhrases {
  {
    packet: "Confirm the district patch dispatch and keep resident memory projection-safe.",
    running: "Finish the current reflection cycle and keep the next resident plan visible.",
    persisting: "Persist the reviewed resident summary and refresh the projection-safe handoff.",
    review: "Clear keeper review before exposing the next reflection summary in town view.",
    completed: "Publish the updated resident lane into the next runtime projection snapshot.",
    recovery: "Recover the stalled resident lane before memory and plan cards drift.",
  }
}

///|
fn resident_twins_next_action_fallback(
  model : Model,
  task : @core.TownTask?,
) -> String {
  civic_task_prompt_or_fallback(
    task,
    fallback=resident_twins_resident_plan(model),
  )
}

///|
fn resident_twins_build_stage(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_execution_stage_label(
    execution,
    resident_twins_build_stage_phrases(),
    fallback=resident_twins_build_stage_fallback(model),
  )
}

///|
fn resident_twins_build_stage_phrases() -> CivicExecutionStagePhrases {
  {
    packet: "Patch packet prepared",
    running: "Reflection loop running",
    persisting: "Memory awaiting persistence",
    review: "Keeper review queued",
    completed: "Projection updated",
    recovery: "Recovery required",
  }
}

///|
fn resident_twins_build_stage_fallback(model : Model) -> String {
  if model.tick % 4 < 2 {
    "Projection wiring queued"
  } else {
    "Review loop visible"
  }
}
