///|
pub fn civic_salon_is_due(
  schedule : CivicCommunicationSchedule,
  now_ms : UInt64,
) -> Bool {
  @civic.civic_salon_is_due(schedule, now_ms)
}

///|
fn complete_civic_salon_schedule(
  schedule : CivicCommunicationSchedule,
  now_ms : UInt64,
  round_id : String,
  summary : String,
) -> CivicCommunicationSchedule {
  @civic.complete_civic_salon_schedule(schedule, now_ms, round_id, summary)
}

///|
fn civic_salon_round_id(schedule : CivicCommunicationSchedule) -> String {
  @civic.civic_salon_round_id(schedule)
}
