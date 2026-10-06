///|
/// Restore durable source-bound work before existing import/poll/ledger recovery.
async fn restore_material_watch_executions(
  state : @core.TownState,
  snapshot_path : String,
  goals : Array[@core.StandingGoal],
) -> Unit {
  for goal in goals {
    if material_watch_plan_path(goal) is None {
      continue
    }
    let directory = material_watch_directory(snapshot_path, goal.id)
    if !@fs.exists(directory) {
      continue
    }
    try {
      let lock = @fs.open(
        directory + "/watch.lock",
        mode=ReadWrite,
        create_mode=OpenOrCreate,
      )
      defer lock.close()
      if !lock.try_lock(Exclusive) {
        continue
      }
      reconcile_material_watch_receipts(directory)
      guard load_material_watch_journal(directory) is Some(journal) else {
        continue
      }
      for change in journal.changes {
        let execution = material_watch_observed_execution(state, change)
        if execution is Some(execution) {
          let bound = bind_material_watch_execution(execution, change)
          state.replace_execution(bound)
          state.replace_task(task_for_supervision(state, bound))
        }
      }
    } catch {
      error =>
        state.record_event(
          @core.TownEvent::new(
            id="event-material-watch-recovery-" + goal.id,
            kind="error",
            detail="Material watch recovery needs attention; retained existing work: " +
              error.to_string(),
            related_book_id=goal.target_book_id,
          ),
        )
    }
  }
}

///|
async fn retain_material_watch_observation(
  goal : @core.StandingGoal,
  snapshot_path : String,
  execution : @core.TaskExecutionRecord,
) -> @core.TaskExecutionRecord {
  if material_watch_plan_path(goal) is None {
    return execution
  }
  let directory = material_watch_directory(snapshot_path, goal.id)
  if !@fs.exists(directory) {
    return execution
  }
  let lock = @fs.open(
    directory + "/watch.lock",
    mode=ReadWrite,
    create_mode=OpenOrCreate,
  )
  defer lock.close()
  if !lock.try_lock(Exclusive) {
    return execution
  }
  reconcile_material_watch_receipts(directory)
  guard load_material_watch_journal(directory) is Some(journal) else {
    return execution
  }
  for change in journal.changes {
    if change.input.task_id == execution.task_id {
      let selected = select_material_watch_execution(change, Some(execution)).unwrap()
      let bound = bind_material_watch_execution(selected, change)
      remember_material_watch_execution(directory, bound)
      return bound
    }
  }
  execution
}
