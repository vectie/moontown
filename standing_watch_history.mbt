///|
async fn standing_watch_execution_with_book_decision(
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
) -> @core.TaskExecutionRecord {
  match standing_watch_book_decision_summary(entry, execution.task_id) {
    Some(summary) =>
      copy_execution_with(execution, summary="\{execution.summary}\n\{summary}")
    None => execution
  }
}

///|
async fn standing_watch_book_decision_summary(
  entry : @moonbook.BookCatalogEntry,
  task_id : String,
) -> String? {
  let root = @moonbook.workspace_root(entry)
  let history = read_text_or_empty("\{root}/wiki/history/standing-watch.md")
  if history.trim().is_blank() {
    None
  } else {
    match
      @standing_watch_policy.standing_watch_history_decision_summary_for_task(
        history, task_id,
      ) {
      Some(summary) => Some(summary)
      None =>
        @standing_watch_policy.standing_watch_latest_provider_decision_summary(
          history,
        )
    }
  }
}

///|
async fn collapse_standing_watch_book_history(
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
) -> Unit {
  let provider_id = @standing_watch_policy.standing_watch_marker_value(
    execution.summary,
    "book_watch_record_id",
  ).unwrap_or("")
  if provider_id.is_empty() {
    return
  }
  let root = @moonbook.workspace_root(entry)
  let path = "\{root}/wiki/history/standing-watch.md"
  let history = read_text_or_empty(path)
  if history.trim().is_blank() {
    return
  }
  let collapsed = @standing_watch_policy.remove_standing_watch_history_block(
    history, provider_id,
  )
  if collapsed != history {
    write_text_file(path, collapsed)
  }
}
