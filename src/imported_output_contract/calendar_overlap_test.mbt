///|
fn overlap_fixture() -> Array[@imported_output_contract.CalendarEvent] raise {
  let text =
    #|BEGIN:VCALENDAR
    #|BEGIN:VEVENT
    #|UID:night
    #|DTSTART:20261009T233000Z
    #|DTEND:20261010T010000Z
    #|SUMMARY:Night review
    #|RRULE:FREQ=DAILY;COUNT=2
    #|END:VEVENT
    #|BEGIN:VEVENT
    #|UID:workshop
    #|DTSTART:20261010T003000Z
    #|DTEND:20261010T020000Z
    #|SUMMARY:Workshop
    #|END:VEVENT
    #|BEGIN:VEVENT
    #|UID:touch
    #|DTSTART:20261010T020000Z
    #|DTEND:20261010T030000Z
    #|SUMMARY:Adjacent
    #|END:VEVENT
    #|BEGIN:VEVENT
    #|UID:holiday
    #|DTSTART;VALUE=DATE:20261010
    #|SUMMARY:All day
    #|END:VEVENT
    #|BEGIN:VEVENT
    #|UID:unknown
    #|DTSTART:20261010T004500Z
    #|SUMMARY:No duration
    #|END:VEVENT
    #|END:VCALENDAR
  guard @imported_output_contract.calendar_occurrences(
      text,
      "2026-10-09",
      "2026-10-10",
      [0, 1, 2, 3, 4],
    )
    is Ok(events) else {
    fail("expand")
  }
  events
}

///|
test "overlap review crosses midnight respects end exclusivity and retains unknowns" {
  let events = overlap_fixture()
  let all = events.mapi((i, _) => i)
  guard @imported_output_contract.calendar_overlap_review(events, all)
    is Ok(review) else {
    fail("review")
  }
  assert_eq(review.assessed, 4)
  assert_eq(review.unassessed.map(i => events[i].uid), ["holiday", "unknown"])
  assert_eq(review.pairs.length(), 1)
  assert_eq(events[review.pairs[0].first].uid, "night")
  assert_eq(events[review.pairs[0].second].uid, "workshop")
  assert_eq(review.pairs[0].start, "2026-10-10 00:30:00")
  assert_eq(review.pairs[0].end, "2026-10-10 01:00:00")
  guard @imported_output_contract.calendar_overlap_report(
      events, all, "2026-10-09", "2026-10-10",
    )
    is Ok(report) else {
    fail("report")
  }
  assert_true(report.contains("unassessed: 2; overlap pairs: 1"))
  assert_true(report.contains("UID: workshop"))
  assert_true(report.contains("Source VEVENT 1"))
  assert_true(report.contains("all-day marker, not a timed commitment"))
  assert_true(report.contains("missing or invalid UTC duration"))
}

///|
test "overlap review selected subset is deterministic rejects duplicate and source indices" {
  let events = overlap_fixture()
  assert_true(
    @imported_output_contract.calendar_overlap_review(events, [0, 0]) is Err(_),
  )
  assert_true(
    @imported_output_contract.calendar_overlap_review(events, [-1]) is Err(_),
  )
  assert_true(
    @imported_output_contract.calendar_overlap_review(events, [6]) is Err(_),
  )
  assert_eq(
    @imported_output_contract.calendar_overlap_review(events, [2, 0]),
    @imported_output_contract.calendar_overlap_review(events, [0, 2]),
  )
  guard @imported_output_contract.calendar_overlap_review(events, [0])
    is Ok(single) else {
    fail("single")
  }
  assert_eq(single.pairs, [])
  let raw = [{ ..events[0], recurrence: "", }]
  assert_true(
    @imported_output_contract.calendar_overlap_review(raw, [0]) is Err(_),
  )
  guard @imported_output_contract.calendar_overlap_report(
      events,
      [],
      "2026-10-09",
      "2026-10-10",
    )
    is Ok(empty) else {
    fail("empty")
  }
  assert_true(empty.contains("Selected: 0"))
  assert_true(empty.contains("does not establish availability"))
}

///|
test "overlap review nested intervals and pair cap are atomic" {
  let original = overlap_fixture()[0]
  let events = [
    original,
    {
      ..original,
      start: "2026-10-10 00:00:00",
      end: "2026-10-10 00:30:00 · UTC",
    },
    {
      ..original,
      start: "2026-10-10 00:15:00",
      end: "2026-10-10 00:45:00 · UTC",
    },
  ]
  guard @imported_output_contract.calendar_overlap_review(events, [0, 1, 2])
    is Ok(review) else {
    fail("nested")
  }
  assert_eq(review.pairs.length(), 3)
  let dense = Array::make(64, original)
  assert_true(
    @imported_output_contract.calendar_overlap_review(
      dense,
      dense.mapi((i, _) => i),
    )
    is Err(_),
  )
}

///|
test "overlap report escapes source text and never treats invalid timestamps as assessed" {
  let original = overlap_fixture()[0]
  let events = [
    {
      ..original,
      summary: "<script>*x*",
      uid: "[evil](link)",
      start: "2026-02-30 00:00:00",
    },
  ]
  guard @imported_output_contract.calendar_overlap_report(
      events,
      [0],
      "from",
      "until",
    )
    is Ok(report) else {
    fail("report")
  }
  assert_true(report.contains("assessed UTC intervals: 0; unassessed: 1"))
  assert_false(report.contains("<script>"))
  assert_true(report.contains("&lt;script&gt;"))
}

///|
test "overlap report rejects oversized duplicated source content without partial output" {
  let original = overlap_fixture()[0]
  let large = Array::make(400000, "x").join("")
  let events = [{ ..original, description: large, }]
  assert_true(
    @imported_output_contract.calendar_overlap_report(
      events,
      [0],
      "2026-10-09",
      "2026-10-10",
    )
    is Err(_),
  )
}
