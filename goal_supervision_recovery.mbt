///|
async fn reconcile_transient_dependency_failures(
  state : @core.TownState,
  catalog? : Array[@moonbook.BookCatalogEntry] = [],
  snapshot_path? : String = @storage.default_snapshot_path(),
  standing_goals? : Array[@core.StandingGoal] = [],
) -> Unit {
  let snapshot = state.executions.copy()
  for execution in snapshot {
    if !transient_dependency_reconcilable_status(execution.status) ||
      !transient_external_dependency_error(execution.summary) {
      continue
    }
    let completed = copy_execution_with(
      execution,
      status=@core.TaskExecutionStatus::Completed,
      summary="\{execution.summary}\nkeeper_auto_triage: transient_infrastructure_contention\nreconciled_detail: MoonBook/MoonClaw dependency-lock or transport contention was classified as operational retry noise, not durable domain/task failure.",
      heartbeat_tick=supervision_tick(state),
      next_retry_tick=None,
      result_decision="deferred-transient-infrastructure",
      requires_review=false,
      notify_town=false,
    )
    state.replace_execution(completed)
    state.replace_task(task_for_supervision(state, completed))
    sync_worker_from_execution(state, completed)
    match @moonbook.entry_for_book_id(catalog, completed.book_id) {
      Some(entry) => {
        let observed = finalize_standing_watch_supervision_record(
          state, entry, completed, standing_goals, snapshot_path,
        )
        if observed != completed {
          state.replace_execution(observed)
          state.replace_task(task_for_supervision(state, observed))
          sync_worker_from_execution(state, observed)
        }
      }
      None => ()
    }
    state.record_event(
      @core.TownEvent::new(
        id="event-transient-infra-\{state.events.length()}-\{completed.task_id}",
        kind="recovery",
        detail="Mayor cleared transient infrastructure failure `\{completed.task_id}`; future cadence can retry normally.",
        related_task_id=Some(completed.task_id),
        related_book_id=Some(completed.book_id),
        related_run_id=completed.run_id,
      ),
    )
  }
}

///|
fn transient_dependency_reconcilable_status(
  status : @core.TaskExecutionStatus,
) -> Bool {
  match status {
    @core.TaskExecutionStatus::Failed
    | @core.TaskExecutionStatus::ReviewQueued => true
    _ => false
  }
}

///|
async fn reconcile_repaired_context_import_failures(
  state : @core.TownState,
) -> Unit {
  let snapshot = state.executions.copy()
  for execution in snapshot {
    if execution.status != @core.TaskExecutionStatus::Failed ||
      !execution.summary.contains("context_pages must not be empty") {
      continue
    }
    match @moonclaw.load_packet_file(execution.packet_path) {
      Some(packet) if packet.context_pages.length() > 0 => {
        let completed = copy_execution_with(
          execution,
          status=@core.TaskExecutionStatus::Completed,
          summary="\{execution.summary}\nkeeper_auto_triage: superseded_context_import_failure\nreconciled_detail: referenced packet now has \{packet.context_pages.length()} context page(s), so the stale import-validation failure no longer represents active work.",
          context_pages=packet.context_pages,
          skill_paths=packet.skill_paths,
          heartbeat_tick=supervision_tick(state),
          next_retry_tick=None,
          result_decision="superseded",
          requires_review=false,
          notify_town=false,
        )
        state.replace_execution(completed)
        state.replace_task(task_for_supervision(state, completed))
        sync_worker_from_execution(state, completed)
        state.record_event(
          @core.TownEvent::new(
            id="event-repaired-context-import-\{state.events.length()}-\{completed.task_id}",
            kind="recovery",
            detail="Mayor reconciled stale import failure `\{completed.task_id}` because the saved packet now contains keeper context.",
            related_task_id=Some(completed.task_id),
            related_book_id=Some(completed.book_id),
            related_run_id=completed.run_id,
          ),
        )
      }
      _ => ()
    }
  }
}
