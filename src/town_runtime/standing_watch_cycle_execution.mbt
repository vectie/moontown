///|
async fn execute_dispatched_standing_watch_task(
  mayor : @roles.Mayor,
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  route : @roles.MayorDispatchPacket,
  worker_id : String?,
  tick : Int,
) -> @core.TaskExecutionRecord {
  let execution = match route.decision {
    @dispatch.RouteDecision::Assigned(_) =>
      execute_goal_book_task(
        mayor,
        entry,
        task,
        assigned_worker_id=worker_id,
        tick~,
      ) catch {
        error => {
          let detail = "Standing watch execution failed for \{entry.id} / \{task.id}: \{error}"
          if @standing_watch_policy.standing_watch_transient_dispatch_error(
              detail,
            ) {
            transient_deferred_standing_watch_execution_record(
              entry,
              task,
              detail,
              assigned_worker_id=worker_id,
              tick~,
            )
          } else {
            failed_execution_record(
              entry,
              task,
              detail,
              assigned_worker_id=worker_id,
            )
          }
        }
      }
    _ =>
      failed_execution_record(
        entry,
        task,
        "Mayor could not dispatch standing watch task for \{entry.id}: \{route.rationale}",
      )
  }
  @build_pipeline.complete_wenyu_build_artifacts_if_needed(
    entry, task, execution,
  )
}

///|
fn apply_standing_watch_execution_state(
  state : @core.TownState,
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  execution : @core.TaskExecutionRecord,
) -> Unit {
  state.replace_task(to_town_task(entry, task, execution.status))
  state.replace_execution(execution)
  sync_worker_from_execution(state, execution)
  state.record_event(execution_event(execution, state.executions.length() - 1))
}
