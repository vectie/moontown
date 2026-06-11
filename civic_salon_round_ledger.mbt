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
  @civic.civic_salon_round_record(
    schedule, round_id, tick, started_ms, finished_ms, metrics, decision, summary,
  )
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
