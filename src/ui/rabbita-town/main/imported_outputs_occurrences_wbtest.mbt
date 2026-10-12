///|
fn occurrence_ui_fixture() -> ImportedOutputsState raise {
  imported_table_fixture(
    "BEGIN:VCALENDAR\nBEGIN:VEVENT\nUID:daily\nDTSTART:20261001T090000Z\nDTEND:20261001T100000Z\nSUMMARY:Daily review\nLOCATION:North\nRRULE:FREQ=DAILY;COUNT=5\nEXDATE:20261003T090000Z\nEND:VEVENT\nBEGIN:VEVENT\nUID:coffee\nDTSTART:20261002T100000\nSUMMARY:Floating coffee\nEND:VEVENT\nEND:VCALENDAR",
    filename="recurring.ics",
  )
}

///|
fn occurrence_ui_expanded() -> ImportedOutputsState raise {
  let state = occurrence_ui_fixture()
  let state = imported_outputs_transition(state, AgendaEvent(Toggle(0))).0
  let state = imported_outputs_transition(
      state,
      AgendaEvent(WindowFrom("2026-10-02")),
    ).0
  let state = imported_outputs_transition(
      state,
      AgendaEvent(WindowUntil("2026-10-05")),
    ).0
  imported_outputs_transition(state, AgendaEvent(Expand)).0
}

///|
test "compiled occurrence journey selects mixed sources expands inspects and exports dated subset" {
  let state = occurrence_ui_expanded()
  guard state.agenda.occurrences is Some(Ok(events)) else { fail("expand") }
  assert_eq(events.map(e => e.date), ["2026-10-02", "2026-10-04", "2026-10-05"])
  assert_eq(state.agenda.source_selected, [0])
  assert_eq(state.agenda.selected, [])
  let html = imported_fixture_render(state)
  assert_true(html.contains("Dated occurrence itinerary"))
  assert_true(html.contains("3 of 3 dated occurrences"))
  assert_true(html.contains("Window 2026-10-02 through 2026-10-05"))
  assert_true(html.contains("1 explicitly selected source entries"))
  assert_false(html.contains("Floating coffee"))
  let selected = imported_outputs_transition(state, AgendaEvent(Toggle(1))).0
  guard imported_outputs_transition(selected, AgendaEvent(Export(false))).1
    is Some(SaveFilteredTable(md, filename)) else {
    fail("Markdown export")
  }
  assert_eq(filename, "selected-occurrence-itinerary.md")
  assert_true(md.contains("## 2026-10-04"))
  assert_false(md.contains("## 2026-10-02"))
  assert_true(md.contains("explicitly selected source entries only"))
  assert_false(md.contains("Recurrences are not expanded"))
  guard imported_outputs_transition(selected, AgendaEvent(Export(true))).1
    is Some(SaveFilteredTable(csv, csv_name)) else {
    fail("CSV export")
  }
  assert_eq(csv_name, "selected-occurrences.csv")
  guard @imported_output_contract.parse_data_table(csv, ',') is Ok(table) else {
    fail("CSV reopen")
  }
  assert_eq(table.rows.length(), 1)
  assert_eq(table.rows[0][1], "2026-10-04 09:00:00")
  assert_true(table.headers[8].contains("2026-10-02 through 2026-10-05"))
  let hidden = imported_outputs_transition(
      selected,
      AgendaEvent(Query("no match")),
    ).0
  assert_true(
    imported_fixture_render(hidden).contains("No dated occurrences match"),
  )
  assert_eq(hidden.agenda.selected, [1])
  assert_eq(
    imported_outputs_transition(hidden, AgendaEvent(Export(true))).1,
    imported_outputs_transition(selected, AgendaEvent(Export(true))).1,
  )
  let raw = imported_outputs_transition(selected, AgendaEvent(Raw)).0
  assert_true(imported_fixture_render(raw).contains("BEGIN:VCALENDAR"))
  assert_eq(
    imported_outputs_transition(raw, AgendaEvent(Raw)).0.agenda.selected,
    [1],
  )
}

///|
test "compiled occurrence regeneration window changes source return and dismissal invalidate positional selection" {
  let selected = imported_outputs_transition(
      occurrence_ui_expanded(),
      AgendaEvent(Toggle(1)),
    ).0
  let regenerated = imported_outputs_transition(selected, AgendaEvent(Expand)).0
  assert_eq(regenerated.agenda.selected, [])
  assert_eq(
    imported_outputs_transition(regenerated, AgendaEvent(Export(true))).1,
    None,
  )
  let changed = imported_outputs_transition(
      selected,
      AgendaEvent(WindowFrom("2026-10-04")),
    ).0
  assert_eq(changed.agenda.occurrences, None)
  assert_eq(changed.agenda.selected, [0])
  assert_true(imported_fixture_render(changed).contains("Calendar agenda"))
  let expanded = imported_outputs_transition(changed, AgendaEvent(Expand)).0
  guard expanded.agenda.occurrences is Some(Ok(events)) else {
    fail("re-expand")
  }
  assert_eq(events.map(e => e.date), ["2026-10-04", "2026-10-05"])
  assert_eq(expanded.agenda.selected, [])
  let sources = imported_outputs_transition(selected, AgendaEvent(Sources)).0
  assert_eq(sources.agenda.selected, [0])
  assert_eq(sources.agenda.occurrences, None)
  guard imported_outputs_transition(sources, AgendaEvent(Export(false))).1
    is Some(SaveFilteredTable(md, filename)) else {
    fail("source export")
  }
  assert_eq(filename, "selected-itinerary.md")
  assert_true(md.contains("Recurrences are not expanded"))
  for
    msg in [
      CloseImportedOutputs,
      RefreshImportedOutputs,
      ChooseImportedFile(selected.selection.unwrap().path),
    ] {
    let reset = imported_outputs_transition(selected, msg).0
    assert_eq(reset.agenda, initial_agenda())
    assert_eq(
      imported_outputs_transition(reset, AgendaEvent(Export(true))).1,
      None,
    )
  }
}

///|
test "compiled occurrence unsupported selection error no partial export repair and empty window" {
  let state = occurrence_ui_fixture()
  let state = imported_outputs_transition(state, AgendaEvent(SelectMatching)).0
  let state = imported_outputs_transition(
      state,
      AgendaEvent(WindowFrom("2026-10-02")),
    ).0
  let state = imported_outputs_transition(
      state,
      AgendaEvent(WindowUntil("2026-10-05")),
    ).0
  let blocked = imported_outputs_transition(state, AgendaEvent(Expand)).0
  assert_true(blocked.agenda.occurrences is Some(Err(_)))
  let html = imported_fixture_render(blocked)
  assert_true(html.contains("Occurrence expansion unavailable"))
  assert_true(html.contains("No partial occurrence itinerary was created"))
  assert_true(html.contains("floating/named-zone"))
  assert_false(html.contains("Download itinerary (.md)"))
  assert_eq(
    imported_outputs_transition(blocked, AgendaEvent(Export(false))).1,
    None,
  )
  let repaired = imported_outputs_transition(blocked, AgendaEvent(Toggle(1))).0
  for message in [WindowFrom("2026-10-03"), WindowUntil("2026-10-04"), Sources] {
    let adjusted = imported_outputs_transition(repaired, AgendaEvent(message)).0
    assert_eq(adjusted.agenda.selected, [0])
    assert_eq(adjusted.agenda.occurrences, None)
    let again = imported_outputs_transition(adjusted, AgendaEvent(Expand)).0
    assert_true(again.agenda.occurrences is Some(Ok(_)))
    let selected = imported_outputs_transition(
        again,
        AgendaEvent(SelectMatching),
      ).0
    assert_true(
      imported_outputs_transition(selected, AgendaEvent(Export(false))).1
      is Some(SaveFilteredTable(_, _)),
    )
  }
  let repaired = imported_outputs_transition(repaired, AgendaEvent(Expand)).0
  assert_true(repaired.agenda.occurrences is Some(Ok(_)))
  let empty = imported_outputs_transition(
      repaired,
      AgendaEvent(WindowFrom("2026-11-01")),
    ).0
  let empty = imported_outputs_transition(
      empty,
      AgendaEvent(WindowUntil("2026-11-02")),
    ).0
  let empty = imported_outputs_transition(empty, AgendaEvent(Expand)).0
  assert_eq(empty.agenda.occurrences, Some(Ok([])))
  assert_true(
    imported_fixture_render(empty).contains("0 of 0 dated occurrences"),
  )
  assert_eq(
    imported_outputs_transition(empty, AgendaEvent(SelectMatching)).0.agenda.selected,
    [],
  )
  assert_eq(
    imported_outputs_transition(empty, AgendaEvent(Export(false))).1,
    None,
  )
}
