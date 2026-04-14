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
        anomalies.push({
          title: "execution-failed",
          detail: "\{execution.task_id} failed after packet \{execution.packet_id}",
        })
      @core.TaskExecutionStatus::ReviewQueued =>
        anomalies.push({
          title: "review-queued",
          detail: "\{execution.task_id} is waiting for keeper review sync",
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
      @core.TaskExecutionStatus::Failed => return Critical
      @core.TaskExecutionStatus::ReviewQueued => return Degraded
      _ => ()
    }
  }
  Healthy
}
