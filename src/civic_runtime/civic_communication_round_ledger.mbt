///|
fn civic_communication_round_record(
  schedule : CivicCommunicationSchedule,
  round_id : String,
  tick : Int,
  started_ms : UInt64,
  finished_ms : UInt64,
  metrics : CivicCommunicationMetric,
  decision : String,
  summary : String,
) -> CivicCommunicationRoundRecord {
  @civic.civic_communication_round_record(
    schedule, round_id, tick, started_ms, finished_ms, metrics, decision, summary,
  )
}

///|
async fn append_civic_communication_round_record(
  path : String,
  record : CivicCommunicationRoundRecord,
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
  @support.write_text_file(path, "\{prefix}\{record.to_json().stringify()}\n")
}
