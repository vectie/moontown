///|
async fn terminal_detached_watcher_ledger_candidate(
  execution : @core.TaskExecutionRecord,
  standing_goals : Array[@core.StandingGoal],
  snapshot_path : String,
) -> Bool {
  if !terminal_execution_status(execution.status) {
    return false
  }
  let goal = match
    @standing_watch_policy.standing_goal_for_execution_task(
      standing_goals,
      execution.task_id,
    ) {
    Some(goal) => goal
    None => return false
  }
  let ledger_dir = watcher_ledger_dir_for_snapshot(snapshot_path)
  match terminal_watcher_record_for_execution(goal.id, ledger_dir, execution) {
    Some(_) => return false
    None => ()
  }
  detached_import_evidence_for_execution(execution)
}

///|
async fn detached_import_evidence_for_execution(
  execution : @core.TaskExecutionRecord,
) -> Bool {
  let command_matches = match execution.last_command {
    Some(command) => command.contains(".import.json")
    None => false
  }
  let packet_path = detached_import_packet_path_for_execution(execution)
  let receipt_path = if packet_path.trim().is_empty() {
    ""
  } else {
    @moonclaw.detached_import_receipt_path(packet_path)
  }
  command_matches ||
  (!receipt_path.is_empty() && @fs.exists(receipt_path)) ||
  execution.summary.contains("inline run finished") ||
  execution.result_decision == "deferred-transient-infrastructure"
}

///|
async fn finalize_terminal_detached_watcher_ledger_if_needed(
  state : @core.TownState,
  catalog : Array[@moonbook.BookCatalogEntry],
  snapshot_path : String,
  standing_goals : Array[@core.StandingGoal],
  execution : @core.TaskExecutionRecord,
) -> Unit {
  match @moonbook.entry_for_book_id(catalog, execution.book_id) {
    Some(entry) => {
      let observed = finalize_standing_watch_supervision_record(
        state, entry, execution, standing_goals, snapshot_path,
      )
      if observed != execution {
        state.replace_execution(observed)
        state.replace_task(task_for_supervision(state, observed))
        sync_worker_from_execution(state, observed)
      }
    }
    None => ()
  }
}
