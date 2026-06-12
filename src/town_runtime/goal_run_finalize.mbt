///|
async fn finalize_goal_book_entry(
  state : @core.TownState,
  entry : @moonbook.BookCatalogEntry,
  pending_review_baseline : Int,
  task_ids : Array[String],
) -> Unit {
  let generated_index = match
    build_goal_book_workspace_or_record_error(state, entry) {
    Some(index) => index
    None => return
  }
  let summary = match summarize_goal_book_or_record_error(state, entry) {
    Some(summary) => summary
    None => return
  }
  let quality_gaps = @research_quality.research_quality_gaps(entry)
  queue_goal_book_reviews_if_needed(
    state, entry, summary, pending_review_baseline, task_ids, quality_gaps,
  )
  record_goal_book_projection_events(
    state, entry, generated_index, summary, quality_gaps,
  )
}

///|
async fn build_goal_book_workspace_or_record_error(
  state : @core.TownState,
  entry : @moonbook.BookCatalogEntry,
) -> String? {
  let generated_index = @moonbook.build_workspace(entry) catch {
    error => {
      record_goal_book_error_event(
        state,
        entry,
        phase="build",
        detail="MoonBook build failed for \{entry.id}: \{error}",
      )
      return None
    }
  }
  Some(generated_index)
}

///|
async fn summarize_goal_book_or_record_error(
  state : @core.TownState,
  entry : @moonbook.BookCatalogEntry,
) -> @moonbook.BookStateSummary? {
  let summary = @moonbook.summarize_state(entry) catch {
    error => {
      record_goal_book_error_event(
        state,
        entry,
        phase="summary",
        detail="MoonBook summary failed for \{entry.id}: \{error}",
      )
      return None
    }
  }
  Some(summary)
}

///|
fn record_goal_book_error_event(
  state : @core.TownState,
  entry : @moonbook.BookCatalogEntry,
  phase~ : String,
  detail~ : String,
) -> Unit {
  state.record_event(
    @core.TownEvent::new(
      id="event-\{phase}-\{entry.id}",
      kind="error",
      detail~,
      related_book_id=Some(entry.id),
    ),
  )
}

///|
async fn queue_goal_book_reviews_if_needed(
  state : @core.TownState,
  entry : @moonbook.BookCatalogEntry,
  summary : @moonbook.BookStateSummary,
  pending_review_baseline : Int,
  task_ids : Array[String],
  quality_gaps : Array[String],
) -> Unit {
  if goal_book_has_new_pending_reviews(summary, pending_review_baseline) {
    queue_book_review_backlog(
      state,
      entry.id,
      task_ids,
      summary.pending_review_count,
    )
  }
  if !quality_gaps.is_empty() {
    queue_research_quality_gate(state, entry.id, task_ids, quality_gaps)
  } else {
    @research_quality.write_research_quality_review_resolved(
      entry, "post-run quality gate",
    )
    complete_recovered_research_bootstrap_if_clean(state, entry.id, task_ids)
  }
}

///|
fn goal_book_has_new_pending_reviews(
  summary : @moonbook.BookStateSummary,
  pending_review_baseline : Int,
) -> Bool {
  summary.pending_review_count > pending_review_baseline
}

///|
fn record_goal_book_projection_events(
  state : @core.TownState,
  entry : @moonbook.BookCatalogEntry,
  generated_index : String,
  summary : @moonbook.BookStateSummary,
  quality_gaps : Array[String],
) -> Unit {
  state.record_event(goal_book_projection_event(entry, generated_index))
  state.record_event(goal_book_summary_event(entry, summary, quality_gaps))
}

///|
fn goal_book_projection_event(
  entry : @moonbook.BookCatalogEntry,
  generated_index : String,
) -> @core.TownEvent {
  @core.TownEvent::new(
    id="event-build-\{entry.id}",
    kind="projection",
    detail="Generated site for \{entry.id}: \{generated_index}",
    related_book_id=Some(entry.id),
  )
}

///|
fn goal_book_summary_event(
  entry : @moonbook.BookCatalogEntry,
  summary : @moonbook.BookStateSummary,
  quality_gaps : Array[String],
) -> @core.TownEvent {
  @core.TownEvent::new(
    id="event-summary-\{entry.id}",
    kind="summary",
    detail=goal_book_summary_event_detail(entry, summary, quality_gaps),
    related_book_id=Some(entry.id),
  )
}

///|
fn goal_book_summary_event_detail(
  entry : @moonbook.BookCatalogEntry,
  summary : @moonbook.BookStateSummary,
  quality_gaps : Array[String],
) -> String {
  let readiness = @research_quality.ResearchReadiness::from_summary(
    summary,
    extra_gaps=quality_gaps,
  )
  [
    "Book summary \{entry.id}:",
    "pages=\{summary.page_count}",
    "domain_evidence=\{summary.evidence_count}",
    "operational_evidence=\{summary.operational_evidence_count}",
    "total_evidence=\{summary.total_evidence_count}",
    "pending_review=\{summary.pending_review_count}",
    "quality_gaps=\{quality_gaps.length()}",
    "readiness=\{readiness.summary_line()}",
  ].join(" ")
}
