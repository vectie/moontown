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
fn execution_action_kind(execution : @core.TaskExecutionRecord) -> String? {
  match execution.status {
    PacketReady => Some(proposal_import_action_kind())
    ProposalImported => Some(run_confirm_action_kind())
    RunConfirmed => Some(run_start_action_kind())
    Running => Some(poll_run_action_kind())
    AwaitingPersistence => Some(persist_result_action_kind())
    ReviewQueued => Some(review_sync_action_kind())
    AwaitingAcceptance => None
    Completed => Some(archive_action_kind())
    Stale => Some(recover_stale_action_kind())
    Failed => Some(recovery_action_kind())
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
        match execution_action_kind(execution) {
          Some(kind) =>
            actions.push({
              kind,
              detail: "\{task.id} / \{execution.status.to_string()}",
            })
          None => ()
        }
      None =>
        actions.push({
          kind: prepare_packet_action_kind(),
          detail: "\{task.id} for \{task.book_id}",
        })
    }
  }
  for recovery in @health.recovery_actions(report) {
    actions.push({ kind: recovery.kind, detail: recovery.detail, })
  }
  actions
}
