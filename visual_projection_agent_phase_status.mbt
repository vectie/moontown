///|
fn visual_execution_is_live(status : @core.TaskExecutionStatus) -> Bool {
  match status {
    @core.TaskExecutionStatus::PacketReady
    | @core.TaskExecutionStatus::ProposalImported
    | @core.TaskExecutionStatus::RunConfirmed
    | @core.TaskExecutionStatus::Running
    | @core.TaskExecutionStatus::AwaitingPersistence
    | @core.TaskExecutionStatus::ReviewQueued
    | @core.TaskExecutionStatus::Stale
    | @core.TaskExecutionStatus::Failed => true
    @core.TaskExecutionStatus::Completed => false
  }
}

///|
fn visual_agent_phase(
  worker : @core.WorkerRef,
  execution : @core.TaskExecutionRecord?,
) -> String {
  match execution {
    Some(record) => visual_phase_for_execution(record.status)
    None =>
      match worker.status {
        @core.WorkerStatus::Running => "running"
        @core.WorkerStatus::Waiting => "waiting"
        @core.WorkerStatus::Idle => "idle"
        @core.WorkerStatus::Blocked => "blocked"
        @core.WorkerStatus::Offline => "offline"
      }
  }
}

///|
fn visual_phase_for_execution(status : @core.TaskExecutionStatus) -> String {
  match status {
    @core.TaskExecutionStatus::PacketReady => "packet"
    @core.TaskExecutionStatus::ProposalImported => "importing"
    @core.TaskExecutionStatus::RunConfirmed => "running"
    @core.TaskExecutionStatus::Running => "running"
    @core.TaskExecutionStatus::AwaitingPersistence => "persisting"
    @core.TaskExecutionStatus::ReviewQueued => "review"
    @core.TaskExecutionStatus::Completed => "completed"
    @core.TaskExecutionStatus::Stale => "stale"
    @core.TaskExecutionStatus::Failed => "failed"
  }
}

///|
fn visual_worker_status(status : @core.WorkerStatus) -> String {
  match status {
    @core.WorkerStatus::Idle => "idle"
    @core.WorkerStatus::Running => "running"
    @core.WorkerStatus::Waiting => "waiting"
    @core.WorkerStatus::Blocked => "blocked"
    @core.WorkerStatus::Offline => "offline"
  }
}

///|
fn visual_phase_is_handoff(phase : String) -> Bool {
  phase == "packet" || phase == "importing"
}

///|
fn visual_phase_is_working(phase : String) -> Bool {
  phase == "running"
}

///|
fn visual_phase_is_keeper_bound(phase : String) -> Bool {
  phase == "persisting" || phase == "review"
}

///|
fn visual_phase_is_recovery(phase : String) -> Bool {
  phase == "failed" || phase == "stale" || phase == "blocked"
}

///|
fn visual_phase_is_completed_or_idle(phase : String) -> Bool {
  phase == "completed" || phase == "idle"
}
