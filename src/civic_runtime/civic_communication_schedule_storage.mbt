///|
pub async fn load_or_create_civic_communication_schedules(
  path? : String = default_civic_communication_schedule_path(),
) -> Array[CivicCommunicationSchedule] {
  if @fs.exists(path) {
    let text = @fs.read_file(path).text() catch { _ => "" }
    if !text.trim().is_empty() {
      let parsed = @json.parse(text) catch { _ => Json::array([]) }
      let schedules : Array[CivicCommunicationSchedule] = @json.from_json(
        parsed,
      ) catch {
        _ => []
      }
      if schedules.length() > 0 {
        let normalized = schedules.map(normalize_civic_salon_schedule)
        if normalized != schedules {
          save_civic_salon_schedules(path, normalized)
        }
        return normalized
      }
    }
  }
  let schedules = default_civic_salon_schedules()
  save_civic_salon_schedules(path, schedules)
  schedules
}

///|
async fn load_or_create_civic_salon_schedules(
  path? : String = default_civic_salon_schedule_path(),
) -> Array[CivicCommunicationSchedule] {
  load_or_create_civic_communication_schedules(path~)
}

///|
fn normalize_civic_salon_schedule(
  schedule : CivicCommunicationSchedule,
) -> CivicCommunicationSchedule {
  {
    ..schedule,
    latest_summary: normalize_civic_pending_summary(schedule.latest_summary),
  }
}

///|
pub fn normalize_civic_pending_summary(summary : String) -> String {
  if summary.has_prefix("Blocked ") &&
    summary.contains("status=RunConfirmed") &&
    summary.contains(" is Pending.") {
    "Running \{summary[8:]}"
  } else {
    summary
  }
}

///|
pub async fn save_civic_communication_schedules(
  path : String,
  schedules : Array[CivicCommunicationSchedule],
) -> Unit {
  @support.write_text_file(path, schedules.to_json().stringify(indent=2))
}

///|
async fn save_civic_salon_schedules(
  path : String,
  schedules : Array[CivicCommunicationSchedule],
) -> Unit {
  save_civic_communication_schedules(path, schedules)
}
