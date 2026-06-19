///|
fn latest_book_execution_note(
  town : @core.TownState,
  book_id : String,
) -> String? {
  for execution in town.executions {
    if execution.book_id == book_id {
      return Some("\{execution.status.to_string()}: \{execution.summary}")
    }
  }
  None
}

///|
fn book_level(town : @core.TownState, book_id : String) -> HealthLevel {
  for execution in town.executions {
    if execution.book_id != book_id {
      continue
    }
    match execution.status {
      Failed =>
        if !execution_issue_superseded(town.executions, execution) {
          return Critical
        }
      Stale =>
        if !execution_issue_superseded(town.executions, execution) {
          return Critical
        }
      _ => ()
    }
  }
  Healthy
}
