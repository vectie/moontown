///|
fn contest_express_signal(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_projected_execution_signal_label(
    model.state_source,
    execution,
    contest_express_signal_phrases(),
    fallback="Readiness live",
  )
}

///|
fn contest_express_signal_phrases() -> CivicExecutionSignalPhrases {
  civic_signal_phrases(
    running="Mock judge live",
    persisting="Replay under review",
    review="Judge review queued",
    completed="Roadshow ready",
  )
}

///|
fn contest_express_signal_class(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_module_signal_class(model, execution, running_is_live=false)
}

///|
fn contest_express_next_action(
  model : Model,
  task : @core.TownTask?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  ignore(model)
  civic_execution_action_label(
    execution,
    contest_express_next_action_phrases(),
    fallback=contest_express_next_action_fallback(task),
  )
}

///|
fn contest_express_next_action_phrases() -> CivicExecutionActionPhrases {
  {
    packet: "Confirm dispatch and open the next contest-readiness step.",
    running: "Finish mock judging and turn weak sections into a revision packet.",
    persisting: "Keep the readiness score and replay link visible while MoonBook persists the reviewed packet.",
    review: "Route the mock-judge notes through keeper review before broadcasting the next reminder.",
    completed: "Publish the champion-wall summary, then schedule the next countdown checkpoint.",
    recovery: "Recover the stalled contest lane before the next roadshow countdown slips.",
  }
}

///|
fn contest_express_next_action_fallback(task : @core.TownTask?) -> String {
  civic_task_prompt_or_fallback(
    task,
    fallback="Open the contest calendar and score the next readiness gap.",
  )
}

///|
fn contest_express_stage(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_execution_stage_label(
    execution,
    contest_express_stage_phrases(),
    fallback=contest_express_stage_fallback(model),
  )
}

///|
fn contest_express_stage_phrases() -> CivicExecutionStagePhrases {
  {
    packet: "Readiness packet prepared",
    running: "Mock judge scoring",
    persisting: "Replay awaiting persistence",
    review: "Keeper review queued",
    completed: "Champion-wall ready",
    recovery: "Recovery required",
  }
}

///|
fn contest_express_stage_fallback(model : Model) -> String {
  if model.tick % 4 < 2 {
    "Deck gap review"
  } else {
    "Reminder schedule"
  }
}

///|
fn contest_express_countdown_label(model : Model) -> String {
  if model_projection_snapshot_ready(model) {
    "Projection-controlled"
  } else if model_projection_snapshot_waiting(model) {
    "Bridge waiting"
  } else {
    let days_left = 9 - model.tick % 5
    "T-\{days_left} days"
  }
}

///|
fn contest_express_readiness_label(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  let score = civic_execution_score(
    execution,
    contest_express_readiness_policy(),
    fallback=contest_express_readiness_fallback(model),
  )
  "\{score}% ready"
}

///|
fn contest_express_readiness_policy() -> CivicExecutionScorePolicy {
  {
    packet: 67,
    running: 74,
    persisting: 88,
    review: 58,
    completed: 96,
    recovery: 34,
  }
}

///|
fn contest_express_readiness_fallback(model : Model) -> Int {
  if model.state_source == StateSourceKind::SnapshotFile {
    46
  } else {
    79
  }
}

///|
fn contest_express_champion_label(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_projected_execution_stage_label(
    model.state_source,
    execution,
    contest_express_champion_phrases(),
    projection_fallback="Projection pending",
    fallback="Ready after next win",
  )
}

///|
fn contest_express_champion_phrases() -> CivicExecutionStagePhrases {
  {
    packet: "Champion wall draft",
    running: "Waiting on judge notes",
    persisting: "Summary persisting",
    review: "Review before broadcast",
    completed: "Replay queued",
    recovery: "Broadcast blocked",
  }
}
