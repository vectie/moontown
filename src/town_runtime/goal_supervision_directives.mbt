///|
async fn apply_supervision_directive(
  state : @core.TownState,
  mayor : @roles.Mayor,
  catalog : Array[@moonbook.BookCatalogEntry],
  directive : @roles.MayorSupervisionDirective,
  snapshot_path : String,
  standing_goals : Array[@core.StandingGoal],
  retry? : async (
    @core.TownState,
    @roles.Mayor,
    Array[@moonbook.BookCatalogEntry],
    @core.TaskExecutionRecord,
    @roles.MayorSupervisionDirective,
    String,
    Array[@core.StandingGoal],
  ) -> Unit = retry_execution,
) -> Unit {
  let execution = match @core.find_execution(state, directive.task_id) {
    Some(execution) => execution
    None => return
  }
  // Native commands keep their exact identity through approval, uncertainty and
  // long waits. Generic stale/retry directives must not replace them.
  if @build_pipeline_runtime.is_wenyu_native_execution(execution) {
    return
  }
  if @roles.supervision_directive_retries_execution(directive.kind) &&
    @core.unconfirmed_standing_watch_dispatch(execution) {
    return
  }
  match directive.kind {
    kind if kind == @scheduler.persist_result_action_kind() =>
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
    kind if @roles.supervision_directive_marks_stale(kind) => {
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
    kind if @roles.supervision_directive_retries_execution(kind) =>
      retry(
        state, mayor, catalog, execution, directive, snapshot_path, standing_goals,
      )
    kind if kind == @scheduler.review_sync_action_kind() => {
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
  // A directive may have been computed before restart reconciliation. Recheck
  // the current execution at the existing dispatch boundary as well as Mayor.
  if @core.unconfirmed_standing_watch_dispatch(execution) {
    return
  }
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
    target_pages=execution.context_pages,
  )
  let rerun = execute_goal_book_task(
    mayor,
    entry,
    retry_task,
    assigned_worker_id=execution.assigned_worker_id,
    tick=supervision_tick(state),
    run_inline=false,
    native_path=@native_work.path_for_snapshot(snapshot_path),
    saved_legacy=execution.attempt > 0,
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
