///|
fn civic_salon_round_record(
  schedule : CivicSalonSchedule,
  round_id : String,
  tick : Int,
  started_ms : UInt64,
  finished_ms : UInt64,
  metrics : CivicSalonMetric,
  decision : String,
  summary : String,
) -> CivicSalonRoundRecord {
  {
    id: round_id,
    salon_id: schedule.id,
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

///|
async fn append_civic_salon_round_record(
  path : String,
  record : CivicSalonRoundRecord,
) -> Unit {
  let previous = if @fs.exists(path) {
    @fs.read_file(path).text() catch {
      _ => ""
    }
  } else {
    ""
  }
  let prefix = if previous.is_empty() || previous.has_suffix("\n") {
    previous
  } else {
    "\{previous}\n"
  }
  write_text_file(path, "\{prefix}\{record.to_json().stringify()}\n")
}
