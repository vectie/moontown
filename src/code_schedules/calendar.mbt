///|
async fn code_schedule_zone(name : String) -> @time.Zone {
  if name == "UTC" || name == "Etc/UTC" {
    return @time.utc_zone
  }
  if name == "" ||
    name.has_prefix("/") ||
    name.split("/").any(part => part == "..") {
    fail("invalid Code schedule timezone")
  }
  let bytes = @fs.read_file("/usr/share/zoneinfo/" + name).binary()
  @time.Zone::from_tzif2(name, bytes.to_fixedarray())
}

///|
pub async fn CodeSchedule::with_calendar(
  self : CodeSchedule,
  recurrence : String,
  timezone : String,
) -> CodeSchedule {
  if recurrence == "" || recurrence == "interval" {
    return {
      ..self,
      recurrence: None,
      timezone: None,
      calendar_anchor_at: None,
    }
  }
  if !["daily", "weekdays", "weekly"].contains(recurrence) {
    fail("invalid Code schedule recurrence")
  }
  ignore(code_schedule_zone(timezone))
  {
    ..self,
    recurrence: Some(recurrence),
    timezone: Some(timezone),
    calendar_anchor_at: Some(self.next_due_at),
  }
}

///|
fn code_schedule_calendar_next(
  schedule : CodeSchedule,
  now : Int64,
  zone : @time.Zone,
) -> Int64 raise {
  let anchor = @time.unix(
    schedule.calendar_anchor_at.unwrap_or(schedule.next_due_at),
    zone~,
  )
  let current = @time.unix(now, zone~)
  let target_time = anchor.to_plain_time()
  let recurrence = schedule.recurrence.unwrap_or("daily")
  for offset in 0..<8 {
    let date = current.to_plain_date().add_days(offset.to_int64())
    let weekday = date.weekday()
    if recurrence == "weekdays" && (weekday is Saturday || weekday is Sunday) {
      continue
    }
    if recurrence == "weekly" && weekday != anchor.weekday() {
      continue
    }
    let candidate = @time.ZonedDateTime::from_plain_datetime(
      target_time.at_date(date),
      zone~,
    ).to_unix_second()
    if candidate > now {
      return candidate
    }
  }
  fail("invalid Code schedule calendar date")
}

///|
async fn code_schedule_next_after_completion(
  original : CodeSchedule,
  completed : CodeSchedule,
  now : Int64,
) -> CodeSchedule {
  if original.recurrence is None || !completed.enabled {
    return completed
  }
  let zone = code_schedule_zone(original.timezone.unwrap_or("UTC"))
  {
    ..completed,
    next_due_at: code_schedule_calendar_next(original, now, zone),
  }
}
