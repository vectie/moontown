///|
async fn apply_supervision_directive(
  state : @core.TownState,
  mayor : @roles.Mayor,
  catalog : Array[@moonbook.BookCatalogEntry],
  directive : @roles.MayorSupervisionDirective,
  snapshot_path : String,
  standing_goals : Array[@core.StandingGoal],
) -> Unit {
  let execution = match @core.find_execution(state, directive.task_id) {
    Some(execution) => execution
    None => return
  }
  match directive.kind {
    "persist-result" =>
      match @moonbook.entry_for_book_id(catalog, execution.book_id) {
        Some(entry) =>
          match persist_execution_into_book(state, entry, execution) {
            Some(outcome) => {
              let reconciled = execution_after_successful_book_persist(
                execution,
                outcome,
                supervision_tick(state),
              )
              if reconciled != execution {
                state.replace_execution(reconciled)
                state.replace_task(task_for_supervision(state, reconciled))
                sync_worker_from_execution(state, reconciled)
              }
            }
            None => ()
          }
        None => ()
      }
    "mark-stale-retry" | "mark-stale-failed" => {
      let updated = copy_execution_with(
        execution,
        status=directive.execution_status,
        summary=directive.detail,
        next_retry_tick=directive.next_retry_tick,
      )
      state.replace_execution(updated)
      state.replace_task(task_for_supervision(state, updated))
      sync_worker_from_execution(state, updated)
    }
    "retry-execution" =>
      retry_execution(
        state, mayor, catalog, execution, directive, snapshot_path, standing_goals,
      )
    "review-sync" => {
      let updated = copy_execution_with(
        execution,
        heartbeat_tick=supervision_tick(state),
      )
      state.replace_execution(updated)
      sync_worker_from_execution(state, updated)
    }
    _ => ()
  }
}

///|
async fn retry_execution(
  state : @core.TownState,
  mayor : @roles.Mayor,
  catalog : Array[@moonbook.BookCatalogEntry],
  execution : @core.TaskExecutionRecord,
  directive : @roles.MayorSupervisionDirective,
  snapshot_path : String,
  standing_goals : Array[@core.StandingGoal],
) -> Unit {
  let entry = match @moonbook.entry_for_book_id(catalog, execution.book_id) {
    Some(entry) => entry
    None => return
  }
  let task = match @core.find_task(state, execution.task_id) {
    Some(task) => task
    None => return
  }
  let retry_task = @moonbook.BookTask::new(
    id=task.id,
    goal=Some(task.prompt),
    title=task.title,
    kind=stage_kind_for_task(task),
    prompt=task.prompt,
    priority=80,
    requires_review=execution.requires_review,
    required_role=task.required_role,
  )
  let rerun = execute_goal_book_task(
    mayor,
    entry,
    retry_task,
    assigned_worker_id=execution.assigned_worker_id,
    tick=supervision_tick(state),
    run_inline=false,
  ) catch {
    error =>
      failed_execution_record(
        entry,
        retry_task,
        "Mayor retry failed for \{entry.id} / \{task.id}: \{error}",
        assigned_worker_id=execution.assigned_worker_id,
      )
  }
  let updated = copy_execution_with(
    rerun,
    attempt=execution.attempt + 1,
    next_retry_tick=directive.next_retry_tick,
  )
  state.replace_execution(updated)
  state.replace_task(task_for_supervision(state, updated))
  sync_worker_from_execution(state, updated)
  let reconciled = match persist_execution_into_book(state, entry, updated) {
    Some(outcome) =>
      execution_after_successful_book_persist(
        updated,
        outcome,
        supervision_tick(state),
      )
    None => updated
  }
  if reconciled != updated {
    state.replace_execution(reconciled)
    state.replace_task(task_for_supervision(state, reconciled))
    sync_worker_from_execution(state, reconciled)
  }
  if @core.terminal_execution_status(updated.status) {
    finalize_goal_book_entry(state, entry, 0, [reconciled.task_id])
    let observed = finalize_standing_watch_supervision_record(
      state, entry, reconciled, standing_goals, snapshot_path,
    )
    if observed != reconciled {
      state.replace_execution(observed)
      state.replace_task(task_for_supervision(state, observed))
      sync_worker_from_execution(state, observed)
    }
  }
}
