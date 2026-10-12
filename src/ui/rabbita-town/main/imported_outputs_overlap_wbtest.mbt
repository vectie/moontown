///|
test "compiled overlap review follows selected expanded occurrences and exports exact preview" {
  let initial = occurrence_ui_expanded()
  assert_eq(
    imported_outputs_transition(initial, AgendaEvent(ExportOverlaps)).1,
    None,
  )
  let state = imported_outputs_transition(initial, AgendaEvent(SelectMatching)).0
  let html = imported_fixture_render(state)
  assert_true(html.contains("Download overlap review (.md)"))
  assert_true(html.contains("assessed UTC intervals: 3"))
  guard imported_outputs_transition(state, AgendaEvent(ExportOverlaps)).1
    is Some(SaveFilteredTable(report, filename)) else {
    fail("export")
  }
  assert_eq(filename, "selected-occurrence-overlaps.md")
  guard state.agenda.occurrences is Some(Ok(events)) else { fail("events") }
  assert_eq(
    @imported_output_contract.calendar_overlap_report(
      events,
      state.agenda.selected,
      state.agenda.window_from,
      state.agenda.window_until,
    ),
    Ok(report),
  )
  let filtered = imported_outputs_transition(
      state,
      AgendaEvent(Query("hidden")),
    ).0
  assert_eq(
    imported_outputs_transition(filtered, AgendaEvent(ExportOverlaps)).1,
    imported_outputs_transition(state, AgendaEvent(ExportOverlaps)).1,
  )
  for msg in [AgendaMsg::Clear, Expand, Sources, WindowUntil("2026-10-06")] {
    let reset = imported_outputs_transition(state, AgendaEvent(msg)).0
    assert_eq(
      imported_outputs_transition(reset, AgendaEvent(ExportOverlaps)).1,
      None,
    )
    assert_false(
      imported_fixture_render(reset).contains("Download overlap review (.md)"),
    )
  }
}

///|
test "compiled actual overlapping fixture shows pair and unknown duration" {
  let text = "BEGIN:VCALENDAR\nBEGIN:VEVENT\nUID:a\nDTSTART:20261009T090000Z\nDTEND:20261009T100000Z\nSUMMARY:First\nEND:VEVENT\nBEGIN:VEVENT\nUID:b\nDTSTART:20261009T093000Z\nDTEND:20261009T103000Z\nSUMMARY:Second\nEND:VEVENT\nBEGIN:VEVENT\nUID:c\nDTSTART:20261009T094500Z\nSUMMARY:Unknown\nEND:VEVENT\nEND:VCALENDAR"
  let state = imported_table_fixture(text, filename="overlap.ics")
  let state = imported_outputs_transition(state, AgendaEvent(SelectMatching)).0
  assert_eq(
    imported_outputs_transition(state, AgendaEvent(ExportOverlaps)).1,
    None,
  )
  let state = imported_outputs_transition(
      state,
      AgendaEvent(WindowFrom("2026-10-09")),
    ).0
  let state = imported_outputs_transition(
      state,
      AgendaEvent(WindowUntil("2026-10-09")),
    ).0
  let state = imported_outputs_transition(state, AgendaEvent(Expand)).0
  let state = imported_outputs_transition(state, AgendaEvent(SelectMatching)).0
  assert_true(imported_fixture_render(state).contains("overlap pairs: 1"))
  guard imported_outputs_transition(state, AgendaEvent(ExportOverlaps)).1
    is Some(SaveFilteredTable(report, _)) else {
    fail("export")
  }
  assert_true(
    report.contains("2026-10-09 09:30:00 → 2026-10-09 10:00:00 UTC"),
  )
  assert_true(report.contains("unassessed: 1"))
  let state = imported_outputs_transition(state, AgendaEvent(Toggle(1))).0
  assert_true(imported_fixture_render(state).contains("overlap pairs: 0"))
  assert_true(imported_fixture_render(state).contains("unassessed: 1"))
}
