///|
pub enum HealthLevel {
  Healthy
  Degraded
  Critical
} derive(Debug, Eq)

///|
pub impl Show for HealthLevel with fn output(
  self : HealthLevel,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    match self {
      Healthy => "Healthy"
      Degraded => "Degraded"
      Critical => "Critical"
    },
  )
}

///|
pub struct WorkerHealth {
  worker_id : String
  level : HealthLevel
  note : String
} derive(Debug, Eq)

///|
pub impl Show for WorkerHealth with fn output(
  self : WorkerHealth,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    "WorkerHealth(worker_id=\{self.worker_id}, level=\{self.level.to_string()}, note=\{self.note})",
  )
}

///|
pub struct BookHealth {
  book_id : String
  level : HealthLevel
  note : String
} derive(Debug, Eq)

///|
pub impl Show for BookHealth with fn output(self : BookHealth, logger : &Logger) -> Unit {
  logger.write_string(
    "BookHealth(book_id=\{self.book_id}, level=\{self.level.to_string()}, note=\{self.note})",
  )
}

///|
pub struct Anomaly {
  title : String
  detail : String
} derive(Debug, Eq)

///|
pub impl Show for Anomaly with fn output(self : Anomaly, logger : &Logger) -> Unit {
  logger.write_string("Anomaly(title=\{self.title}, detail=\{self.detail})")
}

///|
pub struct RecoveryAction {
  kind : String
  detail : String
} derive(Debug, Eq)

///|
pub impl Show for RecoveryAction with fn output(
  self : RecoveryAction,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    "RecoveryAction(kind=\{self.kind}, detail=\{self.detail})",
  )
}

///|
pub struct HealthReport {
  worker_health : Array[WorkerHealth]
  book_health : Array[BookHealth]
  anomalies : Array[Anomaly]
} derive(Debug, Eq)

///|
pub impl Show for HealthReport with fn output(
  self : HealthReport,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    "HealthReport(worker_health=\{self.worker_health.length()}, book_health=\{self.book_health.length()}, anomalies=\{self.anomalies.length()})",
  )
}

///|
pub fn inspect_town(town : @core.TownState) -> HealthReport {
  let worker_health : Array[WorkerHealth] = []
  for worker in town.workers {
    let level = match worker.status {
      @core.WorkerStatus::Offline => Critical
      @core.WorkerStatus::Blocked => Degraded
      _ => Healthy
    }
    worker_health.push({
      worker_id: worker.id,
      level,
      note: worker.status.to_string(),
    })
  }
  let book_health : Array[BookHealth] = []
  for book in town.books {
    let execution_note = match latest_book_execution_note(town, book.id) {
      Some(note) => note
      None => book.purpose
    }
    book_health.push({
      book_id: book.id,
      level: book_level(town, book.id),
      note: execution_note,
    })
  }
  let anomalies = detect_anomalies(worker_health, town.executions)
  { worker_health, book_health, anomalies }
}

///|
fn detect_anomalies(
  worker_health : Array[WorkerHealth],
  executions : Array[@core.TaskExecutionRecord],
) -> Array[Anomaly] {
  let anomalies : Array[Anomaly] = []
  for item in worker_health {
    if item.level != Healthy {
      anomalies.push({
        title: "worker-health",
        detail: "\{item.worker_id} is \{item.level.to_string()}",
      })
    }
  }
  for execution in executions {
    match execution.status {
      @core.TaskExecutionStatus::Failed =>
        if !execution_issue_superseded(executions, execution) {
          anomalies.push({
            title: "execution-failed",
            detail: "\{execution.task_id} failed after packet \{execution.packet_id}",
          })
        }
      @core.TaskExecutionStatus::Stale =>
        if !execution_issue_superseded(executions, execution) {
          anomalies.push({
            title: "execution-stale",
            detail: "\{execution.task_id} missed heartbeat and needs mayor recovery",
          })
        }
      _ => ()
    }
  }
  anomalies
}

///|
pub fn recovery_actions(report : HealthReport) -> Array[RecoveryAction] {
  let actions : Array[RecoveryAction] = []
  for anomaly in report.anomalies {
    actions.push({ kind: "investigate", detail: anomaly.detail })
  }
  actions
}

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
      @core.TaskExecutionStatus::Failed =>
        if !execution_issue_superseded(town.executions, execution) {
          return Critical
        }
      @core.TaskExecutionStatus::Stale =>
        if !execution_issue_superseded(town.executions, execution) {
          return Critical
        }
      _ => ()
    }
  }
  Healthy
}

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
