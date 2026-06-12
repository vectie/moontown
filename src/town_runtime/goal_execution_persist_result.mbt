///|
async fn persist_execution_into_book(
  state : @core.TownState,
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
) -> @moonbook.PersistResultOutcome? {
  if execution.summary.trim().is_blank() ||
    @core.live_execution_status(execution.status) {
    return None
  }
  let result_summary = book_persist_summary(entry, execution)
  let result_artifacts = book_persist_artifacts(entry, execution)
  let memory_candidates = book_persist_memory_candidates(entry, execution)
  let result = @moonbook.BookResult::new(
    task_id=execution.task_id,
    summary=result_summary,
    artifacts=result_artifacts,
    memory_candidates~,
    requires_review=execution.requires_review ||
      execution.status is @core.TaskExecutionStatus::Running,
    notify_town=execution.notify_town,
  )
  let outcome = @moonbook.persist_result(entry, result) catch {
    error => {
      state.record_event(
        @core.TownEvent::new(
          id="event-persist-\{entry.id}-\{execution.task_id}",
          kind="error",
          detail="MoonBook persist failed for \{entry.id} / \{execution.task_id}: \{error}",
          related_book_id=Some(entry.id),
          related_task_id=Some(execution.task_id),
          related_proposal_id=execution.proposal_id,
          related_run_id=execution.run_id,
        ),
      )
      return None
    }
  }
  state.record_event(
    @core.TownEvent::new(
      id="event-persist-\{entry.id}-\{execution.task_id}",
      kind="persist",
      detail="MoonBook persisted \{execution.task_id}: pages=\{outcome.updated_pages.length()} review=\{outcome.review_queued} evidence=\{outcome.evidence_id}",
      related_book_id=Some(entry.id),
      related_task_id=Some(execution.task_id),
      related_proposal_id=execution.proposal_id,
      related_run_id=execution.run_id,
    ),
  )
  Some(outcome)
}

///|
fn execution_after_successful_book_persist(
  execution : @core.TaskExecutionRecord,
  outcome : @moonbook.PersistResultOutcome,
  tick : Int,
) -> @core.TaskExecutionRecord {
  let status = match execution.status {
    @core.TaskExecutionStatus::Failed
    | @core.TaskExecutionStatus::Stale
    | @core.TaskExecutionStatus::AwaitingPersistence =>
      if outcome.review_queued {
        @core.TaskExecutionStatus::ReviewQueued
      } else {
        @core.TaskExecutionStatus::Completed
      }
    _ => execution.status
  }
  if status == execution.status {
    return execution
  }
  let decision = if outcome.review_queued {
    "persisted-review"
  } else {
    "persisted"
  }
  copy_execution_with(
    execution,
    status~,
    summary="\{execution.summary}\nkeeper_auto_triage: persisted_terminal_result\npersisted_result_review: \{outcome.review_queued}\npersisted_evidence_id: \{outcome.evidence_id}",
    heartbeat_tick=tick,
    next_retry_tick=None,
    result_decision=decision,
    requires_review=outcome.review_queued,
    notify_town=outcome.notify_town,
  )
}
