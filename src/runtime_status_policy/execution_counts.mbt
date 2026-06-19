///|
fn count_runtime_executions_in_indexes(
  state : @core.TownState,
  indexes : Array[Int],
  statuses : Array[@core.TaskExecutionStatus],
) -> Int {
  let mut count = 0
  for index in indexes {
    let execution = state.executions[index]
    if execution_status_in(execution.status, statuses) {
      count += 1
    }
  }
  count
}

///|
fn count_active_work_executions_in_indexes(
  state : @core.TownState,
  indexes : Array[Int],
) -> Int {
  let mut count = 0
  for index in indexes {
    let execution = state.executions[index]
    if @core.active_work_execution_status(execution.status) {
      count += 1
    }
  }
  count
}

///|
fn effective_execution_indexes(state : @core.TownState) -> Array[Int] {
  let indexes : Array[Int] = []
  for index in 0..<state.executions.length() {
    if effective_execution_record(state, index) {
      indexes.push(index)
    }
  }
  indexes
}

///|
fn effective_execution_record(state : @core.TownState, index : Int) -> Bool {
  let current = state.executions[index]
  for other_index in 0..<state.executions.length() {
    if other_index == index {
      continue
    }
    let other = state.executions[other_index]
    if other.task_id != current.task_id {
      continue
    }
    let other_rank = @core.execution_status_rank(other.status)
    let current_rank = @core.execution_status_rank(current.status)
    if other_rank > current_rank ||
      (other_rank == current_rank && other_index > index) {
      return false
    }
  }
  true
}

///|
fn runtime_status_review_execution_statuses() -> Array[
  @core.TaskExecutionStatus,
] {
  [ReviewQueued]
}

///|
pub fn runtime_status_execution_counts(
  state : @core.TownState,
  report : @health.HealthReport,
) -> RuntimeStatusExecutionCounts {
  let effective_indexes = effective_execution_indexes(state)
  {
    running: count_active_work_executions_in_indexes(state, effective_indexes),
    review: count_runtime_executions_in_indexes(
      state,
      effective_indexes,
      runtime_status_review_execution_statuses(),
    ),
    failed: @health.count_health_anomalies_by_title(report, "execution-failed"),
    stale: count_runtime_executions_in_indexes(state, effective_indexes, [Stale]),
    completed: count_runtime_executions_in_indexes(state, effective_indexes, [
      Completed,
    ]),
  }
}

///|
pub fn runtime_status_active_execution_status(
  status : @core.TaskExecutionStatus,
) -> Bool {
  @core.active_work_execution_status(status)
}

///|
pub fn runtime_status_review_execution_status(
  status : @core.TaskExecutionStatus,
) -> Bool {
  execution_status_in(status, runtime_status_review_execution_statuses())
}

///|
fn execution_status_in(
  status : @core.TaskExecutionStatus,
  candidates : Array[@core.TaskExecutionStatus],
) -> Bool {
  for candidate in candidates {
    if status == candidate {
      return true
    }
  }
  false
}
