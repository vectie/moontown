///|
pub fn inspect_town(town : @core.TownState) -> HealthReport {
  let worker_health : Array[WorkerHealth] = []
  for worker in town.workers {
    let level = match worker.status {
      Offline => Critical
      Blocked => Degraded
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
