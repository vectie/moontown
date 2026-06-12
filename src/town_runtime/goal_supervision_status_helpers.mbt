///|
fn terminal_execution_status(status : @core.TaskExecutionStatus) -> Bool {
  match status {
    @core.TaskExecutionStatus::Completed => true
    @core.TaskExecutionStatus::Stale => true
    @core.TaskExecutionStatus::Failed => true
    _ => false
  }
}

///|
fn live_external_execution_count(state : @core.TownState) -> Int {
  let mut count = 0
  for execution in state.executions {
    match execution.status {
      @core.TaskExecutionStatus::ProposalImported
      | @core.TaskExecutionStatus::RunConfirmed
      | @core.TaskExecutionStatus::Running =>
        if execution.run_id is Some(_) {
          count += 1
        }
      _ => ()
    }
  }
  count
}

///|
fn max_live_external_executions() -> Int {
  8
}

///|
fn has_live_executions(state : @core.TownState) -> Bool {
  for execution in state.executions {
    if live_execution_status(execution.status) {
      return true
    }
  }
  false
}

///|
fn has_retry_pending_executions(state : @core.TownState, tick : Int) -> Bool {
  ignore(tick)
  for execution in state.executions {
    match execution.status {
      @core.TaskExecutionStatus::Stale
      | @core.TaskExecutionStatus::Failed
      | @core.TaskExecutionStatus::ReviewQueued =>
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
fn no_run_id_live_execution_stale(
  execution : @core.TaskExecutionRecord,
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
fn pollable_execution_status(status : @core.TaskExecutionStatus) -> Bool {
  live_execution_status(status) || status is @core.TaskExecutionStatus::Stale
}

///|
fn live_execution_status(status : @core.TaskExecutionStatus) -> Bool {
  match status {
    @core.TaskExecutionStatus::ProposalImported => true
    @core.TaskExecutionStatus::RunConfirmed => true
    @core.TaskExecutionStatus::Running => true
    _ => false
  }
}

///|
fn polled_execution_stale_window_ticks(
  execution : @core.TaskExecutionRecord,
) -> Int {
  match execution.run_id {
    Some(_) => 120
    None => 15
  }
}
