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
    match standing_watch_history_decision_summary_for_task(history, task_id) {
      Some(summary) => Some(summary)
      None => standing_watch_latest_provider_decision_summary(history)
    }
  }
}

///|
async fn collapse_standing_watch_book_history(
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
) -> Unit {
  let provider_id = standing_watch_marker_value(
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
  let collapsed = remove_standing_watch_history_block(history, provider_id)
  if collapsed != history {
    write_text_file(path, collapsed)
  }
}

///|
fn remove_standing_watch_history_block(
  history : String,
  block_id : String,
) -> String {
  let heading = "### \{block_id}"
  let builder = StringBuilder::new()
  let mut skipping = false
  let mut removed = false
  for raw in history.split("\n") {
    let line = raw.to_owned()
    if line.has_prefix("### ") {
      if line.trim().to_owned() == heading {
        skipping = true
        removed = true
        continue
      }
      skipping = false
    }
    if !skipping {
      builder.write_string(line)
      builder.write_char('\n')
    }
  }
  if removed {
    builder.to_string()
  } else {
    history
  }
}
