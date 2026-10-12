///|
priv struct OccurrenceProperty {
  key : String
  params : String
  value : String
}

///|
priv struct OccurrenceSource {
  event : CalendarEvent
  properties : Array[OccurrenceProperty]
  ordinal : Int
}

///|
// Retain every EXDATE and validate structure before matching source-view indices.
fn occurrence_sources(text : String) -> Result[Array[OccurrenceSource], String] {
  if @utf8.encode(text).length() > 1024 * 1024 {
    return Err("Calendar exceeds the 1 MiB limit")
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
  let sources : Array[OccurrenceSource] = []
  let stack : Array[String] = []
  let mut calendar_count = 0
  let mut properties : Array[OccurrenceProperty] = []
  let mut event_lines : Array[String] = []
  for line in lines {
    if line.is_empty() {
      continue
    }
    let segments = line.split(":").map(s => s.to_owned()).collect()
    if segments.length() < 2 {
      return Err("Malformed calendar property")
    }
    let header = segments[0].to_upper()
    let key = header.split(";").next().unwrap_or("").to_owned()
    let value = segments[1:].join(":")
    if key == "BEGIN" {
      if value == "VCALENDAR" {
        if !stack.is_empty() || calendar_count != 0 {
          return Err("Expected one VCALENDAR")
        }
        calendar_count += 1
      } else if value == "VEVENT" {
        if stack != ["VCALENDAR"] {
          return Err("VEVENT must be directly inside VCALENDAR")
        }
        properties = []
        event_lines = [line]
      } else if stack.is_empty() {
        return Err("Component outside VCALENDAR")
      }
      stack.push(value)
      continue
    }
    if key == "END" {
      if stack.last() != Some(value) {
        return Err("Unbalanced calendar components")
      }
      if value == "VEVENT" {
        event_lines.push(line)
        guard parse_calendar(
            "BEGIN:VCALENDAR\n" + event_lines.join("\n") + "\nEND:VCALENDAR",
          )
          is Ok([event]) else {
          return Err("Source event cannot be read by the agenda")
        }
        sources.push({ event, properties, ordinal: sources.length() + 1, })
        if sources.length() > 2000 {
          return Err("Calendar exceeds 2,000 source events")
        }
      }
      ignore(stack.pop())
      continue
    }
    if stack.is_empty() {
      return Err("Property outside VCALENDAR")
    }
    if stack == ["VCALENDAR"] && key == "METHOD" && value != "PUBLISH" {
      return Err(
        "Calendar METHOD is unsupported for occurrence expansion (including cancellation or scheduling messages)",
      )
    }
    if stack == ["VCALENDAR", "VEVENT"] {
      properties.push({ key, params: header, value, })
      event_lines.push(line)
    }
  }
  if calendar_count != 1 || !stack.is_empty() {
    return Err("Incomplete VCALENDAR or VEVENT")
  }
  sources.sort_by((a, b) => {
    if a.event.date == b.event.date {
      a.event.start.compare(b.event.start)
    } else {
      a.event.date.compare(b.event.date)
    }
  })
  Ok(sources)
}

///|
fn occurrence_single(
  properties : Array[OccurrenceProperty],
  key : String,
) -> Result[OccurrenceProperty?, String] {
  let matches = properties.filter(p => p.key == key)
  if matches.length() > 1 {
    Err("Duplicate " + key + " is unsupported")
  } else {
    Ok(matches.get(0))
  }
}
