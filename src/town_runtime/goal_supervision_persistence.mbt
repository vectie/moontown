///|
async fn reconcile_persisted_non_review_outputs(
  state : @core.TownState,
  snapshot_path : String,
) -> Unit {
  let snapshot = state.executions.copy()
  for execution in snapshot {
    if execution.status != ReviewQueued {
      continue
    }
    match persisted_non_review_book_result(snapshot_path, execution.task_id) {
      Some(result) => {
        let completed = copy_execution_with(
          execution,
          status=Completed,
          summary="\{execution.summary}\nkeeper_auto_triage: persisted_non_review_result\npersisted_result_summary: \{result.summary}",
          heartbeat_tick=supervision_tick(state),
          next_retry_tick=None,
        )
        state.replace_execution(completed)
        state.replace_task(task_for_supervision(state, completed))
        sync_worker_from_execution(state, completed)
        state.record_event(
          @core.TownEvent::new(
            id="event-persisted-non-review-\{state.events.length()}-\{completed.task_id}",
            kind="review",
            detail="Mayor closed review queue for `\{completed.task_id}` because MoonBook already persisted a non-review result.",
            related_task_id=Some(completed.task_id),
            related_book_id=Some(completed.book_id),
            related_run_id=completed.run_id,
          ),
        )
      }
      None => ()
    }
  }
}

///|
async fn reconcile_persisted_terminal_outputs(
  state : @core.TownState,
  snapshot_path : String,
) -> Unit {
  let snapshot = state.executions.copy()
  for execution in snapshot {
    if execution.status != Failed &&
      execution.status != Stale &&
      execution.status != AwaitingPersistence {
      continue
    }
    match persisted_book_result(snapshot_path, execution.task_id) {
      Some(result) => {
        let outcome = recovered_persist_result_outcome(
          execution.book_id,
          result,
          evidence_id="persisted-book-result",
        )
        let reconciled = execution_after_successful_book_persist(
          execution,
          outcome,
          supervision_tick(state),
        )
        if reconciled != execution {
          state.replace_execution(reconciled)
          state.replace_task(task_for_supervision(state, reconciled))
          sync_worker_from_execution(state, reconciled)
          state.record_event(
            @core.TownEvent::new(
              id="event-persisted-terminal-\{state.events.length()}-\{reconciled.task_id}",
              kind="recovery",
              detail="Mayor reconciled `\{reconciled.task_id}` because MoonBook already has a persisted terminal result.",
              related_task_id=Some(reconciled.task_id),
              related_book_id=Some(reconciled.book_id),
              related_run_id=reconciled.run_id,
            ),
          )
        }
      }
      None => ()
    }
  }
}

///|
async fn persisted_non_review_book_result(
  snapshot_path : String,
  task_id : String,
) -> @moonbook.BookResult? {
  match persisted_book_result(snapshot_path, task_id) {
    Some(result) if !result.requires_review => Some(result)
    _ => None
  }
}

///|
async fn persisted_book_result(
  snapshot_path : String,
  task_id : String,
) -> @moonbook.BookResult? {
  let path = book_result_path_for_snapshot(snapshot_path, task_id)
  if !@fs.exists(path) {
    return None
  }
  let parsed = @json.parse(@fs.read_file(path).text()) catch {
    _ => return None
  }
  let result : @moonbook.BookResult = @json.from_json(parsed) catch {
    _ => return None
  }
  Some(result)
}

///|
fn book_result_path_for_snapshot(
  snapshot_path : String,
  task_id : String,
) -> String {
  "\{@storage.snapshot_base_dir(snapshot_path)}/book-results/\{task_id}.json"
}

///|
fn recovered_persist_result_outcome(
  book_id : String,
  result : @moonbook.BookResult,
  evidence_id~ : String,
) -> @moonbook.PersistResultOutcome {
  let review_path = if result.requires_review {
    Some("wiki/reviews/pending.md")
  } else {
    None
  }
  let event = result.to_executable_book_event(
    book_id~,
    evidence_id=Some(evidence_id),
    review_path~,
  )
  @moonbook.PersistResultOutcome::new(
    log_path="",
    updated_pages=[],
    review_queued=result.requires_review,
    notify_town=result.notify_town,
    evidence_id~,
    executable_event_path="",
    latest_executable_event_path="",
    executable_event=event,
  )
}
