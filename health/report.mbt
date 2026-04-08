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
    book_health.push({ book_id: book.id, level: Healthy, note: book.purpose })
  }
  let anomalies = detect_anomalies(worker_health)
  { worker_health, book_health, anomalies }
}

///|
fn detect_anomalies(worker_health : Array[WorkerHealth]) -> Array[Anomaly] {
  let anomalies : Array[Anomaly] = []
  for item in worker_health {
    if item.level != Healthy {
      anomalies.push({
        title: "worker-health",
        detail: "\{item.worker_id} is \{item.level.to_string()}",
      })
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
