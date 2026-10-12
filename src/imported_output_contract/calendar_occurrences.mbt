///|
// This is deliberately a bounded subset of RFC 5545, not an ICS scheduler.
fn expand_occurrence_source(
  source : OccurrenceSource,
  from : Int,
  until : Int,
) -> Result[Array[CalendarEvent], String] {
  let props = source.properties
  for key in ["RDATE", "EXRULE", "RECURRENCE-ID", "DURATION"] {
    if props.any(p => p.key == key) {
      return Err(key + " is unsupported; exclude this source entry")
    }
  }
  for p in props {
    if p.key == "STATUS" && p.value != "CONFIRMED" && p.value != "TENTATIVE" {
      return Err(
        "Cancellation/unknown STATUS is unsupported; exclude this source entry",
      )
    }
  }
  let status = match occurrence_single(props, "STATUS") {
    Err(e) => return Err(e)
    Ok(Some(p)) => "; STATUS=" + p.value
    Ok(None) => ""
  }
  let start = match occurrence_single(props, "DTSTART") {
    Err(e) => return Err(e)
    Ok(None) => return Err("DTSTART is required")
    Ok(Some(p)) =>
      match occurrence_time(p.value, p.params) {
        Ok(t) => t
        Err(e) => return Err(e)
      }
  }
  let end = match occurrence_single(props, "DTEND") {
    Err(e) => return Err(e)
    Ok(None) =>
      if start.all_day {
        Some({ ..start, day: start.day + 1, })
      } else {
        None
      }
    Ok(Some(p)) =>
      match occurrence_time(p.value, p.params) {
        Ok(t) => Some(t)
        Err(e) => return Err(e)
      }
  }
  if end is Some(end) {
    if end.all_day != start.all_day ||
      end.day < start.day ||
      (end.day == start.day && end.seconds <= start.seconds) {
      return Err("DTEND must have the same type and be after DTSTART")
    }
  }
  let rule = match occurrence_single(props, "RRULE") {
    Err(e) => return Err(e)
    Ok(p) => p
  }
  let mut step = 0
  let mut count = 1
  let mut bound : OccurrenceTime? = None
  if rule is Some(rule) {
    if rule.params != "RRULE" {
      return Err("RRULE parameters are unsupported")
    }
    let fields : Map[String, String] = {}
    for part in rule.value.to_upper().split(";") {
      let pair = part.split("=").map(s => s.to_owned()).collect()
      if pair.length() != 2 ||
        !["FREQ", "INTERVAL", "COUNT", "UNTIL"].contains(pair[0]) {
        return Err(
          "Only DAILY/WEEKLY FREQ with INTERVAL, COUNT or UNTIL is supported; BYDAY and other rule parts are unsupported",
        )
      }
      if fields.contains(pair[0]) {
        return Err("Duplicate RRULE part")
      }
      fields[pair[0]] = pair[1]
    }
    let frequency = fields.get("FREQ").unwrap_or("")
    if frequency != "DAILY" && frequency != "WEEKLY" {
      return Err("Only DAILY and WEEKLY recurrence is supported")
    }
    let interval = @string.parse_int(fields.get("INTERVAL").unwrap_or("1")) catch {
      _ => 0
    }
    if interval < 1 || interval > 3660 {
      return Err("INTERVAL must be 1–3660")
    }
    step = interval * (if frequency == "DAILY" { 1 } else { 7 })
    count = 10000000
    if fields.get("COUNT") is Some(value) {
      count = @string.parse_int(value) catch { _ => 0 }
      if count < 1 || count > 10000000 {
        return Err("COUNT must be 1–10,000,000")
      }
    }
    if fields.get("UNTIL") is Some(value) {
      if fields.contains("COUNT") {
        return Err("COUNT and UNTIL cannot be combined")
      }
      match occurrence_time(value, "UNTIL") {
        Err(e) => return Err(e)
        Ok(t) => bound = Some(t)
      }
      if bound is Some(t) && t.all_day != start.all_day {
        return Err("UNTIL must have the same date/UTC type as DTSTART")
      }
    }
  }
  let exclusions : Array[OccurrenceTime] = []
  for prop in props {
    if prop.key == "EXDATE" {
      for value in prop.value.split(",") {
        match occurrence_time(value.to_owned(), prop.params) {
          Err(e) => return Err("EXDATE: " + e)
          Ok(t) => {
            if t.all_day != start.all_day {
              return Err("EXDATE must have the same date/UTC type as DTSTART")
            }
            exclusions.push(t)
          }
        }
      }
    }
  }
  let result : Array[CalendarEvent] = []
  let mut field_bytes = 0
  let first = if step == 0 || start.day >= from {
    0
  } else {
    (from - start.day + step - 1) / step
  }
  for n = first; n < count; n = n + 1 {
    // n is derived from a <=9999 date window, so multiplication remains bounded.
    let day = start.day + n * step
    if day > until {
      break
    }
    let time = { ..start, day, }
    if bound is Some(b) &&
      (day > b.day || (day == b.day && start.seconds > b.seconds)) {
      break
    }
    if day >= from && !exclusions.contains(time) {
      let ending = match end {
        None => "Not specified"
        Some(e) => {
          let shifted = { ..e, day: day + e.day - start.day, }
          if shifted.day >= occurrence_year_days(10000) {
            return Err("An occurrence end exceeds year 9999")
          }
          occurrence_stamp(shifted) + " · " + source.event.zone
        }
      }
      result.push({
        ..source.event,
        start: occurrence_stamp(time),
        date: occurrence_date(day),
        end: ending,
        recurrence: "Source VEVENT " +
        source.ordinal.to_string() +
        "; occurrence " +
        occurrence_stamp(time) +
        "; " +
        (if rule is Some(r) { "RRULE=" + r.value } else { "one-off" }) +
        status,
      })
      field_bytes += occurrence_field_bytes(result[result.length() - 1])
      if field_bytes > 4 * 1024 * 1024 {
        return Err(
          "Expanded fields exceed 4 MiB; choose fewer sources or a shorter window",
        )
      }
      if result.length() > 2000 {
        return Err(
          "Window exceeds 2,000 occurrences; choose fewer sources or a shorter window",
        )
      }
    }
    if step == 0 {
      break
    }
  }
  Ok(result)
}

///|
/// Expand explicitly selected source-view indices, atomically. Window endpoints
/// are inclusive occurrence-start dates, at most 366 dates. Unsupported selected
/// sources fail the entire result; unselected sources are never implied included.
pub fn calendar_occurrences(
  text : String,
  from : String,
  until : String,
  source_indices : Array[Int],
) -> Result[Array[CalendarEvent], String] {
  guard occurrence_window_day(from) is Some(first) &&
    occurrence_window_day(until) is Some(last) else {
    return Err(
      "Choose valid From and Through dates in YYYY-MM-DD (years 0001–9999)",
    )
  }
  if last < first || last - first >= 366 {
    return Err("Choose an ordered window of at most 366 inclusive dates")
  }
  if source_indices.is_empty() {
    return Err("Select at least one source event before expanding")
  }
  let sources = match occurrence_sources(text) {
    Ok(s) => s
    Err(e) => return Err(e)
  }
  let selected : Array[Int] = []
  for i in source_indices {
    if i < 0 || i >= sources.length() {
      return Err("Selected source index is invalid")
    }
    if selected.contains(i) {
      return Err("Selected source indices must be unique")
    }
    selected.push(i)
  }
  selected.sort()
  let result : Array[CalendarEvent] = []
  let mut field_bytes = 0
  for i in selected {
    let uid = sources[i].event.uid
    if !uid.is_empty() &&
      sources.any(s => {
        s.event.uid == uid &&
        s.properties.any(p => {
          p.key == "RECURRENCE-ID" ||
          (p.key == "STATUS" && p.value == "CANCELLED")
        })
      }) {
      return Err(
        "Selected UID " +
        uid +
        " has an override/cancellation sibling; this series is unsupported even if that sibling is unselected",
      )
    }
    if !uid.is_empty() && sources.filter(s => s.event.uid == uid).length() > 1 {
      return Err(
        "Selected UID " +
        uid +
        " occurs in multiple source entries; revision/duplicate merging is unsupported",
      )
    }
    match expand_occurrence_source(sources[i], first, last) {
      Err(e) =>
        return Err(
          "Source VEVENT " +
          sources[i].ordinal.to_string() +
          " (" +
          sources[i].event.summary +
          "): " +
          e,
        )
      Ok(events) => {
        for event in events {
          field_bytes += occurrence_field_bytes(event)
          if field_bytes > 4 * 1024 * 1024 {
            return Err(
              "Expanded fields exceed 4 MiB; choose fewer sources or a shorter window",
            )
          }
          result.push(event)
        }
        if result.length() > 2000 {
          return Err(
            "Window exceeds 2,000 occurrences; choose fewer sources or a shorter window",
          )
        }
      }
    }
  }
  result.sort_by((a, b) => {
    if a.date == b.date {
      a.start.compare(b.start)
    } else {
      a.date.compare(b.date)
    }
  })
  Ok(result)
}

///|
fn occurrence_field_bytes(event : CalendarEvent) -> Int {
  let mut size = 0
  for
    field in [
      event.uid,
      event.summary,
      event.start,
      event.end,
      event.date,
      event.zone,
      event.location,
      event.description,
      event.url,
      event.recurrence,
    ] {
    size += @utf8.encode(field).length()
  }
  size
}
