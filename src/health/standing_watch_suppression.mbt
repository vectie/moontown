///|
fn execution_issue_superseded(
  executions : Array[@core.TaskExecutionRecord],
  issue : @core.TaskExecutionRecord,
) -> Bool {
  standing_watch_issue_superseded(executions, issue) ||
  repaired_context_packet_import_failure(issue)
}

///|
fn repaired_context_packet_import_failure(
  issue : @core.TaskExecutionRecord,
) -> Bool {
  if !issue.summary.contains("context_pages must not be empty") {
    return false
  }
  issue.context_pages.length() > 0
}

///|
fn standing_watch_issue_superseded(
  executions : Array[@core.TaskExecutionRecord],
  issue : @core.TaskExecutionRecord,
) -> Bool {
  let prefix = match standing_watch_task_prefix(issue.task_id) {
    Some(prefix) => prefix
    None => return false
  }
  if issue.summary.contains("no eligible worker") &&
    standing_watch_neighbor_completed(executions, issue, prefix) {
    return true
  }
  let mut after_issue = false
  for execution in executions {
    if execution.task_id == issue.task_id {
      after_issue = true
      continue
    }
    if !after_issue || execution.book_id != issue.book_id {
      continue
    }
    match standing_watch_task_prefix(execution.task_id) {
      Some(other_prefix) =>
        if other_prefix == prefix &&
          execution.status != @core.TaskExecutionStatus::Failed &&
          execution.status != @core.TaskExecutionStatus::Stale {
          return true
        }
      None => ()
    }
  }
  false
}

///|
fn standing_watch_neighbor_completed(
  executions : Array[@core.TaskExecutionRecord],
  failed : @core.TaskExecutionRecord,
  prefix : String,
) -> Bool {
  let failed_tick = match standing_watch_task_tick(failed.task_id) {
    Some(tick) => tick
    None => return false
  }
  for execution in executions {
    if execution.task_id == failed.task_id ||
      execution.book_id != failed.book_id {
      continue
    }
    match standing_watch_task_prefix(execution.task_id) {
      Some(other_prefix) if other_prefix == prefix =>
        if standing_watch_successful_terminal(execution.status) {
          match standing_watch_task_tick(execution.task_id) {
            Some(tick) if tick >= failed_tick - 1 && tick <= failed_tick =>
              return true
            _ => ()
          }
        }
      _ => ()
    }
  }
  false
}

///|
fn standing_watch_successful_terminal(
  status : @core.TaskExecutionStatus,
) -> Bool {
  status == @core.TaskExecutionStatus::Completed ||
  status == @core.TaskExecutionStatus::ReviewQueued
}

///|
fn standing_watch_task_prefix(task_id : String) -> String? {
  let normalized = task_id.to_lower()
  if !normalized.has_prefix("standing-") || !normalized.contains("-tick-") {
    return None
  }
  let parts = task_id.split("-tick-").to_array()
  if parts.length() == 0 || parts[0].is_empty() {
    None
  } else {
    Some(parts[0].to_owned())
  }
}

///|
fn standing_watch_task_tick(task_id : String) -> Int? {
  let parts = task_id.split("-tick-").to_array()
  if parts.length() < 2 {
    return None
  }
  let suffix = parts[1].trim()
  if suffix.is_empty() {
    return None
  }
  let mut value = 0
  for char in suffix {
    if char < '0' || char > '9' {
      return None
    }
    value = value * 10 + (char.to_int() - '0'.to_int())
  }
  Some(value)
}
