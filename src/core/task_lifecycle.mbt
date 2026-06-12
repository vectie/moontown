///|
pub fn town_task_status_for_execution(
  status : TaskExecutionStatus,
) -> TownTaskStatus {
  match status {
    TaskExecutionStatus::PacketReady => TownTaskStatus::Planned
    TaskExecutionStatus::ProposalImported => TownTaskStatus::Assigned
    TaskExecutionStatus::RunConfirmed => TownTaskStatus::Assigned
    TaskExecutionStatus::Running => TownTaskStatus::Running
    TaskExecutionStatus::AwaitingPersistence => TownTaskStatus::Running
    TaskExecutionStatus::ReviewQueued => TownTaskStatus::Blocked
    TaskExecutionStatus::Completed => TownTaskStatus::Done
    TaskExecutionStatus::Stale => TownTaskStatus::Blocked
    TaskExecutionStatus::Failed => TownTaskStatus::Failed
  }
}

///|
pub fn copy_task_with_status(
  task : TownTask,
  status : TownTaskStatus,
) -> TownTask {
  TownTask::new(
    id=task.id,
    book_id=task.book_id,
    title=task.title,
    prompt=task.prompt,
    domain=task.domain,
    required_role=task.required_role,
    required_capabilities=task.required_capabilities,
    status~,
  )
}

///|
pub fn terminal_execution_status(status : TaskExecutionStatus) -> Bool {
  match status {
    TaskExecutionStatus::Completed => true
    TaskExecutionStatus::Stale => true
    TaskExecutionStatus::Failed => true
    _ => false
  }
}

///|
pub fn live_execution_status(status : TaskExecutionStatus) -> Bool {
  match status {
    TaskExecutionStatus::ProposalImported => true
    TaskExecutionStatus::RunConfirmed => true
    TaskExecutionStatus::Running => true
    _ => false
  }
}

///|
pub fn pollable_execution_status(status : TaskExecutionStatus) -> Bool {
  live_execution_status(status) || status is TaskExecutionStatus::Stale
}

///|
pub fn polled_execution_stale_window_ticks(
  execution : TaskExecutionRecord,
) -> Int {
  match execution.run_id {
    Some(_) => 120
    None => 15
  }
}

///|
pub fn external_execution_stale_window_ticks() -> Int {
  30
}

///|
pub fn no_run_id_live_execution_stale(
  execution : TaskExecutionRecord,
  tick : Int,
) -> Bool {
  if !live_execution_status(execution.status) {
    return false
  }
  tick >= execution.stale_after_tick ||
  (
    execution.run_id is None &&
    tick >=
    execution.heartbeat_tick + polled_execution_stale_window_ticks(execution)
  )
}

///|
pub fn live_external_execution_count(state : TownState) -> Int {
  let mut count = 0
  for execution in state.executions {
    match execution.status {
      TaskExecutionStatus::ProposalImported
      | TaskExecutionStatus::RunConfirmed
      | TaskExecutionStatus::Running =>
        if execution.run_id is Some(_) {
          count += 1
        }
      _ => ()
    }
  }
  count
}

///|
pub fn max_live_external_executions() -> Int {
  8
}

///|
pub fn has_live_executions(state : TownState) -> Bool {
  for execution in state.executions {
    if live_execution_status(execution.status) {
      return true
    }
  }
  false
}

///|
pub fn has_retry_pending_executions(state : TownState, tick : Int) -> Bool {
  ignore(tick)
  for execution in state.executions {
    match execution.status {
      TaskExecutionStatus::Stale
      | TaskExecutionStatus::Failed
      | TaskExecutionStatus::ReviewQueued =>
        match execution.next_retry_tick {
          Some(_) if execution.attempt < 3 => return true
          _ => ()
        }
      _ => ()
    }
  }
  false
}
