///|
pub enum HealthLevel {
  Healthy
  Degraded
  Critical
} derive(Show, Eq)

///|
pub struct WorkerHealth {
  worker_id : String
  level : HealthLevel
  note : String
} derive(Show, Eq)

///|
pub struct BookHealth {
  book_id : String
  level : HealthLevel
  note : String
} derive(Show, Eq)

///|
pub struct Anomaly {
  title : String
  detail : String
} derive(Show, Eq)

///|
pub struct RecoveryAction {
  kind : String
  detail : String
} derive(Show, Eq)

///|
pub struct HealthReport {
  worker_health : Array[WorkerHealth]
  book_health : Array[BookHealth]
  anomalies : Array[Anomaly]
} derive(Show, Eq)

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
        if !standing_watch_failure_superseded(executions, execution) {
          anomalies.push({
            title: "execution-failed",
            detail: "\{execution.task_id} failed after packet \{execution.packet_id}",
          })
        }
      @core.TaskExecutionStatus::Stale =>
        anomalies.push({
          title: "execution-stale",
          detail: "\{execution.task_id} missed heartbeat and needs mayor recovery",
        })
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
        if !standing_watch_failure_superseded(town.executions, execution) {
          return Critical
        }
      @core.TaskExecutionStatus::Stale => return Critical
      _ => ()
    }
  }
  Healthy
}

///|
fn standing_watch_failure_superseded(
  executions : Array[@core.TaskExecutionRecord],
  failed : @core.TaskExecutionRecord,
) -> Bool {
  let prefix = match standing_watch_task_prefix(failed.task_id) {
    Some(prefix) => prefix
    None => return false
  }
  let mut after_failed = false
  for execution in executions {
    if execution.task_id == failed.task_id {
      after_failed = true
      continue
    }
    if !after_failed || execution.book_id != failed.book_id {
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
fn standing_watch_task_prefix(task_id : String) -> String? {
  let normalized = task_id.to_lower()
  if !normalized.has_prefix("standing-") || !normalized.contains("-tick-") {
    return None
  }
  let parts = task_id.split("-tick-").to_array()
  if parts.length() == 0 || parts[0].is_empty() {
    None
  } else {
    Some(parts[0].to_string())
  }
}
