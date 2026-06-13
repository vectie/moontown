///|
/// Returns whether a civic communication schedule is due at `now_ms`.
pub fn civic_communication_is_due(
  schedule : CivicCommunicationSchedule,
  now_ms : UInt64,
) -> Bool {
  civic_salon_is_due(schedule, now_ms)
}

///|
/// Marks a civic communication schedule complete and advances its cadence.
pub fn complete_civic_communication_schedule(
  schedule : CivicCommunicationSchedule,
  now_ms : UInt64,
  round_id : String,
  summary : String,
) -> CivicCommunicationSchedule {
  complete_civic_salon_schedule(schedule, now_ms, round_id, summary)
}

///|
/// Builds the next round id for a civic communication schedule.
pub fn civic_communication_round_id(
  schedule : CivicCommunicationSchedule,
) -> String {
  civic_salon_round_id(schedule)
}

///|
/// Builds an append-only round record for a civic communication session.
pub fn civic_communication_round_record(
  schedule : CivicCommunicationSchedule,
  round_id : String,
  tick : Int,
  started_ms : UInt64,
  finished_ms : UInt64,
  metrics : CivicCommunicationMetric,
  decision : String,
  summary : String,
) -> CivicCommunicationRoundRecord {
  civic_salon_round_record(
    schedule, round_id, tick, started_ms, finished_ms, metrics, decision, summary,
  )
}

///|
/// Computes structural exchange/reduction/distribution metrics.
pub fn civic_communication_metrics(
  scenario : CivicCommunicationScenario,
  participants : Array[CivicCommunicationParticipantBook],
  ideas : Array[CivicCommunicationIdea],
) -> CivicCommunicationMetric {
  civic_salon_metrics(scenario, participants, ideas)
}

///|
/// Counts the raw signals that feed civic communication metrics.
pub fn civic_communication_metric_counts(
  participants : Array[CivicCommunicationParticipantBook],
  ideas : Array[CivicCommunicationIdea],
) -> CivicCommunicationMetricCounts {
  civic_salon_metric_counts(participants, ideas)
}

///|
/// Returns reduced outputs routed back to a participant's home book.
pub fn civic_communication_returned_ideas_for_book(
  book_id : String,
  ideas : Array[CivicCommunicationIdea],
) -> Array[CivicCommunicationIdea] {
  civic_salon_returned_ideas_for_book(book_id, ideas)
}
