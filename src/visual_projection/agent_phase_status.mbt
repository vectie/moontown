///|
fn visual_execution_is_live(status : @core.TaskExecutionStatus) -> Bool {
  match status {
    PacketReady
    | ProposalImported
    | RunConfirmed
    | Running
    | AwaitingPersistence
    | ReviewQueued
    | Stale
    | Failed => true
    Completed => false
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
        Running => "running"
        Waiting => "waiting"
        Idle => "idle"
        Blocked => "blocked"
        Offline => "offline"
      }
  }
}

///|
fn visual_phase_for_execution(status : @core.TaskExecutionStatus) -> String {
  match status {
    PacketReady => "packet"
    ProposalImported => "importing"
    RunConfirmed => "running"
    Running => "running"
    AwaitingPersistence => "persisting"
    ReviewQueued => "review"
    Completed => "completed"
    Stale => "stale"
    Failed => "failed"
  }
}

///|
fn visual_worker_status(status : @core.WorkerStatus) -> String {
  match status {
    Idle => "idle"
    Running => "running"
    Waiting => "waiting"
    Blocked => "blocked"
    Offline => "offline"
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
