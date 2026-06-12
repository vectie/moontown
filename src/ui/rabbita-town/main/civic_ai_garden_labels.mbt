///|
fn ai_garden_signal(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_projected_execution_signal_label(
    model.state_source,
    execution,
    ai_garden_signal_phrases(),
    fallback="Learning live",
  )
}

///|
fn ai_garden_signal_phrases() -> CivicExecutionSignalPhrases {
  civic_signal_phrases(
    running="Tool trial live",
    persisting="Tutorial under review",
    review="Keeper review queued",
    completed="Lesson published",
  )
}

///|
fn ai_garden_signal_class(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_module_signal_class(model, execution, running_is_live=false)
}

///|
fn ai_garden_next_action(
  model : Model,
  task : @core.TownTask?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_execution_action_label(
    execution,
    ai_garden_next_action_phrases(),
    fallback=ai_garden_next_action_fallback(model, task),
  )
}

///|
fn ai_garden_next_action_phrases() -> CivicExecutionActionPhrases {
  {
    packet: "Confirm dispatch and open the next AI adoption quest.",
    running: "Finish the guided tool trial and keep the five-minute lesson visible to residents.",
    persisting: "Persist the reviewed tutorial page and refresh the district-facing learning snapshot.",
    review: "Resolve keeper review before promoting the next public-safe tool trial.",
    completed: "Queue the next resident scenario and compare before-and-after output in town view.",
    recovery: "Recover the stalled tutorial run before the daily learning loop drifts.",
  }
}

///|
fn ai_garden_next_action_fallback(
  model : Model,
  task : @core.TownTask?,
) -> String {
  civic_task_prompt_or_projected_fallback(
    model.state_source,
    task,
    projection_fallback="Connect MoonBook learning projections so the district stops relying on synthetic examples.",
    fallback="Keep AI Garden visible as a practical on-ramp to resident AI adoption.",
  )
}

///|
fn ai_garden_stage(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_execution_stage_label(
    execution,
    ai_garden_stage_phrases(),
    fallback=ai_garden_stage_fallback(model),
  )
}

///|
fn ai_garden_stage_phrases() -> CivicExecutionStagePhrases {
  {
    packet: "Tool trial packet prepared",
    running: "Tutorial quest running",
    persisting: "Tutorial awaiting persistence",
    review: "Keeper review queued",
    completed: "Daily lesson published",
    recovery: "Recovery required",
  }
}

///|
fn ai_garden_stage_fallback(model : Model) -> String {
  if model.tick % 4 < 2 {
    "Scenario drafting"
  } else {
    "Workshop rotation"
  }
}

///|
fn ai_garden_tool_trial_label(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_projected_execution_stage_label(
    model.state_source,
    execution,
    ai_garden_tool_trial_phrases(),
    projection_fallback="Projection lesson pending",
    fallback="Client email tool trial",
  )
}

///|
fn ai_garden_tool_trial_phrases() -> CivicExecutionStagePhrases {
  {
    packet: "Scenario packet staged",
    running: "Email draft comparison live",
    persisting: "Reviewed lesson waiting for persist",
    review: "Comparison draft in keeper review",
    completed: "Before/after lesson published",
    recovery: "Tool trial recovery required",
  }
}

///|
fn ai_garden_workshop_label(model : Model) -> String {
  if model_projection_snapshot_waiting(model) {
    "Projection workshop waiting"
  } else {
    match model.tick % 3 {
      0 => "Creator workshop live"
      1 => "Template remix circle"
      _ => "Five-minute tutorial clinic"
    }
  }
}

///|
fn ai_garden_comparison_label(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_projected_execution_stage_label(
    model.state_source,
    execution,
    ai_garden_comparison_phrases(),
    projection_fallback="Projection proof pending",
    fallback="Before/after proof loop",
  )
}

///|
fn ai_garden_comparison_phrases() -> CivicExecutionStagePhrases {
  {
    packet: "Comparison prompt staged",
    running: "Live before/after capture",
    persisting: "Comparison proof persisting",
    review: "Comparison proof under review",
    completed: "Comparison proof published",
    recovery: "Comparison proof blocked",
  }
}
