///|
test "calendar normal itinerary unfolds text labels zones and exports selected rows" {
  let source = "BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\nUID:walk\r\nDTSTART:20261009T090000Z\r\nDTEND:20261009T100000Z\r\nSUMMARY:River walk\r\nLOCATION:North\\, gate\r\nDESCRIPTION:Bring notes\\nMeet by the\r\n  bridge\\; thanks\r\nURL:https://example.invalid/walk\r\nEND:VEVENT\r\nBEGIN:VEVENT\r\nDTSTART;VALUE=DATE:20261010\r\nDTEND;VALUE=DATE:20261011\r\nSUMMARY:Deadline\r\nEND:VEVENT\r\nBEGIN:VEVENT\r\nDTSTART;TZID=Asia/Shanghai:20261009T150000\r\nSUMMARY:Studio\r\nRRULE:FREQ=WEEKLY;COUNT=4\r\nEND:VEVENT\r\nBEGIN:VEVENT\r\nDTSTART:20261011T103000\r\nSUMMARY:Coffee\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n"
  guard @imported_output_contract.parse_calendar(source) is Ok(events) else {
    fail("calendar")
  }
  assert_eq(events.length(), 4)
  assert_eq(events[0].description, "Bring notes\nMeet by the bridge; thanks")
  assert_eq(events[0].location, "North, gate")
  assert_eq(events[0].zone, "UTC")
  assert_eq(events[1].zone, "Asia/Shanghai (unconverted)")
  assert_eq(events[2].zone, "all day")
  assert_eq(events[3].zone, "floating (unconverted)")
  let matches = @imported_output_contract.calendar_matches(
    events, "notes", "2026-10-09", "2026-10-09", "NORTH",
  )
  assert_eq(matches, [0])
  let markdown = @imported_output_contract.calendar_itinerary(events, [0, 1, 2])
  assert_true(markdown.contains("## 2026-10-10"))
  assert_true(markdown.contains("RRULE=FREQ=WEEKLY;COUNT=4"))
  guard @imported_output_contract.parse_data_table(
      @imported_output_contract.calendar_csv(events, matches),
      ',',
    )
    is Ok(csv) else {
    fail("export")
  }
  assert_eq(csv.rows.length(), 1)
  assert_eq(csv.rows[0][0], "River walk")
  assert_eq(csv.rows[0][5], events[0].description)
  assert_true(
    @imported_output_contract.calendar_file("calendar.ICS", "text/plain"),
  )
  assert_false(
    @imported_output_contract.calendar_file("preview.txt", "text/calendar"),
  )
}

///|
test "calendar malformed source falls back and nested alarm does not overwrite event" {
  assert_true(
    @imported_output_contract.parse_calendar("BEGIN:VCALENDAR\n") is Err(_),
  )
  assert_true(
    @imported_output_contract.parse_calendar(
      "BEGIN:VCALENDAR\nBEGIN:VEVENT\nDTSTART:20260230\nEND:VEVENT\nEND:VCALENDAR",
    )
    is Err(_),
  )
  guard @imported_output_contract.parse_calendar(
      "BEGIN:VCALENDAR\nBEGIN:VEVENT\nDTSTART:20261009T090000Z\nSUMMARY:=Bad <script>\nBEGIN:VALARM\nDESCRIPTION:alarm text\nEND:VALARM\nEND:VEVENT\nEND:VCALENDAR",
    )
    is Ok(events) else {
    fail("alarm")
  }
  assert_eq(events[0].description, "")
  assert_true(
    @imported_output_contract.calendar_csv(events, [0]).contains("'=Bad"),
  )
  assert_true(
    @imported_output_contract.calendar_itinerary(events, [0]).contains(
      "&lt;script&gt;",
    ),
  )
}
