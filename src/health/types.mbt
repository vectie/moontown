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
