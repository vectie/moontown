///|
fn dashboard_overview_section(
  town : @core.TownState,
  report : @health.HealthReport,
) -> DashboardSection {
  let health_line = if report.anomalies.is_empty() {
    "status: calm routes and clean patrol"
  } else {
    "status: \{report.anomalies.length()} anomaly signals on the board"
  }
  {
    title: "Overview",
    lines: [
      "town: \{town.config.name}",
      "books online: \{town.books.length()}",
      health_line,
      "packets: \{count_execution_status(town, PacketReady)} ready",
      "imports: \{count_execution_status(town, ProposalImported)} imported",
      "runs: \{running_like_count(town)} active lifecycle records",
    ],
  }
}

///|
fn is_mayor_book(book : @core.BookRef) -> Bool {
  book.id == "town" || book.id == "moontown" || book.id == "mayor"
}

///|
fn count_execution_status(
  town : @core.TownState,
  status : @core.TaskExecutionStatus,
) -> Int {
  count_executions_by_status(town, fn(candidate) { candidate == status })
}

///|
fn running_like_count(town : @core.TownState) -> Int {
  count_executions_by_status(town, dashboard_execution_status_running_like)
}

///|
fn count_executions_by_status(
  town : @core.TownState,
  predicate : (@core.TaskExecutionStatus) -> Bool,
) -> Int {
  let mut count = 0
  for execution in town.executions {
    if predicate(execution.status) {
      count += 1
    }
  }
  count
}

///|
fn dashboard_execution_status_running_like(
  status : @core.TaskExecutionStatus,
) -> Bool {
  match status {
    RunConfirmed | Running | AwaitingPersistence | ReviewQueued | Stale => true
    _ => false
  }
}
