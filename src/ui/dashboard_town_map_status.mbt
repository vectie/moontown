///|
fn count_execution_status(
  town : @core.TownState,
  status : @core.TaskExecutionStatus,
) -> Int {
  count_executions_by_status(town, fn(candidate) { candidate == status })
}

///|
fn running_like_count(town : @core.TownState) -> Int {
  count_executions_by_status(town, dashboard_execution_status_running_like)
}

///|
fn count_executions_by_status(
  town : @core.TownState,
  predicate : (@core.TaskExecutionStatus) -> Bool,
) -> Int {
  let mut count = 0
  for execution in town.executions {
    if predicate(execution.status) {
      count += 1
    }
  }
  count
}

///|
fn dashboard_execution_status_running_like(
  status : @core.TaskExecutionStatus,
) -> Bool {
  match status {
    @core.TaskExecutionStatus::RunConfirmed
    | @core.TaskExecutionStatus::Running
    | @core.TaskExecutionStatus::AwaitingPersistence
    | @core.TaskExecutionStatus::ReviewQueued
    | @core.TaskExecutionStatus::Stale => true
    _ => false
  }
}
