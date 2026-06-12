///|
priv enum CivicExecutionStage {
  Packet
  Running
  Persisting
  Review
  Completed
  Recovery
}

///|
fn civic_execution_stage(
  status : @core.TaskExecutionStatus,
) -> CivicExecutionStage {
  match status {
    @core.TaskExecutionStatus::PacketReady
    | @core.TaskExecutionStatus::ProposalImported => Packet
    @core.TaskExecutionStatus::RunConfirmed
    | @core.TaskExecutionStatus::Running => Running
    @core.TaskExecutionStatus::AwaitingPersistence => Persisting
    @core.TaskExecutionStatus::ReviewQueued => Review
    @core.TaskExecutionStatus::Completed => Completed
    @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
      Recovery
  }
}

///|
priv struct CivicExecutionStagePhrases {
  packet : String
  running : String
  persisting : String
  review : String
  completed : String
  recovery : String
}

///|
fn civic_execution_stage_label(
  execution : @core.TaskExecutionRecord?,
  phrases : CivicExecutionStagePhrases,
  fallback~ : String,
) -> String {
  match execution {
    Some(execution) =>
      civic_execution_stage_label_for_status(execution.status, phrases)
    None => fallback
  }
}

///|
fn civic_projected_execution_stage_label(
  source : StateSourceKind,
  execution : @core.TaskExecutionRecord?,
  phrases : CivicExecutionStagePhrases,
  projection_fallback~ : String,
  fallback~ : String,
) -> String {
  if source == StateSourceKind::SnapshotFile {
    projection_fallback
  } else {
    civic_execution_stage_label(execution, phrases, fallback~)
  }
}

///|
fn civic_execution_stage_label_for_status(
  status : @core.TaskExecutionStatus,
  phrases : CivicExecutionStagePhrases,
) -> String {
  match civic_execution_stage(status) {
    Packet => phrases.packet
    Running => phrases.running
    Persisting => phrases.persisting
    Review => phrases.review
    Completed => phrases.completed
    Recovery => phrases.recovery
  }
}

///|
type CivicExecutionActionPhrases = CivicExecutionStagePhrases

///|
fn civic_execution_action_label(
  execution : @core.TaskExecutionRecord?,
  phrases : CivicExecutionActionPhrases,
  fallback~ : String,
) -> String {
  civic_execution_stage_label(execution, phrases, fallback~)
}

///|
type CivicExecutionSignalPhrases = CivicExecutionStagePhrases

///|
fn civic_signal_phrases(
  packet? : String = "Dispatching",
  running~ : String,
  persisting~ : String,
  review~ : String,
  completed~ : String,
  recovery? : String = "Needs recovery",
) -> CivicExecutionSignalPhrases {
  { packet, running, persisting, review, completed, recovery }
}

///|
fn civic_execution_signal_label(
  execution : @core.TaskExecutionRecord?,
  phrases : CivicExecutionSignalPhrases,
  fallback~ : String,
) -> String {
  civic_execution_stage_label(execution, phrases, fallback~)
}

///|
fn civic_projected_execution_signal_label(
  source : StateSourceKind,
  execution : @core.TaskExecutionRecord?,
  phrases : CivicExecutionSignalPhrases,
  fallback~ : String,
) -> String {
  if source == StateSourceKind::SnapshotFile {
    "Projection bridge"
  } else {
    civic_execution_signal_label(execution, phrases, fallback~)
  }
}

///|
fn civic_task_prompt_or_fallback(
  task : @core.TownTask?,
  fallback~ : String,
) -> String {
  match task {
    Some(task) => task.prompt
    None => fallback
  }
}

///|
fn civic_task_prompt_or_projected_fallback(
  source : StateSourceKind,
  task : @core.TownTask?,
  projection_fallback~ : String,
  fallback~ : String,
) -> String {
  civic_task_prompt_or_fallback(
    task,
    fallback=if source == StateSourceKind::SnapshotFile {
      projection_fallback
    } else {
      fallback
    },
  )
}

///|
priv struct CivicExecutionScorePolicy {
  packet : Int
  running : Int
  persisting : Int
  review : Int
  completed : Int
  recovery : Int
}

///|
fn civic_execution_score(
  execution : @core.TaskExecutionRecord?,
  policy : CivicExecutionScorePolicy,
  fallback~ : Int,
) -> Int {
  match execution {
    Some(execution) =>
      civic_execution_score_for_status(execution.status, policy)
    None => fallback
  }
}

///|
fn civic_execution_score_for_status(
  status : @core.TaskExecutionStatus,
  policy : CivicExecutionScorePolicy,
) -> Int {
  match civic_execution_stage(status) {
    Packet => policy.packet
    Running => policy.running
    Persisting => policy.persisting
    Review => policy.review
    Completed => policy.completed
    Recovery => policy.recovery
  }
}
