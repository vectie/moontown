///|
async test "local imported calendar discover verify agenda export and preserve exact source" {
  let content = "BEGIN:VCALENDAR\nBEGIN:VEVENT\nUID:walk\nDTSTART:20261009T090000Z\nDTEND:20261009T100000Z\nSUMMARY:River walk\nLOCATION:North gate\nDESCRIPTION:Bring notebook\nEND:VEVENT\nBEGIN:VEVENT\nUID:deadline\nDTSTART;VALUE=DATE:20261010\nSUMMARY:Proposal deadline\nLOCATION:City Hall\nEND:VEVENT\nEND:VCALENDAR\n"
  let bytes = @utf8.encode(content)
  let (home, root, selection) = fixture(
    bytes,
    filename="valley.ics",
    mime="text/calendar",
  )
  defer @fs.rmdir(home, recursive=true)
  let catalog_path = home + "/missing-catalog.json"
  let catalog = discover(catalog_path, home)
  assert_true(
    @contract.calendar_file(
      selection.path,
      catalog.books[0].outputs[0].mime_type,
    ),
  )
  let response = respond(
    "GET",
    @contract.content_path(selection, mode="text"),
    catalog_path,
    home,
  )
  assert_eq(response.status, 200)
  let reply = @contract.parse_text_reply(@utf8.decode(response.body)).unwrap()
  assert_eq(reply.selection, selection)
  guard @contract.parse_calendar(reply.content.unwrap()) is Ok(events) else {
    fail("agenda")
  }
  let selected = @contract.calendar_matches(
    events, "walk", "2026-10-09", "2026-10-09", "north",
  )
  assert_eq(selected, [0])
  assert_true(
    @contract.calendar_itinerary(events, selected).contains("River walk"),
  )
  guard @contract.parse_data_table(
      @contract.calendar_csv(events, selected),
      ',',
    )
    is Ok(csv) else {
    fail("CSV")
  }
  assert_eq(csv.rows.length(), 1)
  assert_eq(csv.rows[0][6], "walk")
  assert_eq(
    respond(
      "GET",
      @contract.content_path(selection, mode="download"),
      catalog_path,
      home,
    ).body,
    bytes,
  )
  assert_eq(@fs.read_file(root + "/" + selection.path).binary(), bytes)
  assert_false(@fs.exists(catalog_path))
}
