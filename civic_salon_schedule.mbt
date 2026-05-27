///|
pub fn default_civic_salon_schedules() -> Array[CivicSalonSchedule] {
  []
}

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
pub async fn load_or_create_civic_salon_schedules(
  path? : String = default_civic_salon_schedule_path(),
) -> Array[CivicSalonSchedule] {
  if @fs.exists(path) {
    let text = @fs.read_file(path).text() catch { _ => "" }
    if !text.trim().is_empty() {
      let parsed = @json.parse(text) catch { _ => Json::array([]) }
      let schedules : Array[CivicSalonSchedule] = @json.from_json(parsed) catch {
        _ => []
      }
      if schedules.length() > 0 {
        return schedules
      }
    }
  }
  let schedules = default_civic_salon_schedules()
  save_civic_salon_schedules(path, schedules)
  schedules
}

///|
pub async fn save_civic_salon_schedules(
  path : String,
  schedules : Array[CivicSalonSchedule],
) -> Unit {
  write_text_file(path, schedules.to_json().stringify(indent=2))
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

///|
pub async fn render_civic_salon_schedule_status(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  let schedules = load_or_create_civic_salon_schedules(
    path=default_civic_salon_schedule_path(snapshot_path~),
  )
  let now_ms = @env.now()
  let builder = StringBuilder::new()
  builder.write_string("# Civic Salon Schedule Status\n\n")
  builder.write_string(
    "| Salon | Building | Enabled | Due | Interval min | Rounds | Latest |\n",
  )
  builder.write_string("| --- | --- | ---:| ---:| ---:| ---:| --- |\n")
  for schedule in schedules {
    builder.write_string(
      "|\{schedule.title}|\{schedule.building_id}|\{schedule.enabled}|\{civic_salon_is_due(schedule, now_ms)}|\{schedule.interval_ms / 60_000UL}|\{schedule.round_count}|\{schedule.latest_round_id}|\n",
    )
  }
  builder.to_string()
}
