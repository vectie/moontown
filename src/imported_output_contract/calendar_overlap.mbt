///|
pub(all) struct CalendarOverlap {
  first : Int
  second : Int
  start : String
  end : String
} derive(Debug, Eq)

///|
pub(all) struct CalendarOverlapReview {
  pairs : Array[CalendarOverlap]
  unassessed : Array[Int]
  assessed : Int
} derive(Debug, Eq)

///|
fn overlap_utc_stamp(value : String) -> Bool {
  if value.length() != 19 {
    return false
  }
  let raw = value
    .replace_all(old="-", new="")
    .replace_all(old=":", new="")
    .replace_all(old=" ", new="T") +
    "Z"
  match occurrence_time(raw, "DTSTART") {
    Ok(t) => occurrence_stamp(t) == value
    Err(_) => false
  }
}

///|
/// Review selected dated occurrences only. Intervals are half-open UTC ranges;
/// all-day markers and missing durations are explicitly unassessed.
pub fn calendar_overlap_review(
  events : Array[CalendarEvent],
  indices : Array[Int],
) -> Result[CalendarOverlapReview, String] {
  if events.length() > 2000 {
    return Err("Overlap review supports at most 2,000 occurrences")
  }
  let selected : Array[Int] = []
  for i in indices {
    if i < 0 || i >= events.length() || selected.contains(i) {
      return Err("Select unique valid occurrence indices")
    }
    if !events[i].recurrence.has_prefix("Source VEVENT ") {
      return Err("Expand selected source entries before reviewing overlaps")
    }
    selected.push(i)
  }
  selected.sort()
  let known : Array[(Int, String)] = []
  let unassessed : Array[Int] = []
  for i in selected {
    let e = events[i]
    let parts = e.end.split(" · ").map(s => s.to_owned()).collect()
    if e.zone != "UTC" ||
      parts.length() != 2 ||
      parts[1] != "UTC" ||
      !overlap_utc_stamp(e.start) ||
      !overlap_utc_stamp(parts[0]) ||
      parts[0] <= e.start {
      unassessed.push(i)
    } else {
      known.push((i, parts[0]))
    }
  }
  let pairs : Array[CalendarOverlap] = []
  for p = 0; p < known.length(); p = p + 1 {
    let (i, ending) = known[p]
    for q = p + 1; q < known.length(); q = q + 1 {
      let (j, other_end) = known[q]
      let start = if events[i].start > events[j].start {
        events[i].start
      } else {
        events[j].start
      }
      let end = if ending < other_end { ending } else { other_end }
      if start < end {
        if pairs.length() >= 2000 {
          return Err(
            "More than 2,000 overlap pairs; narrow the occurrence selection",
          )
        }
        pairs.push({ first: i, second: j, start, end, })
      }
    }
  }
  Ok({ pairs, unassessed, assessed: known.length(), })
}

///|
/// Produce a portable review with source identities and explicit coverage gaps.
pub fn calendar_overlap_report(
  events : Array[CalendarEvent],
  indices : Array[Int],
  from : String,
  until : String,
) -> Result[String, String] {
  let review = match calendar_overlap_review(events, indices) {
    Ok(r) => r
    Err(e) => return Err(e)
  }
  // Conservative bound includes worst-case Markdown escaping and duplicated
  // pair labels, before allocating the report. No partial report is returned.
  let mut budget = 4096 +
    6 * (@utf8.encode(from).length() + @utf8.encode(until).length())
  for i in indices {
    budget += 512 + 12 * occurrence_field_bytes(events[i])
    if budget > 4 * 1024 * 1024 {
      return Err(
        "Overlap report exceeds 4 MiB conservative budget; narrow selection",
      )
    }
  }
  for pair in review.pairs {
    budget += 256
    for i in [pair.first, pair.second] {
      let e = events[i]
      budget += 128 +
        6 * @utf8.encode(e.summary + e.uid + e.recurrence).length()
      if budget > 4 * 1024 * 1024 {
        return Err(
          "Overlap report exceeds 4 MiB conservative budget; narrow selection",
        )
      }
    }
  }
  let out = StringBuilder()
  out.write_string(
    "# Selected occurrence overlap review\n\nWindow (occurrence start dates): " +
    calendar_markdown_text(from) +
    " through " +
    calendar_markdown_text(until) +
    ".\nSelected occurrences only. Unselected sources/occurrences and starts outside the window are not assessed. This is a time-overlap review, not personal availability or a scheduling decision. All-day markers and missing/invalid UTC durations are unassessed. Touching endpoints do not overlap.\n\n",
  )
  out.write_string(
    "Selected: " +
    indices.length().to_string() +
    "; assessed UTC intervals: " +
    review.assessed.to_string() +
    "; unassessed: " +
    review.unassessed.length().to_string() +
    "; overlap pairs: " +
    review.pairs.length().to_string() +
    ".\n",
  )
  out.write_string("\n## Overlap pairs\n")
  if review.pairs.is_empty() {
    out.write_string(
      "\nNo overlaps among assessed selected UTC intervals. This does not establish availability.\n",
    )
  }
  for pair in review.pairs {
    out.write_string(
      "\n- Occurrences " +
      (pair.first + 1).to_string() +
      " and " +
      (pair.second + 1).to_string() +
      ": " +
      pair.start +
      " → " +
      pair.end +
      " UTC\n",
    )
    for i in [pair.first, pair.second] {
      let e = events[i]
      out.write_string(
        "  - " +
        calendar_markdown_text(e.summary) +
        "; UID: " +
        calendar_markdown_text(e.uid) +
        "; " +
        calendar_markdown_text(e.recurrence) +
        "\n",
      )
    }
  }
  out.write_string("\n## Unassessed occurrences\n")
  if review.unassessed.is_empty() {
    out.write_string("\nNone in this selection.\n")
  }
  for i in review.unassessed {
    let e = events[i]
    out.write_string(
      "\n- Occurrence " +
      (i + 1).to_string() +
      ": " +
      calendar_markdown_text(e.summary) +
      "; UID: " +
      calendar_markdown_text(e.uid) +
      "; " +
      calendar_markdown_text(e.recurrence) +
      "; " +
      (if e.zone == "all day" {
        "all-day marker, not a timed commitment"
      } else {
        "missing or invalid UTC duration"
      }) +
      "\n",
    )
  }
  out.write_string(
    "\n## Selected source details\n\n" +
    calendar_occurrence_itinerary(events, indices, from, until),
  )
  Ok(out.to_string())
}
