///|
pub fn civic_communication_is_due(
  schedule : CivicCommunicationSchedule,
  now_ms : UInt64,
) -> Bool {
  @civic.civic_communication_is_due(schedule, now_ms)
}

///|
fn complete_civic_communication_schedule(
  schedule : CivicCommunicationSchedule,
  now_ms : UInt64,
  round_id : String,
  summary : String,
) -> CivicCommunicationSchedule {
  @civic.complete_civic_communication_schedule(
    schedule, now_ms, round_id, summary,
  )
}

///|
fn civic_communication_round_id(
  schedule : CivicCommunicationSchedule,
) -> String {
  @civic.civic_communication_round_id(schedule)
}
