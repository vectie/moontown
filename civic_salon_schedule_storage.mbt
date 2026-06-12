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
fn normalize_civic_salon_schedule(
  schedule : CivicSalonSchedule,
) -> CivicSalonSchedule {
  {
    ..schedule,
    latest_summary: normalize_civic_pending_summary(schedule.latest_summary),
  }
}

///|
fn normalize_civic_pending_summary(summary : String) -> String {
  if summary.has_prefix("Blocked ") &&
    summary.contains("status=RunConfirmed") &&
    summary.contains(" is Pending.") {
    "Running \{summary[8:]}"
  } else {
    summary
  }
}

///|
pub async fn save_civic_salon_schedules(
  path : String,
  schedules : Array[CivicSalonSchedule],
) -> Unit {
  @support.write_text_file(path, schedules.to_json().stringify(indent=2))
}
