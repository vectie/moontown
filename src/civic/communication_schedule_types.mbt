///|
#derive(Debug, Eq, ToJson, FromJson)
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
  round_count : Int32
  latest_round_id : String
  latest_summary : String
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct CivicCommunicationRoundRecord {
  id : String
  scenario_id : String
  building_id : String
  tick : Int32
  round_number : Int32
  started_ms : UInt64
  finished_ms : UInt64
  participant_count : Int32
  idea_count : Int32
  research_question_count : Int32
  participant_idea_links : Int32
  idea_return_home_count : Int32
  structural_effectiveness_score : Int32
  decision : String
  summary : String
}

///|
pub fn CivicCommunicationSchedule::new(
  id~ : String,
  title~ : String,
  building_id~ : String,
  topic~ : String,
  interval_ms~ : UInt64 = 1_800_000UL,
  participant_book_ids~ : Array[String] = [],
  enabled~ : Bool = true,
  last_run_ms~ : UInt64 = 0UL,
  next_due_ms~ : UInt64 = 0UL,
  round_count~ : Int32 = 0,
  latest_round_id~ : String = "",
  latest_summary~ : String = "",
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
