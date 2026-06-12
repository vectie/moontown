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
pub fn schedulable_task_status(status : TownTaskStatus) -> Bool {
  match status {
    TownTaskStatus::Pending => true
    TownTaskStatus::Planned => true
    TownTaskStatus::Assigned => true
    TownTaskStatus::Running => true
    TownTaskStatus::Blocked => false
    TownTaskStatus::Done => false
    TownTaskStatus::Failed => false
  }
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
pub fn active_work_execution_status(status : TaskExecutionStatus) -> Bool {
  live_execution_status(status) ||
  status is TaskExecutionStatus::AwaitingPersistence
}

///|
pub fn execution_status_rank(status : TaskExecutionStatus) -> Int {
  match status {
    TaskExecutionStatus::PacketReady => 1
    TaskExecutionStatus::ProposalImported => 2
    TaskExecutionStatus::RunConfirmed
    | TaskExecutionStatus::Running
    | TaskExecutionStatus::AwaitingPersistence => 3
    TaskExecutionStatus::ReviewQueued
    | TaskExecutionStatus::Completed
    | TaskExecutionStatus::Stale
    | TaskExecutionStatus::Failed => 4
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
pub fn has_active_work_executions(state : TownState) -> Bool {
  for execution in state.executions {
    if active_work_execution_status(execution.status) {
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

///|
pub fn tick_from_task_id(task_id : String) -> Int {
  match tick_marker_index(task_id) {
    Some(index) => first_non_negative_int(task_id[index + 5:].to_owned())
    None => 0
  }
}

///|
fn tick_marker_index(task_id : String) -> Int? {
  let marker = "tick-"
  let limit = task_id.length() - marker.length()
  if limit < 0 {
    return None
  }
  let mut found : Int? = None
  for index in 0..<=limit {
    if task_id[index:index + marker.length()].to_owned() == marker {
      found = Some(index)
    }
  }
  found
}

///|
fn first_non_negative_int(text : String) -> Int {
  let mut value = 0
  let mut seen = false
  for char in text {
    if char >= '0' && char <= '9' {
      value = value * 10 + (char.to_int() - '0'.to_int())
      seen = true
    } else if seen {
      return value
    }
  }
  value
}
