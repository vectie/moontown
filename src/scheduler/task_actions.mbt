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
    @core.TaskExecutionStatus::PacketReady => proposal_import_action_kind()
    @core.TaskExecutionStatus::ProposalImported => run_confirm_action_kind()
    @core.TaskExecutionStatus::RunConfirmed => run_start_action_kind()
    @core.TaskExecutionStatus::Running => poll_run_action_kind()
    @core.TaskExecutionStatus::AwaitingPersistence =>
      persist_result_action_kind()
    @core.TaskExecutionStatus::ReviewQueued => review_sync_action_kind()
    @core.TaskExecutionStatus::Completed => archive_action_kind()
    @core.TaskExecutionStatus::Stale => recover_stale_action_kind()
    @core.TaskExecutionStatus::Failed => recovery_action_kind()
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
          kind: prepare_packet_action_kind(),
          detail: "\{task.id} for \{task.book_id}",
        })
    }
  }
  for recovery in @health.recovery_actions(report) {
    actions.push({ kind: recovery.kind, detail: recovery.detail })
  }
  actions
}
