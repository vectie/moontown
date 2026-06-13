///|
/// Returns whether a civic communication schedule is due at `now_ms`.
pub fn civic_communication_is_due(
  schedule : CivicCommunicationSchedule,
  now_ms : UInt64,
) -> Bool {
  schedule.enabled && now_ms >= schedule.next_due_ms
}

///|
/// Marks a civic communication schedule complete and advances its cadence.
pub fn complete_civic_communication_schedule(
  schedule : CivicCommunicationSchedule,
  now_ms : UInt64,
  round_id : String,
  summary : String,
) -> CivicCommunicationSchedule {
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
/// Builds the next round id for a civic communication schedule.
pub fn civic_communication_round_id(
  schedule : CivicCommunicationSchedule,
) -> String {
  "\{schedule.id}-round-\{schedule.round_count + 1}"
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
  {
    id: round_id,
    scenario_id: schedule.id,
    building_id: schedule.building_id,
    tick,
    round_number: schedule.round_count + 1,
    started_ms,
    finished_ms,
    participant_count: metrics.participant_count,
    idea_count: metrics.idea_count,
    research_question_count: metrics.research_question_count,
    participant_idea_links: metrics.participant_idea_links,
    idea_return_home_count: metrics.idea_return_home_count,
    structural_effectiveness_score: metrics.structural_effectiveness_score,
    decision,
    summary,
  }
}
