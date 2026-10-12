///|
pub(all) struct CalendarEvent {
  uid : String
  summary : String
  start : String
  end : String
  date : String
  zone : String
  location : String
  description : String
  url : String
  recurrence : String
} derive(Debug, Eq)

///|
pub fn calendar_file(path : String, mime : String) -> Bool {
  let name = path.split("/").last().unwrap_or("").to_owned().to_lower()
  name.has_suffix(".ics") ||
  (
    !name.contains(".") &&
    mime.split(";").next().unwrap_or("").trim() == "text/calendar"
  )
}

///|
fn calendar_unescape(value : String) -> String {
  let out = StringBuilder()
  let mut escaped = false
  for c in value {
    if escaped {
      if c == 'n' || c == 'N' {
        out.write_char('\n')
      } else {
        out.write_char(c)
      }
      escaped = false
    } else if c == '\\' {
      escaped = true
    } else {
      out.write_char(c)
    }
  }
  if escaped {
    out.write_char('\\')
  }
  out.to_string()
}

///|
fn calendar_time(value : String, params : String) -> (String, String, String)? {
  let parts = value.split("T").map(s => s.to_owned()).collect()
  let day = parts[0]
  if day.length() != 8 || !day.iter().all(c => c >= '0' && c <= '9') {
    return None
  }
  let year = try! day[0:4].to_string()
  let month = try! day[4:6].to_string()
  let date = try! day[6:8].to_string()
  let m = @string.parse_int(month) catch { _ => 0 }
  let d = @string.parse_int(date) catch { _ => 0 }
  let y = @string.parse_int(year) catch { _ => 0 }
  let days = if m == 2 {
    if y % 4 == 0 && (y % 100 != 0 || y % 400 == 0) {
      29
    } else {
      28
    }
  } else if [4, 6, 9, 11].contains(m) {
    30
  } else {
    31
  }
  if m < 1 || m > 12 || d < 1 || d > days {
    return None
  }
  let date = year + "-" + month + "-" + date
  if parts.length() == 1 {
    return Some((date, date, "all day"))
  }
  if parts.length() != 2 {
    return None
  }
  let utc = parts[1].has_suffix("Z")
  let time = parts[1].replace_all(old="Z", new="")
  if time.length() != 6 || !time.iter().all(c => c >= '0' && c <= '9') {
    return None
  }
  let hh = try! time[0:2].to_string()
  let mm = try! time[2:4].to_string()
  let ss = try! time[4:6].to_string()
  if hh > "23" || mm > "59" || ss > "60" {
    return None
  }
  let mut zone = if utc { "UTC" } else { "floating (unconverted)" }
  if !utc {
    for param in params.split(";") {
      if param.has_prefix("TZID=") {
        zone = param.replace_all(old="TZID=", new="").to_string() +
          " (unconverted)"
      }
    }
  }
  Some((date + " " + hh + ":" + mm + ":" + ss, date, zone))
}

///|
/// An agenda of source VEVENTs, never an expanded recurrence calendar.
pub fn parse_calendar(text : String) -> Result[Array[CalendarEvent], String] {
  if @utf8.encode(text).length() > 1024 * 1024 {
    return Err("Calendar exceeds the 1 MiB agenda limit")
  }
  let lines : Array[String] = []
  for
    raw in text
    .replace_all(old="\r\n", new="\n")
    .replace_all(old="\r", new="\n")
    .split("\n") {
    if raw.has_prefix(" ") || raw.has_prefix("\t") {
      if lines.is_empty() {
        return Err("Folded line without a preceding property")
      }
      lines[lines.length() - 1] += (try! raw.to_owned()[1:]).to_string()
    } else {
      lines.push(raw.to_owned())
    }
  }
  let events : Array[CalendarEvent] = []
  let mut active = false
  let mut nested = 0
  let mut calendar = false
  let mut closed = false
  let props : Map[String, String] = {}
  let params : Map[String, String] = {}
  for line in lines {
    if line == "BEGIN:VCALENDAR" {
      calendar = true
      continue
    }
    if line == "END:VCALENDAR" {
      closed = true
      continue
    }
    if line == "BEGIN:VEVENT" {
      if active {
        return Err("Nested VEVENT is unsupported")
      }
      active = true
      nested = 0
      props.clear()
      params.clear()
      continue
    }
    if line == "END:VEVENT" {
      if !active {
        return Err("VEVENT end without start")
      }
      guard calendar_time(
          props.get("DTSTART").unwrap_or(""),
          params.get("DTSTART").unwrap_or(""),
        )
        is Some((start, date, zone)) else {
        return Err("Event has a missing or unsupported DTSTART")
      }
      let end = if props.get("DTEND") is Some(value) {
        guard calendar_time(value, params.get("DTEND").unwrap_or(""))
          is Some((end, _, end_zone)) else {
          return Err("Event has an unsupported DTEND")
        }
        end + " · " + end_zone
      } else {
        "Not specified"
      }
      events.push({
        uid: props.get("UID").unwrap_or(""),
        summary: props.get("SUMMARY").unwrap_or("Untitled event"),
        start,
        end,
        date,
        zone,
        location: props.get("LOCATION").unwrap_or(""),
        description: props.get("DESCRIPTION").unwrap_or(""),
        url: props.get("URL").unwrap_or(""),
        recurrence: ["RRULE", "RDATE", "EXDATE", "RECURRENCE-ID"]
        .filter_map(k => props.get(k).map(v => k + "=" + v))
        .join("; "),
      })
      if events.length() > 2000 {
        return Err("Calendar exceeds 2,000 source events")
      }
      active = false
      continue
    }
    if !active {
      continue
    }
    if line.has_prefix("BEGIN:") {
      nested += 1
      continue
    }
    if line.has_prefix("END:") {
      nested -= 1
      continue
    }
    if nested > 0 {
      continue
    }
    let segments = line.split(":").map(s => s.to_owned()).collect()
    if segments.length() < 2 {
      continue
    }
    let key = segments[0].split(";").next().unwrap_or("").to_owned().to_upper()
    props[key] = calendar_unescape(segments[1:].join(":"))
    params[key] = segments[0]
  }
  if !calendar || !closed || active {
    return Err("Incomplete VCALENDAR or VEVENT")
  }
  events.sort_by((a, b) => {
    if a.date == b.date {
      a.start.compare(b.start)
    } else {
      a.date.compare(b.date)
    }
  })
  Ok(events)
}

///|
pub fn calendar_matches(
  events : Array[CalendarEvent],
  query : String,
  from : String,
  until : String,
  location : String,
) -> Array[Int] {
  let found : Array[Int] = []
  for i, event in events {
    if (from.is_empty() || event.date >= from) &&
      (until.is_empty() || event.date <= until) &&
      event.location.to_lower().contains(location.to_lower()) &&
      [event.summary, event.description, event.location, event.uid]
      .join(" ")
      .to_lower()
      .contains(query.to_lower()) {
      found.push(i)
    }
  }
  found
}

///|
fn calendar_markdown_text(value : String) -> String {
  value
  .replace_all(old="&", new="&amp;")
  .replace_all(old="<", new="&lt;")
  .replace_all(old=">", new="&gt;")
  .replace_all(old="\\", new="\\\\")
  .replace_all(old="[", new="\\[")
  .replace_all(old="]", new="\\]")
  .replace_all(old="*", new="\\*")
  .replace_all(old="_", new="\\_")
  .replace_all(old="`", new="\\`")
  .replace_all(old="#", new="\\#")
  .replace_all(old="\n", new="\n    ")
}

///|
pub fn calendar_itinerary(
  events : Array[CalendarEvent],
  indices : Array[Int],
) -> String {
  calendar_itinerary_text(
    events, indices, "Source events only. Recurrences are not expanded. Local/TZID times are unconverted. All-day end dates are exclusive.",
    "Recurrence not expanded",
  )
}

///|
fn calendar_itinerary_text(
  events : Array[CalendarEvent],
  indices : Array[Int],
  notice : String,
  provenance : String,
) -> String {
  let out = StringBuilder()
  out.write_string("# Selected calendar itinerary\n\n" + notice + "\n")
  let mut day = ""
  for i in indices {
    guard events.get(i) is Some(e) else { continue }
    if e.date != day {
      day = e.date
      out.write_string("\n## " + day + "\n")
    }
    out.write_string(
      "\n- " +
      calendar_markdown_text(e.summary) +
      "\n  - Start: " +
      e.start +
      " · " +
      calendar_markdown_text(e.zone) +
      "\n  - End: " +
      calendar_markdown_text(e.end) +
      "\n  - Location: " +
      calendar_markdown_text(e.location) +
      "\n  - Notes: " +
      calendar_markdown_text(e.description) +
      "\n  - UID: " +
      calendar_markdown_text(e.uid) +
      "\n  - URL (source text): " +
      calendar_markdown_text(e.url) +
      "\n",
    )
    if !e.recurrence.is_empty() {
      out.write_string(
        "  - " + provenance + ": " + calendar_markdown_text(e.recurrence) + "\n",
      )
    }
  }
  out.to_string()
}

///|
pub fn calendar_csv(
  events : Array[CalendarEvent],
  indices : Array[Int],
) -> String {
  calendar_csv_text(events, indices, "Recurrence (not expanded)")
}

///|
fn calendar_csv_text(
  events : Array[CalendarEvent],
  indices : Array[Int],
  provenance : String,
) -> String {
  let rows = [
    [
      "Summary", "Start", "Time zone", "End", "Location", "Description", "UID", "URL",
      provenance,
    ]
    .map(csv_cell)
    .join(","),
  ]
  for i in indices {
    if events.get(i) is Some(e) {
      rows.push(
        [
          e.summary,
          e.start,
          e.zone,
          e.end,
          e.location,
          e.description,
          e.uid,
          e.url,
          e.recurrence,
        ]
        .map(csv_cell)
        .join(","),
      )
    }
  }
  rows.join("\r\n") + "\r\n"
}

///|
/// A selected subset of a bounded expansion, never a whole-calendar claim.
pub fn calendar_occurrence_itinerary(
  events : Array[CalendarEvent],
  indices : Array[Int],
  from : String,
  until : String,
) -> String {
  calendar_itinerary_text(
    events,
    indices,
    "Dated occurrences from explicitly selected source entries only. Inclusive start-date window: " +
    calendar_markdown_text(from) +
    " through " +
    calendar_markdown_text(until) +
    ". UTC/all-day only; all-day end dates are exclusive. Unselected sources and unselected occurrences are not included. No scheduling actions.",
    "Occurrence provenance",
  )
}

///|
pub fn calendar_occurrence_csv(
  events : Array[CalendarEvent],
  indices : Array[Int],
  from : String,
  until : String,
) -> String {
  calendar_csv_text(
    events,
    indices,
    "Occurrence provenance; selected-source subset; start-date window " +
    from +
    " through " +
    until,
  )
}
