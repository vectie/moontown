///|
fn worker_status_for(model : Model, offset : Int) -> @core.WorkerStatus {
  let cycle = (model.tick + offset) % 9
  if mayor_recovery_active(model) {
    worker_balanced_cycle_status(cycle)
  } else if model.stability < 30 && (cycle == 2 || cycle == 6) {
    @core.WorkerStatus::Waiting
  } else if model.pressure > 76 && (cycle == 1 || cycle == 4 || cycle == 7) {
    @core.WorkerStatus::Waiting
  } else {
    worker_strategy_cycle_status(model.strategy, cycle)
  }
}

///|
fn worker_strategy_cycle_status(strategy : Strategy, cycle : Int) -> @core.WorkerStatus {
  match strategy {
    Strategy::Balanced => worker_balanced_cycle_status(cycle)
    Strategy::Throughput => worker_throughput_cycle_status(cycle)
    Strategy::Recovery => worker_recovery_cycle_status(cycle)
  }
}

///|
fn worker_balanced_cycle_status(cycle : Int) -> @core.WorkerStatus {
  match cycle {
    0 | 3 | 6 => @core.WorkerStatus::Running
    1 | 4 | 7 => @core.WorkerStatus::Waiting
    _ => @core.WorkerStatus::Idle
  }
}

///|
fn worker_throughput_cycle_status(cycle : Int) -> @core.WorkerStatus {
  match cycle {
    2 | 5 => @core.WorkerStatus::Waiting
    7 => @core.WorkerStatus::Idle
    _ => @core.WorkerStatus::Running
  }
}

///|
fn worker_recovery_cycle_status(cycle : Int) -> @core.WorkerStatus {
  match cycle {
    2 | 5 => @core.WorkerStatus::Running
    1 | 4 | 7 => @core.WorkerStatus::Waiting
    _ => @core.WorkerStatus::Idle
  }
}

///|
fn worker_zone_key(book_id : String, status : @core.WorkerStatus) -> String {
  match status {
    @core.WorkerStatus::Blocked => "anomaly-corner"
    @core.WorkerStatus::Idle => "book-\{book_id}"
    @core.WorkerStatus::Waiting => "book-\{book_id}"
    @core.WorkerStatus::Offline => "gate"
    @core.WorkerStatus::Running => "book-\{book_id}"
  }
}

///|
fn worker_load(model : Model, offset : Int, status : @core.WorkerStatus) -> Int {
  let baseline = model.pressure + offset * 6
  match status {
    @core.WorkerStatus::Running => clamp_metric(baseline + 16)
    @core.WorkerStatus::Waiting => clamp_metric(baseline - 8)
    @core.WorkerStatus::Idle => clamp_metric(baseline - 18)
    @core.WorkerStatus::Blocked => clamp_metric(baseline + 26)
    @core.WorkerStatus::Offline => 0
  }
}

///|
fn worker_summary(status : @core.WorkerStatus, load : Int) -> String {
  match status {
    @core.WorkerStatus::Running =>
      "Serving residents and town quests at load \{load}%."
    @core.WorkerStatus::Waiting =>
      "Waiting in the plaza for the mayor's next supervised handoff."
    @core.WorkerStatus::Idle =>
      "Resting in the yard while memory and social signals settle."
    @core.WorkerStatus::Blocked =>
      "Blocked by civic queue pressure or failed offline linkage."
    @core.WorkerStatus::Offline => "Offline and unavailable."
  }
}
