///|
fn worker_status_for(model : Model, offset : Int) -> @core.WorkerStatus {
  let cycle = (model.tick + offset) % 9
  if mayor_recovery_active(model) {
    worker_operating_cycle_status(cycle)
  } else if model.stability < 30 && (cycle == 2 || cycle == 6) {
    Waiting
  } else if model.pressure > 76 && (cycle == 1 || cycle == 4 || cycle == 7) {
    Waiting
  } else {
    worker_operating_cycle_status(cycle)
  }
}

///|
fn worker_operating_cycle_status(cycle : Int) -> @core.WorkerStatus {
  match cycle {
    0 | 3 | 6 => Running
    1 | 4 | 7 => Waiting
    _ => Idle
  }
}

///|
fn worker_zone_key(book_id : String, status : @core.WorkerStatus) -> String {
  match status {
    Blocked => "anomaly-corner"
    Idle => "book-\{book_id}"
    Waiting => "book-\{book_id}"
    Offline => "gate"
    Running => "book-\{book_id}"
  }
}

///|
fn worker_load(model : Model, offset : Int, status : @core.WorkerStatus) -> Int {
  let baseline = model.pressure + offset * 6
  match status {
    Running => clamp_metric(baseline + 16)
    Waiting => clamp_metric(baseline - 8)
    Idle => clamp_metric(baseline - 18)
    Blocked => clamp_metric(baseline + 26)
    Offline => 0
  }
}

///|
fn worker_summary(status : @core.WorkerStatus, load : Int) -> String {
  match status {
    Running => "Serving residents and town quests at load \{load}%."
    Waiting => "Waiting in the plaza for the mayor's next supervised handoff."
    Idle => "Resting in the yard while memory and social signals settle."
    Blocked => "Blocked by civic queue pressure or failed offline linkage."
    Offline => "Offline and unavailable."
  }
}
