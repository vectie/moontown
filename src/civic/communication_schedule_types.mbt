///|
pub(all) struct CivicCommunicationSchedule {
  id : String
  title : String
  building_id : String
  topic : String
  interval_ms : UInt64
  participant_book_ids : Array[String]
  enabled : Bool
  last_run_ms : UInt64
  next_due_ms : UInt64
  round_count : Int
  latest_round_id : String
  latest_summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct CivicCommunicationRoundRecord {
  id : String
  scenario_id : String
  building_id : String
  tick : Int
  round_number : Int
  started_ms : UInt64
  finished_ms : UInt64
  participant_count : Int
  idea_count : Int
  research_question_count : Int
  participant_idea_links : Int
  idea_return_home_count : Int
  structural_effectiveness_score : Int
  decision : String
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn CivicCommunicationSchedule::new(
  id~ : String,
  title~ : String,
  building_id~ : String,
  topic~ : String,
  interval_ms? : UInt64 = 1_800_000UL,
  participant_book_ids? : Array[String] = [],
  enabled? : Bool = true,
  last_run_ms? : UInt64 = 0UL,
  next_due_ms? : UInt64 = 0UL,
  round_count? : Int = 0,
  latest_round_id? : String = "",
  latest_summary? : String = "",
) -> CivicCommunicationSchedule {
  {
    id,
    title,
    building_id,
    topic,
    interval_ms,
    participant_book_ids,
    enabled,
    last_run_ms,
    next_due_ms,
    round_count,
    latest_round_id,
    latest_summary,
  }
}
