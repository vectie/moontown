///|
/// Reconcile the current native execution with its exact, explicit Book review.
/// This owner entry never dispatches work, approves a review or accepts a goal.
///
/// ```mbt check
/// test {
///   ignore(@town_runtime.reconcile_native_wenyu_review)
/// }
/// ```
pub async fn reconcile_native_wenyu_review(
  state : @core.TownState,
  entry : @moonbook.BookCatalogEntry,
  task_id : String,
  tick : Int,
) -> Unit {
  let execution = match @core.find_execution(state, task_id) {
    Some(execution) => execution
    None => return
  }
  if !@build_pipeline_runtime.is_wenyu_native_execution(execution) ||
    !(execution.status == ReviewQueued ||
    execution.status == AwaitingAcceptance ||
    [
      "native-blocked-review", "native-book-review-approved", "native-book-review-rejected",
    ].contains(execution.result_decision)) {
    return
  }
  reconcile_wenyu_review_execution(state, entry, execution, tick)
}

///|
async fn reconcile_wenyu_review_execution(
  state : @core.TownState,
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
  tick : Int,
  readback? : async (@moonbook.BookCatalogEntry, @core.TaskExecutionRecord, Int) -> @core.TaskExecutionRecord,
) -> Unit {
  if execution.result_decision == "native-book-review-rejected" ||
    @core.find_execution(state, execution.task_id) != Some(execution) {
    return
  }
  let updated = try {
    match readback {
      Some(readback) => readback(entry, execution, tick)
      None =>
        @build_pipeline_runtime.reconcile_wenyu_native_review(
          entry, execution, tick,
        )
    }
  } catch {
    error =>
      copy_execution_with(
        execution,
        status=if execution.status == AwaitingAcceptance {
          ReviewQueued
        } else {
          execution.status
        },
        summary="Saved Wenyu Book review could not be verified: " +
          error.to_string() +
          "; original-task and goal acceptance remain unevaluated",
        next_retry_tick=None,
        result_decision=if execution.status == Failed {
          "native-blocked-review"
        } else {
          "native-persisted-review"
        },
        requires_review=true,
      )
  }
  // Another state owner may have installed a newer generation while the Book
  // process was being observed. Never project the older review over that row.
  if @core.find_execution(state, execution.task_id) != Some(execution) {
    return
  }
  replace_execution_task_and_worker(state, updated)
  if updated.requires_review ||
    !["native-book-review-approved", "native-book-review-rejected"].contains(
      updated.result_decision,
    ) {
    return
  }
  let event_id = "event-native-book-review-" +
    @native_work.digest(
      updated.packet_id +
      "\n" +
      updated.result_decision +
      "\n" +
      updated.summary,
    )
  if state.events.any(event => event.id == event_id) {
    return
  }
  state.record_event(
    @core.TownEvent::new(
      id=event_id,
      kind="review",
      detail=updated.summary,
      related_task_id=Some(updated.task_id),
      related_book_id=Some(updated.book_id),
    ),
  )
}
