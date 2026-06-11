///|
async fn standing_watch_observed_for_auto_triage(
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
  snapshot_path : String,
) -> @core.TaskExecutionRecord {
  let observed = standing_watch_execution_with_book_decision(entry, execution)
  let decision = @standing_watch_policy.standing_watch_decision_from_execution(
    observed,
  )
  if decision != @core.WatcherDecisionKind::NeedsReview {
    return observed
  }
  match
    standing_watch_no_change_summary_from_book_result(snapshot_path, execution) {
    Some(summary) =>
      copy_execution_with(observed, summary="\{observed.summary}\n\{summary}")
    None => observed
  }
}

///|
async fn standing_watch_no_change_summary_from_book_result(
  snapshot_path : String,
  execution : @core.TaskExecutionRecord,
) -> String? {
  let path = standing_watch_book_result_path(snapshot_path, execution.task_id)
  if !@fs.exists(path) {
    return None
  }
  let parsed = @json.parse(@fs.read_file(path).text()) catch {
    _ => return None
  }
  let result : @moonbook.BookResult = @json.from_json(parsed) catch {
    _ => return None
  }
  if result.requires_review || !result.memory_candidates.is_empty() {
    return None
  }
  if @standing_watch_policy.standing_watch_marker_decision(
      result.summary.to_lower(),
    ) !=
    None {
    return None
  }
  if !result.summary.contains("Workflow completed") {
    return None
  }
  Some(standing_watch_empty_completion_no_change_summary(execution.task_id))
}

///|
fn standing_watch_empty_completion_no_change_summary(
  task_id : String,
) -> String {
  standing_watch_empty_completion_no_change_lines(task_id).join("\n")
}

///|
fn standing_watch_empty_completion_no_change_lines(
  task_id : String,
) -> Array[String] {
  [
    "standing_goal_decision: no_change",
    "delta_score: 0",
    "new_source_count: 0",
    "next_check_hint: normal",
    "checked_sources_count: 0",
    "new_sources_found: 0",
    "accepted_facts_count: 0",
    "rejected_facts_count: 0",
    "wiki_pages_changed_count: 0",
    "book_changed: no",
    "book_watch_record_id: \{task_id}",
    standing_watch_empty_completion_no_change_reason(),
  ]
}

///|
fn standing_watch_empty_completion_no_change_reason() -> String {
  "MoonBook result was an empty, non-review operational completion; mayor classified it as no_change so it does not block live autonomy."
}

///|
fn standing_watch_book_result_path(
  snapshot_path : String,
  task_id : String,
) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  let root = if base == "." || base == "" { ".moontown" } else { base }
  "\{root}/book-results/\{task_id}.json"
}
