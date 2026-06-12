///|
async fn queue_research_quality_gate(
  state : @core.TownState,
  book_id : String,
  task_ids : Array[String],
  gaps : Array[String],
) -> Unit {
  let gap_summary = gaps.join("; ")
  let detail = "Research quality gate failed for \{book_id}: \{gap_summary}"
  let mut marked = 0
  write_research_quality_review_trigger_for_state(
    state, book_id, gaps, "post-run quality gate",
  )
  for task_id in task_ids {
    match @core.find_execution(state, task_id) {
      Some(execution) =>
        if execution.status is @core.TaskExecutionStatus::Completed ||
          execution.status is @core.TaskExecutionStatus::Failed ||
          execution.status is @core.TaskExecutionStatus::Stale {
          let retry_tick = if execution.attempt < 3 {
            Some(supervision_tick(state))
          } else {
            None
          }
          let updated = copy_execution_with(
            execution,
            status=@core.TaskExecutionStatus::ReviewQueued,
            summary="\{execution.summary} / quality_gate_failed=\{gaps.length()} / auto_retry=\{retry_tick != None}",
            next_retry_tick=retry_tick,
          )
          state.replace_execution(updated)
          state.replace_task(task_for_supervision(state, updated))
          sync_worker_from_execution(state, updated)
          marked += 1
        }
      None => ()
    }
  }
  state.record_event(
    @core.TownEvent::new(
      id="event-quality-\{book_id}",
      kind="review",
      detail="\{detail}; mayor marked \{marked} task(s) as review-queued and scheduled in-place repair retries when attempts remain.",
      related_book_id=Some(book_id),
    ),
  )
}

///|
async fn write_research_quality_review_trigger_for_state(
  state : @core.TownState,
  book_id : String,
  quality_gaps : Array[String],
  reason : String,
) -> Unit {
  for book in state.books {
    if book.id != book_id {
      continue
    }
    let entry = @moonbook.BookCatalogEntry::new(
      id=book.id,
      name=book.name,
      purpose=book.purpose,
      workspace_root=book.workspace_root,
      memory_scope=book.memory_scope,
      tags=book.tags,
    )
    write_research_quality_review_trigger(entry, quality_gaps, reason)
    return
  }
}

///|
fn complete_recovered_research_bootstrap_if_clean(
  state : @core.TownState,
  book_id : String,
  task_ids : Array[String],
) -> Unit {
  if !book_id.has_prefix("research-") {
    return
  }
  let mut recovered = 0
  for task_id in task_ids {
    if !task_id.contains("research-bootstrap-ingest") {
      continue
    }
    match @core.find_execution(state, task_id) {
      Some(execution) =>
        if execution.status is @core.TaskExecutionStatus::Failed ||
          execution.status is @core.TaskExecutionStatus::Stale {
          let updated = copy_execution_with(
            execution,
            status=@core.TaskExecutionStatus::Completed,
            summary="\{execution.summary} / quality_gate_recovered=clean_research_projection",
          )
          state.replace_execution(updated)
          state.replace_task(task_for_supervision(state, updated))
          sync_worker_from_execution(state, updated)
          recovered += 1
        }
      None => ()
    }
  }
  if recovered > 0 {
    state.record_event(
      @core.TownEvent::new(
        id="event-quality-recovered-\{book_id}",
        kind="recovery",
        detail="Research bootstrap for \{book_id} recovered after late worker failure because MoonBook artifacts, wiki materialization, and generated site passed quality gates.",
        related_book_id=Some(book_id),
      ),
    )
  }
}

///|
fn queue_book_review_backlog(
  state : @core.TownState,
  book_id : String,
  task_ids : Array[String],
  pending_review_count : Int,
) -> Unit {
  let mut marked = 0
  for task_id in task_ids {
    match @core.find_execution(state, task_id) {
      Some(execution) =>
        if execution.status is @core.TaskExecutionStatus::Completed {
          let updated = copy_execution_with(
            execution,
            status=@core.TaskExecutionStatus::ReviewQueued,
            summary="\{execution.summary} / pending_review=\{pending_review_count}",
          )
          state.replace_execution(updated)
          state.replace_task(task_for_supervision(state, updated))
          sync_worker_from_execution(state, updated)
          marked += 1
        }
      None => ()
    }
  }
  if marked > 0 {
    state.record_event(
      @core.TownEvent::new(
        id="event-review-backlog-\{book_id}",
        kind="review",
        detail="Book \{book_id} still has \{pending_review_count} pending review items after execution; mayor marked \{marked} task(s) as review-queued.",
        related_book_id=Some(book_id),
      ),
    )
  }
}
