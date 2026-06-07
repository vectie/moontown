///|
fn count_live_workers(state : @core.TownState) -> Int {
  let mut count = 0
  for worker in state.workers {
    if worker_is_live(worker) {
      count += 1
    }
  }
  count
}

///|
fn worker_is_live(worker : @core.WorkerRef) -> Bool {
  worker.status == @core.WorkerStatus::Running ||
  worker.status == @core.WorkerStatus::Waiting ||
  worker.status == @core.WorkerStatus::Blocked
}

///|
fn count_live_activity(state : @core.TownState) -> Int {
  max_int(count_live_workers(state), count_live_active_executions(state))
}

///|
fn count_live_active_executions(state : @core.TownState) -> Int {
  count_live_executions(state, active_execution_statuses())
}

///|
fn count_live_executions(
  state : @core.TownState,
  statuses : Array[@core.TaskExecutionStatus],
) -> Int {
  let mut count = 0
  for execution in state.executions {
    if execution_status_in(execution.status, statuses) {
      count += 1
    }
  }
  count
}

///|
fn count_transient_infrastructure_debt(state : @core.TownState) -> Int {
  let mut count = 0
  for execution in state.executions {
    if execution_is_transient_infrastructure_debt(execution) {
      count += 1
    }
  }
  count
}

///|
fn execution_is_transient_infrastructure_debt(
  execution : @core.TaskExecutionRecord,
) -> Bool {
  execution.result_decision == "deferred-transient-infrastructure"
}

///|
fn live_autonomy_tick(state : @core.TownState) -> Int {
  let mut tick = state.events.length()
  for execution in state.executions {
    if execution.heartbeat_tick > tick {
      tick = execution.heartbeat_tick
    }
  }
  tick
}
