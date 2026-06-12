///|
fn talent_avenue_signal(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_projected_execution_signal_label(
    model.state_source,
    execution,
    talent_avenue_signal_phrases(),
    fallback="Graph warm",
  )
}

///|
fn talent_avenue_signal_phrases() -> CivicExecutionSignalPhrases {
  civic_signal_phrases(
    running="Heatmap refreshing",
    persisting="Tour note under review",
    review="Reception review queued",
    completed="Talent wall live",
  )
}

///|
fn talent_avenue_signal_class(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_module_signal_class(model, execution, running_is_live=false)
}

///|
fn talent_avenue_next_action(
  model : Model,
  task : @core.TownTask?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_execution_action_label(
    execution,
    talent_avenue_next_action_phrases(),
    fallback=talent_avenue_next_action_fallback(model, task),
  )
}

///|
fn talent_avenue_next_action_phrases() -> CivicExecutionActionPhrases {
  {
    packet: "Confirm dispatch and open the next showcase refresh for operators.",
    running: "Refresh achievements, evidence tags, and reception notes without leaking resident-private detail.",
    persisting: "Keep the VIP route note visible while MoonBook persists the reviewed reception summary.",
    review: "Clear the queued reception review before promoting the next public-safe card.",
    completed: "Publish the refreshed tour cards and export the next talent graph snapshot.",
    recovery: "Recover the stalled talent graph before the reception route goes stale.",
  }
}

///|
fn talent_avenue_next_action_fallback(
  model : Model,
  task : @core.TownTask?,
) -> String {
  civic_task_prompt_or_projected_fallback(
    model.state_source,
    task,
    projection_fallback="Bridge Talent Avenue to a persisted MoonBook projection before switching out of snapshot mode.",
    fallback="Keep the talent wall aligned with the next reception-ready projection.",
  )
}

///|
fn talent_avenue_stage(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_execution_stage_label(
    execution,
    talent_avenue_stage_phrases(),
    fallback=talent_avenue_stage_fallback(model),
  )
}

///|
fn talent_avenue_stage_phrases() -> CivicExecutionStagePhrases {
  {
    packet: "Showcase packet prepared",
    running: "Talent heatmap refresh",
    persisting: "Reception summary awaiting persistence",
    review: "Keeper review queued",
    completed: "Tour cards ready",
    recovery: "Recovery required",
  }
}

///|
fn talent_avenue_stage_fallback(model : Model) -> String {
  if model.tick % 4 < 2 {
    "Achievement broadcast refresh"
  } else {
    "VIP route planning"
  }
}
