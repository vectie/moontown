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
  @live_autonomy_policy.worker_is_live(worker)
}

///|
fn count_live_activity(state : @core.TownState) -> Int {
  @support.max_int(
    count_live_workers(state),
    count_live_active_executions(state),
  )
}

///|
fn count_live_active_executions(state : @core.TownState) -> Int {
  @live_autonomy_policy.count_live_active_executions(state)
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
  @live_autonomy_policy.execution_is_transient_infrastructure_debt(execution)
}

///|
fn live_autonomy_tick(state : @core.TownState) -> Int {
  @live_autonomy_policy.live_autonomy_tick(state)
}
