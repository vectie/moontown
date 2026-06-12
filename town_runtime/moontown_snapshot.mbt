///|
fn snapshot_requires_refresh(snapshot : @storage.TownSnapshot) -> Bool {
  snapshot_has_legacy_workspace_root(snapshot) ||
  snapshot_has_duplicate_execution_task_ids(snapshot) ||
  snapshot_has_refreshable_execution_failure(snapshot)
}

///|
fn snapshot_has_legacy_workspace_root(snapshot : @storage.TownSnapshot) -> Bool {
  snapshot.town.books.any(book_workspace_root_requires_refresh)
}

///|
fn book_workspace_root_requires_refresh(book : @core.BookRef) -> Bool {
  book.workspace_root.contains("/workspace/")
}

///|
fn snapshot_has_duplicate_execution_task_ids(
  snapshot : @storage.TownSnapshot,
) -> Bool {
  let seen : Array[String] = []
  for execution in snapshot.town.executions {
    if seen.contains(execution.task_id) {
      return true
    }
    seen.push(execution.task_id)
  }
  false
}

///|
fn snapshot_has_refreshable_execution_failure(
  snapshot : @storage.TownSnapshot,
) -> Bool {
  snapshot.town.executions.any(fn(execution : @core.TaskExecutionRecord) {
    execution_summary_requires_snapshot_refresh(execution.summary)
  })
}

///|
fn execution_summary_requires_snapshot_refresh(summary : String) -> Bool {
  for marker in snapshot_refresh_execution_summary_markers() {
    if summary.contains(marker) {
      return true
    }
  }
  false
}

///|
fn snapshot_refresh_execution_summary_markers() -> Array[String] {
  [
    "Synthetic lifecycle", "No such file or directory", "MoonBook task planning failed",
    "metadata must be object", "Unknown external proposal profile",
  ]
}
