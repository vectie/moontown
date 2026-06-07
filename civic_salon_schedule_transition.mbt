///|
pub fn civic_salon_is_due(
  schedule : CivicSalonSchedule,
  now_ms : UInt64,
) -> Bool {
  schedule.enabled && now_ms >= schedule.next_due_ms
}

///|
fn complete_civic_salon_schedule(
  schedule : CivicSalonSchedule,
  now_ms : UInt64,
  round_id : String,
  summary : String,
) -> CivicSalonSchedule {
  let interval = if schedule.interval_ms < 1UL {
    1_800_000UL
  } else {
    schedule.interval_ms
  }
  {
    ..schedule,
    last_run_ms: now_ms,
    next_due_ms: now_ms + interval,
    round_count: schedule.round_count + 1,
    latest_round_id: round_id,
    latest_summary: summary,
  }
}

///|
fn civic_salon_round_id(schedule : CivicSalonSchedule) -> String {
  "\{schedule.id}-round-\{schedule.round_count + 1}"
}
