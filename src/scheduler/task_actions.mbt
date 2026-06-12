///|
pub fn collect_due_tasks(town : @core.TownState) -> Array[@core.TownTask] {
  let tasks : Array[@core.TownTask] = []
  for task in town.tasks {
    if @core.schedulable_task_status(task.status) {
      tasks.push(task)
    }
  }
  tasks
}

///|
fn execution_action_kind(execution : @core.TaskExecutionRecord) -> String {
  match execution.status {
    @core.TaskExecutionStatus::PacketReady => "proposal-import"
    @core.TaskExecutionStatus::ProposalImported => "run-confirm"
    @core.TaskExecutionStatus::RunConfirmed => "run-start"
    @core.TaskExecutionStatus::Running => "poll-run"
    @core.TaskExecutionStatus::AwaitingPersistence => "persist-result"
    @core.TaskExecutionStatus::ReviewQueued => "review-sync"
    @core.TaskExecutionStatus::Completed => "archive"
    @core.TaskExecutionStatus::Stale => "recover-stale"
    @core.TaskExecutionStatus::Failed => "recovery"
  }
}

///|
pub fn plan_tick(
  town : @core.TownState,
  report : @health.HealthReport,
) -> Array[SchedulerAction] {
  let actions : Array[SchedulerAction] = []
  for task in collect_due_tasks(town) {
    match @core.find_execution(town, task.id) {
      Some(execution) =>
        actions.push({
          kind: execution_action_kind(execution),
          detail: "\{task.id} / \{execution.status.to_string()}",
        })
      None =>
        actions.push({
          kind: "prepare-packet",
          detail: "\{task.id} for \{task.book_id}",
        })
    }
  }
  for recovery in @health.recovery_actions(report) {
    actions.push({ kind: recovery.kind, detail: recovery.detail })
  }
  actions
}
