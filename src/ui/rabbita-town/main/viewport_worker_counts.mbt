///|
priv struct WorkerCountSummary {
  total : Int32
  idle : Int32
  running : Int32
  waiting : Int32
  blocked : Int32
  offline : Int32
}

///|
fn worker_count_summary(workers : Array[WorkerSim]) -> WorkerCountSummary {
  let mut summary = worker_count_summary_empty()
  for worker in workers {
    summary = summary.add(worker)
  }
  summary
}

///|
fn worker_count_summary_empty() -> WorkerCountSummary {
  { total: 0, idle: 0, running: 0, waiting: 0, blocked: 0, offline: 0, }
}

///|
fn WorkerCountSummary::add(
  self : WorkerCountSummary,
  worker : WorkerSim,
) -> WorkerCountSummary {
  match worker.status {
    Idle => { ..self, total: self.total + 1, idle: self.idle + 1, }
    Running => { ..self, total: self.total + 1, running: self.running + 1, }
    Waiting => { ..self, total: self.total + 1, waiting: self.waiting + 1, }
    Blocked => { ..self, total: self.total + 1, blocked: self.blocked + 1, }
    Offline => { ..self, total: self.total + 1, offline: self.offline + 1, }
  }
}

///|
fn WorkerCountSummary::online(self : WorkerCountSummary) -> Int32 {
  self.total - self.offline
}
