///|
fn policy_hall_signal(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_execution_signal_label(
    execution,
    policy_hall_signal_phrases(),
    fallback=policy_hall_signal_fallback(model),
  )
}

///|
fn policy_hall_signal_phrases() -> CivicExecutionSignalPhrases {
  civic_signal_phrases(
    running="Quest live",
    persisting="Checklist under review",
    review="Escalated",
    completed="Checklist ready",
  )
}

///|
fn policy_hall_signal_fallback(model : Model) -> String {
  if model.state_source == StateSourceKind::SnapshotFile {
    "Projection bridge pending"
  } else {
    "Quest-ready"
  }
}

///|
fn policy_hall_signal_class(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_module_signal_class(model, execution, running_is_live=true)
}

///|
fn policy_hall_next_action(
  model : Model,
  task : @core.TownTask?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_execution_action_label(
    execution,
    policy_hall_next_action_phrases(),
    fallback=policy_hall_next_action_fallback(model, task),
  )
}

///|
fn policy_hall_next_action_phrases() -> CivicExecutionActionPhrases {
  {
    packet: "Confirm dispatch and open the first policy quest step.",
    running: "Finish the current clause walkthrough and prepare the checklist.",
    persisting: "Keep the checklist visible while MoonBook persists reviewed output.",
    review: "Escalate the low-confidence answer for keeper review before publishing.",
    completed: "Hand the resident a reviewed checklist and packet summary.",
    recovery: "Recover the stalled run and replay the eligibility step.",
  }
}

///|
fn policy_hall_next_action_fallback(
  model : Model,
  task : @core.TownTask?,
) -> String {
  civic_task_prompt_or_projected_fallback(
    model.state_source,
    task,
    projection_fallback="Bridge the Policy Hall book projection so confidence, checklist readiness, and reviewed citations stop falling back to demo state.",
    fallback=resident_twins_resident_plan(model),
  )
}

///|
fn policy_hall_quest_stage(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_execution_stage_label(
    execution,
    policy_hall_quest_stage_phrases(),
    fallback=policy_hall_quest_stage_fallback(model),
  )
}

///|
fn policy_hall_quest_stage_phrases() -> CivicExecutionStagePhrases {
  {
    packet: "Packet prepared",
    running: "Advisor interpreting",
    persisting: "Checklist awaiting persistence",
    review: "Keeper review queued",
    completed: "Checklist ready",
    recovery: "Recovery required",
  }
}

///|
fn policy_hall_quest_stage_fallback(model : Model) -> String {
  if model.state_source == StateSourceKind::SnapshotFile {
    "Projection bridge pending"
  } else if model.tick % 4 < 2 {
    "Advisor interpreting"
  } else {
    "Checklist ready"
  }
}

///|
fn policy_hall_checklist_label(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_projected_execution_stage_label(
    model.state_source,
    execution,
    policy_hall_checklist_phrases(),
    projection_fallback="Waiting for projection",
    fallback="Demo quest ready",
  )
}

///|
fn policy_hall_checklist_phrases() -> CivicExecutionStagePhrases {
  {
    packet: "Packet staged",
    running: "Drafting checklist",
    persisting: "Keeper persistence pending",
    review: "Escalated for review",
    completed: "Ready for resident handoff",
    recovery: "Recovery required",
  }
}

///|
fn policy_hall_evidence_label(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  civic_projected_execution_stage_label(
    model.state_source,
    execution,
    policy_hall_evidence_phrases(),
    projection_fallback="Snapshot not wired yet",
    fallback="Demo citations assumed",
  )
}

///|
fn policy_hall_evidence_phrases() -> CivicExecutionStagePhrases {
  {
    packet: "Evidence packet staged",
    running: "Clause scan in flight",
    persisting: "Citations queued for persist",
    review: "Low-confidence review",
    completed: "Reviewed citations linked",
    recovery: "Evidence needs recovery",
  }
}
