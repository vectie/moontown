///|
pub fn count_live_workers(state : @core.TownState) -> Int {
  let mut count = 0
  for worker in state.workers {
    if worker_is_live(worker) {
      count += 1
    }
  }
  count
}

///|
pub fn worker_is_live(worker : @core.WorkerRef) -> Bool {
  worker.status == @core.WorkerStatus::Running ||
  worker.status == @core.WorkerStatus::Waiting ||
  worker.status == @core.WorkerStatus::Blocked
}

///|
pub fn count_live_activity(state : @core.TownState) -> Int {
  max_int(count_live_workers(state), count_live_active_executions(state))
}

///|
pub fn count_live_active_executions(state : @core.TownState) -> Int {
  let mut count = 0
  for execution in state.executions {
    if @runtime_status_policy.runtime_status_active_execution_status(
        execution.status,
      ) {
      count += 1
    }
  }
  count
}

///|
pub fn count_live_review_executions(state : @core.TownState) -> Int {
  let mut count = 0
  for execution in state.executions {
    if @runtime_status_policy.runtime_status_review_execution_status(
        execution.status,
      ) {
      count += 1
    }
  }
  count
}

///|
pub fn count_transient_infrastructure_debt(state : @core.TownState) -> Int {
  let mut count = 0
  for execution in state.executions {
    if execution_is_transient_infrastructure_debt(execution) {
      count += 1
    }
  }
  count
}

///|
pub fn execution_is_transient_infrastructure_debt(
  execution : @core.TaskExecutionRecord,
) -> Bool {
  execution.result_decision == "deferred-transient-infrastructure"
}

///|
pub fn live_autonomy_tick(state : @core.TownState) -> Int {
  let mut tick = state.events.length()
  for execution in state.executions {
    if execution.heartbeat_tick > tick {
      tick = execution.heartbeat_tick
    }
  }
  tick
}

///|
pub fn live_autonomy_metric_counts(
  active_workers~ : Int,
  review~ : Int,
  blocked~ : Int,
  accepted_updates~ : Int,
  no_change~ : Int,
  failed~ : Int,
  transient_infrastructure_debt~ : Int,
  enabled_standing_goals~ : Int,
  disabled_standing_goals~ : Int,
  due_goals~ : Int,
) -> LiveAutonomyMetricCounts {
  {
    active_workers,
    review,
    blocked,
    accepted_updates,
    no_change,
    failed,
    transient_infrastructure_debt,
    enabled_standing_goals,
    disabled_standing_goals,
    due_goals,
  }
}

///|
fn max_int(left : Int, right : Int) -> Int {
  if left > right {
    left
  } else {
    right
  }
}
