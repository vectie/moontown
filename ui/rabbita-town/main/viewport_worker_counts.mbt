priv struct WorkerCountSummary {
  total : Int
  idle : Int
  running : Int
  waiting : Int
  blocked : Int
  offline : Int
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
  WorkerCountSummary::{ total: 0, idle: 0, running: 0, waiting: 0, blocked: 0, offline: 0 }
}

///|
fn WorkerCountSummary::add(
  self : WorkerCountSummary,
  worker : WorkerSim,
) -> WorkerCountSummary {
  match worker.status {
    @core.WorkerStatus::Idle => { ..self, total: self.total + 1, idle: self.idle + 1 }
    @core.WorkerStatus::Running => { ..self, total: self.total + 1, running: self.running + 1 }
    @core.WorkerStatus::Waiting => { ..self, total: self.total + 1, waiting: self.waiting + 1 }
    @core.WorkerStatus::Blocked => { ..self, total: self.total + 1, blocked: self.blocked + 1 }
    @core.WorkerStatus::Offline => { ..self, total: self.total + 1, offline: self.offline + 1 }
  }
}

///|
fn WorkerCountSummary::online(self : WorkerCountSummary) -> Int {
  self.total - self.offline
}

///|
fn WorkerCountSummary::available(self : WorkerCountSummary) -> Int {
  self.idle + self.waiting
}
