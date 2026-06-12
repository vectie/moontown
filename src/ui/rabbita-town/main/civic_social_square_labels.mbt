///|
fn social_square_signal(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_projected_execution_signal_label(
    model.state_source,
    execution,
    social_square_signal_phrases(),
    fallback="Matchmaking",
  )
}

///|
fn social_square_signal_phrases() -> CivicExecutionSignalPhrases {
  civic_signal_phrases(
    packet="Match queued",
    running="Match live",
    persisting="Follow-up persisting",
    review="Review queued",
    completed="Follow-up landed",
  )
}

///|
fn social_square_signal_class(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_module_signal_class(model, execution, running_is_live=true)
}

///|
fn social_square_next_action(
  model : Model,
  task : @core.TownTask?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_execution_action_label(
    execution,
    social_square_next_action_phrases(),
    fallback=social_square_next_action_fallback(model, task),
  )
}

///|
fn social_square_next_action_phrases() -> CivicExecutionActionPhrases {
  {
    packet: "Confirm the dispatch so the reason and confidence stay visible in the town loop.",
    running: "Finish the cafe intro proposal with RSVP timing and a low-pressure follow-up.",
    persisting: "Persist the reviewed intro outcome and follow-up note into MoonBook social records.",
    review: "Clear the sensitive match review before the invite and reminder plan is sent.",
    completed: "Project the latest follow-up back into the district card and resident-safe memory handoff.",
    recovery: "Recover the stalled introduction run before the context for this weak tie goes cold.",
  }
}

///|
fn social_square_next_action_fallback(
  model : Model,
  task : @core.TownTask?,
) -> String {
  civic_task_prompt_or_projected_fallback(
    model.state_source,
    task,
    projection_fallback="Load projected social records so the district stops relying on demo-only matches.",
    fallback="Keep the district card aligned with reviewed matches, event plans, and follow-up memory.",
  )
}

///|
fn social_square_stage(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_projected_execution_stage_label(
    model.state_source,
    execution,
    social_square_stage_phrases(),
    projection_fallback="Projection bridge pending",
    fallback="Reasoned introductions",
  )
}

///|
fn social_square_stage_phrases() -> CivicExecutionStagePhrases {
  {
    packet: "Match dispatch",
    running: "RSVP plan in flight",
    persisting: "MoonBook follow-up persistence",
    review: "Sensitive match review",
    completed: "Follow-up recorded",
    recovery: "Recovery required",
  }
}

///|
fn social_square_pair_label(match_item : SocialMatchSim) -> String {
  "\{match_item.left} x \{match_item.right}"
}
