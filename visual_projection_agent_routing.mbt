///|
fn visual_zone_key(
  book_id : String,
  phase : String,
  status : @core.WorkerStatus,
) -> String {
  if visual_phase_is_recovery(phase) || status == @core.WorkerStatus::Blocked {
    "anomaly-corner"
  } else if visual_phase_is_handoff(phase) {
    "city-hall"
  } else if phase == "waiting" {
    "worker-yard"
  } else if status == @core.WorkerStatus::Offline {
    "gate"
  } else {
    "book-\{book_id}"
  }
}

///|
fn visual_location_label(book_id : String, phase : String) -> String {
  if visual_phase_is_handoff(phase) {
    "city-hall"
  } else if phase == "waiting" {
    "worker-yard"
  } else if visual_phase_is_recovery(phase) {
    "anomaly-corner"
  } else {
    "book-\{book_id}"
  }
}

///|
fn visual_destination_label(book_id : String, phase : String) -> String {
  if visual_phase_is_handoff(phase) || phase == "waiting" {
    "book-\{book_id}"
  } else if visual_phase_is_keeper_bound(phase) {
    "keeper-desk-\{book_id}"
  } else if visual_phase_is_recovery(phase) {
    "recovery-yard"
  } else {
    "inside-\{book_id}"
  }
}
