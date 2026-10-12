///|
fn occurrence_fixture(body : String) -> String {
  "BEGIN:VCALENDAR\nBEGIN:VEVENT\nUID:series\nSUMMARY:Review\n" +
  body +
  "\nEND:VEVENT\nEND:VCALENDAR"
}

///|
test "daily COUNT includes original starts before window and exclusions are not replenished" {
  let source = occurrence_fixture(
    "DTSTART:20261001T230000Z\nDTEND:20261002T003000Z\nRRULE:FREQ=DAILY;COUNT=8\nEXDATE:20261003T230000Z\nEXDATE:20261005T230000Z,20261006T230000Z",
  )
  guard @imported_output_contract.calendar_occurrences(
      source,
      "2026-10-03",
      "2026-10-10",
      [0],
    )
    is Ok(events) else {
    fail("expand")
  }
  assert_eq(events.map(e => e.date), ["2026-10-04", "2026-10-07", "2026-10-08"])
  assert_eq(events[0].end, "2026-10-05 00:30:00 · UTC")
  assert_true(
    events[0].recurrence.contains("Source VEVENT 1; occurrence 2026-10-04"),
  )
}

///|
test "weekly INTERVAL UNTIL is inclusive and preserves exclusive all-day duration through leap year" {
  let source = occurrence_fixture(
    "DTSTART;VALUE=DATE:20240215\nDTEND;VALUE=DATE:20240217\nRRULE:FREQ=WEEKLY;INTERVAL=2;UNTIL=20240314\nEXDATE;VALUE=DATE:20240215",
  )
  guard @imported_output_contract.calendar_occurrences(
      source,
      "2024-02-01",
      "2024-04-01",
      [0],
    )
    is Ok(events) else {
    fail("expand")
  }
  assert_eq(events.map(e => e.date), ["2024-02-29", "2024-03-14"])
  assert_eq(events[0].end, "2024-03-02 · all day")
  assert_eq(events[1].end, "2024-03-16 · all day")
  let utc = occurrence_fixture(
    "DTSTART:20261231T230000Z\nDTEND:20270101T010000Z\nRRULE:FREQ=DAILY;UNTIL=20270102T225959Z",
  )
  guard @imported_output_contract.calendar_occurrences(
      utc,
      "2026-12-31",
      "2027-01-03",
      [0],
    )
    is Ok(timed) else {
    fail("UTC until")
  }
  assert_eq(timed.map(e => e.date), ["2026-12-31", "2027-01-01"])
  assert_eq(timed[1].end, "2027-01-02 01:00:00 · UTC")
}

///|
test "explicit mixed selection ignores unrelated unsupported sources but never a related override" {
  let source = "BEGIN:VCALENDAR\nBEGIN:VEVENT\nUID:floating\nDTSTART:20261002T100000\nSUMMARY:Floating\nEND:VEVENT\nBEGIN:VEVENT\nUID:daily\nDTSTART:20261001T090000Z\nSUMMARY:Supported\nRRULE:FREQ=DAILY;COUNT=3\nEND:VEVENT\nEND:VCALENDAR"
  guard @imported_output_contract.calendar_occurrences(
      source,
      "2026-10-01",
      "2026-10-03",
      [0],
    )
    is Ok(events) else {
    fail("selected supported")
  }
  assert_eq(events.length(), 3)
  assert_true(events[0].recurrence.contains("Source VEVENT 2"))
  assert_true(
    @imported_output_contract.calendar_occurrences(
      source,
      "2026-10-01",
      "2026-10-03",
      [0, 1],
    )
    is Err(_),
  )
  let override = source.replace_all(
    old="UID:floating",
    new="UID:daily\nRECURRENCE-ID:20261002T090000Z",
  )
  assert_true(
    @imported_output_contract.calendar_occurrences(
      override,
      "2026-10-01",
      "2026-10-03",
      [0],
    )
    is Err(_),
  )
  let cancelled = source.replace_all(
    old="UID:floating",
    new="UID:daily\nSTATUS:CANCELLED",
  )
  assert_true(
    @imported_output_contract.calendar_occurrences(
      cancelled,
      "2026-10-01",
      "2026-10-03",
      [0],
    )
    is Err(_),
  )
}

///|
test "unsupported rules dates and ambiguous series fail atomically" {
  for
    body in [
      "DTSTART:20261001T090000Z\nRRULE:FREQ=MONTHLY", "DTSTART:20261001T090000Z\nRRULE:FREQ=WEEKLY;BYDAY=MO,FR",
      "DTSTART:20261001T090000Z\nRRULE:FREQ=DAILY;COUNT=2;UNTIL=20261003T090000Z",
      "DTSTART:20261001T090000Z\nRRULE:FREQ=DAILY;COUNT=0", "DTSTART:20261001T090000Z\nRRULE:FREQ=DAILY;INTERVAL=0",
      "DTSTART:20261001T090000Z\nRRULE:FREQ=DAILY;FREQ=WEEKLY", "DTSTART:20261001T090000Z\nRRULE:FREQ=DAILY\nRRULE:FREQ=WEEKLY",
      "DTSTART;TZID=Europe/London:20261001T090000", "DTSTART:20261001T090000Z\nEXDATE;VALUE=DATE:20261002",
      "DTSTART:20261001T090000Z\nRRULE:FREQ=DAILY;UNTIL=20261003", "DTSTART:20261001T090000Z\nRDATE:20261002T090000Z",
      "DTSTART:20261001T090000Z\nRECURRENCE-ID:20261001T090000Z", "DTSTART:20261001T090000Z\nDURATION:PT1H",
      "DTSTART:20261001T090000Z\nSTATUS:CANCELLED", "DTSTART:20261001T090000Z\nDTEND:20261001T080000Z",
      "DTSTART:20261001T090000Z\nDTEND;VALUE=DATE:20261002", "DTSTART:20261001T090060Z",
    ] {
    assert_true(
      @imported_output_contract.calendar_occurrences(
        occurrence_fixture(body),
        "2026-10-01",
        "2026-10-10",
        [0],
      )
      is Err(_),
      msg=body,
    )
  }
  let source = occurrence_fixture(
    "DTSTART:20261001T090000Z\nrrule:FREQ=MONTHLY",
  )
  assert_true(
    @imported_output_contract.calendar_occurrences(
      source,
      "2026-10-01",
      "2026-10-02",
      [0],
    )
    is Err(_),
  )
}

///|
test "window limits source selection validation empty results and ancient starts" {
  let source = occurrence_fixture(
    "DTSTART;VALUE=DATE:00010101\nRRULE:FREQ=DAILY",
  )
  guard @imported_output_contract.calendar_occurrences(
      source,
      "2024-02-28",
      "2024-03-01",
      [0],
    )
    is Ok(events) else {
    fail("ancient")
  }
  assert_eq(events.map(e => e.date), ["2024-02-28", "2024-02-29", "2024-03-01"])
  for from in ["", "2026-02-30", "0000-01-01", "2026😀-01-1", "2026-10-10"] {
    assert_true(
      @imported_output_contract.calendar_occurrences(
        source,
        from,
        "2026-10-09",
        [0],
      )
      is Err(_),
    )
  }
  assert_true(
    @imported_output_contract.calendar_occurrences(
      source,
      "2026-01-01",
      "2027-01-02",
      [0],
    )
    is Err(_),
  )
  for selection in [[], [-1], [1], [0, 0]] {
    assert_true(
      @imported_output_contract.calendar_occurrences(
        source, "2026-10-01", "2026-10-02", selection,
      )
      is Err(_),
    )
  }
  let finite = occurrence_fixture(
    "DTSTART;VALUE=DATE:20261001\nRRULE:FREQ=DAILY;COUNT=2",
  )
  assert_eq(
    @imported_output_contract.calendar_occurrences(
      finite,
      "2026-10-03",
      "2026-10-05",
      [0],
    ),
    Ok([]),
  )
  let edge = occurrence_fixture("DTSTART;VALUE=DATE:99991231")
  assert_true(
    @imported_output_contract.calendar_occurrences(
      edge,
      "9999-12-31",
      "9999-12-31",
      [0],
    )
    is Err(_),
  )
}

///|
test "occurrence caps never truncate and malformed calendars never yield partial plans" {
  let parts : Array[String] = ["BEGIN:VCALENDAR"]
  for n = 0; n < 6; n = n + 1 {
    parts.push(
      "BEGIN:VEVENT\nUID:" +
      n.to_string() +
      "\nDTSTART;VALUE=DATE:20260101\nRRULE:FREQ=DAILY\nEND:VEVENT",
    )
  }
  parts.push("END:VCALENDAR")
  assert_true(
    @imported_output_contract.calendar_occurrences(
      parts.join("\n"),
      "2026-01-01",
      "2026-12-31",
      [0, 1, 2, 3, 4, 5],
    )
    is Err(_),
  )
  let source = occurrence_fixture("DTSTART:20261001T090000Z")
  for
    broken in [
      source + "\nBEGIN:VCALENDAR",
      source.replace_all(old="END:VEVENT", new="END:VALARM"),
      source.replace_all(old="BEGIN:VEVENT", new="METHOD:CANCEL\nBEGIN:VEVENT"),
    ] {
    assert_true(
      @imported_output_contract.calendar_occurrences(
        broken,
        "2026-10-01",
        "2026-10-10",
        [0],
      )
      is Err(_),
    )
  }
}

///|
test "occurrence exports state subset and window escape markup and reopen CSV" {
  let source = occurrence_fixture(
    "DTSTART:20261001T090000Z\nRRULE:FREQ=DAILY;COUNT=3\nDESCRIPTION:<script>\\nhello\nLOCATION:=North",
  )
  guard @imported_output_contract.calendar_occurrences(
      source,
      "2026-10-01",
      "2026-10-03",
      [0],
    )
    is Ok(events) else {
    fail("expand")
  }
  let md = @imported_output_contract.calendar_occurrence_itinerary(
    events,
    [1],
    "2026-10-01",
    "2026-10-03",
  )
  assert_true(md.contains("explicitly selected source entries only"))
  assert_true(md.contains("through 2026-10-03"))
  assert_true(md.contains("## 2026-10-02"))
  assert_false(md.contains("Recurrence not expanded"))
  assert_true(md.contains("&lt;script&gt;"))
  guard @imported_output_contract.parse_data_table(
      @imported_output_contract.calendar_occurrence_csv(
        events,
        [1],
        "2026-10-01",
        "2026-10-03",
      ),
      ',',
    )
    is Ok(table) else {
    fail("CSV")
  }
  assert_eq(table.rows.length(), 1)
  assert_eq(table.rows[0][1], "2026-10-02 09:00:00")
  assert_eq(table.rows[0][4], "'=North")
  assert_true(table.headers[8].contains("selected-source subset"))
}

///|
test "expanded field cap is atomic and tentative status is retained" {
  let source = occurrence_fixture(
    "DTSTART;VALUE=DATE:20260101\nRRULE:FREQ=DAILY\nDESCRIPTION:" +
    "x".repeat(12000),
  )
  assert_true(
    @imported_output_contract.calendar_occurrences(
      source,
      "2026-01-01",
      "2026-12-31",
      [0],
    )
    is Err(_),
  )
  let tentative = occurrence_fixture(
    "DTSTART;VALUE=DATE:20261001\nSTATUS:TENTATIVE",
  )
  guard @imported_output_contract.calendar_occurrences(
      tentative,
      "2026-10-01",
      "2026-10-01",
      [0],
    )
    is Ok([event]) else {
    fail("tentative")
  }
  assert_true(event.recurrence.contains("STATUS=TENTATIVE"))
  assert_eq(event.end, "2026-10-02 · all day")
}
