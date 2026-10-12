///|
test "calendar agenda normal filtered selected itinerary and raw journey" {
  let content = "BEGIN:VCALENDAR\nBEGIN:VEVENT\nUID:walk\nDTSTART:20261009T090000Z\nSUMMARY:River walk\nLOCATION:North gate\nEND:VEVENT\nBEGIN:VEVENT\nDTSTART;VALUE=DATE:20261010\nSUMMARY:Deadline\nLOCATION:City Hall\nEND:VEVENT\nEND:VCALENDAR"
  let state = imported_table_fixture(content, filename="valley.ics")
  assert_true(state.agenda.events is Some(Ok(_)))
  let html = imported_fixture_render(state)
  assert_true(html.contains("Calendar agenda"))
  assert_true(html.contains("2026-10-09"))
  assert_true(html.contains("2 of 2 source events"))
  let filtered = imported_outputs_transition(
      state,
      AgendaEvent(Location("North")),
    ).0
  let filtered = imported_outputs_transition(
      filtered,
      AgendaEvent(From("2026-10-09")),
    ).0
  let filtered = imported_outputs_transition(
      filtered,
      AgendaEvent(Until("2026-10-09")),
    ).0
  let filtered = imported_outputs_transition(
      filtered,
      AgendaEvent(Query("walk")),
    ).0
  assert_true(
    imported_fixture_render(filtered).contains("1 of 2 source events"),
  )
  let selected = imported_outputs_transition(
      filtered,
      AgendaEvent(SelectMatching),
    ).0
  assert_eq(selected.agenda.selected, [0])
  guard imported_outputs_transition(selected, AgendaEvent(Export(false))).1
    is Some(SaveFilteredTable(md, filename)) else {
    fail("itinerary")
  }
  assert_eq(filename, "selected-itinerary.md")
  assert_true(md.contains("River walk"))
  guard imported_outputs_transition(selected, AgendaEvent(Export(true))).1
    is Some(SaveFilteredTable(csv, _)) else {
    fail("CSV")
  }
  assert_true(csv.contains("North gate"))
  assert_false(csv.contains("Deadline"))
  let hidden = imported_outputs_transition(
      selected,
      AgendaEvent(Query("no match")),
    ).0
  assert_eq(hidden.agenda.selected, [0])
  assert_true(
    imported_fixture_render(hidden).contains("No source events match"),
  )
  let raw = imported_outputs_transition(selected, AgendaEvent(Raw)).0
  assert_true(imported_fixture_render(raw).contains("BEGIN:VCALENDAR"))
  assert_eq(
    imported_outputs_transition(selected, AgendaEvent(Toggle(0))).0.agenda.selected,
    [],
  )
  assert_eq(
    imported_outputs_transition(selected, AgendaEvent(Clear)).0.agenda.selected,
    [],
  )
  assert_eq(
    imported_outputs_transition(
      selected,
      ChooseImportedFile(state.selection.unwrap().path),
    ).0.agenda,
    initial_agenda(),
  )
  assert_eq(
    imported_outputs_transition(selected, RefreshImportedOutputs).0.agenda,
    initial_agenda(),
  )
  let closed = imported_outputs_transition(selected, CloseImportedOutputs).0
  assert_eq(closed.agenda, initial_agenda())
  assert_eq(
    imported_outputs_transition(closed, AgendaEvent(Export(true))).1,
    None,
  )
}

///|
test "calendar raw fallback and inert content" {
  let broken = imported_table_fixture("BEGIN:VCALENDAR", filename="broken.ics")
  assert_true(imported_fixture_render(broken).contains("Agenda unavailable"))
  let state = imported_table_fixture(
    "BEGIN:VCALENDAR\nBEGIN:VEVENT\nDTSTART:20261009\nSUMMARY:<script>\nURL:javascript:alert(1)\nEND:VEVENT\nEND:VCALENDAR",
    filename="inert.ics",
  )
  let html = imported_fixture_render(state)
  assert_true(html.contains("&lt;script&gt;"))
  assert_false(html.contains("<script>"))
  assert_false(html.contains("href=\"javascript:"))
}
