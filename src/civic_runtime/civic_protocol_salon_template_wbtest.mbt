///|
async test "civic salon scenario template can seed a non-hardcoded domain" {
  let root = cleaned_civic_protocol_test_root(
    "/tmp/moontown-civic-salon-template",
  )
  let template_path = write_test_civic_salon_template(root)
  let book_catalog_path = "\{root}/catalog.json"
  let scenario = test_civic_salon_scenario()
  let summary = bootstrap_civic_salon_scenario_file(
    template_path,
    book_catalog_path~,
    round_id="future-energy-round-1",
    round_number=1,
    workspace_base=root,
    reducer_mode=FixtureReducer,
  )
  assert_true(summary.contains("Future Energy Social Square Salon"))
  assert_true(summary.contains("2 internal participant perspective"))
  assert_true(
    @fs.exists(
      "\{root}/books/future-energy-storage/raw/bootstrap/FUTURE_ENERGY_SALON_CONTRACT.md",
    ),
  )
  let projection = @fs.read_file(
    "\{root}/books/wenyu-social-square/book/moonbook-ui-state.json",
  ).text()
  assert_true(projection.contains("Future Energy Social Square Salon"))
  assert_true(projection.contains("future energy"))
  assert_true(projection.contains("\"projection_scope\": \"public\""))
  let returned = @fs.read_file(
    "\{root}/books/future-energy-grid-ai/wiki/queries/salon-returned-ideas.md",
  ).text()
  assert_true(returned.contains("Storage-Grid Control Contract"))
  let participant_projection = @fs.read_file(
    "\{root}/books/future-energy-grid-ai/book/moonbook-ui-state.json",
  ).text()
  assert_true(
    participant_projection.contains("\"projection_scope\": \"internal\""),
  )
  assert_true(participant_projection.contains("\"participant-workspace\""))
  let snapshot_path = "\{root}/town.json"
  assert_true(
    @fs.exists(civic_salon_scenario_path(scenario.id, snapshot_path~)),
  )
  let schedules = load_or_create_civic_salon_schedules(
    path=default_civic_salon_schedule_path(snapshot_path~),
  )
  assert_eq(schedules.length(), 1)
  let schedule = schedules[0]
  assert_eq(schedule.id, scenario.id)
  assert_eq(schedule.round_count, 1)
  assert_eq(schedule.latest_round_id, "future-energy-round-1")
  assert_true(schedule.next_due_ms > schedule.last_run_ms)
}

///|
async test "civic pattern template uses scenario round id by default" {
  let root = cleaned_civic_protocol_test_root(
    "/tmp/moontown-civic-pattern-template-default-round",
  )
  let template_path = write_test_civic_salon_template(root)
  let summary = bootstrap_civic_salon_scenario_file(
    template_path,
    book_catalog_path="\{root}/catalog.json",
    workspace_base=root,
    reducer_mode=FixtureReducer,
  )
  assert_true(summary.contains("future-energy-social-square-round-1"))
  let schedules = load_or_create_civic_salon_schedules(
    path=default_civic_salon_schedule_path(snapshot_path="\{root}/town.json"),
  )
  assert_eq(schedules.length(), 1)
  assert_eq(schedules[0].latest_round_id, "future-energy-social-square-round-1")
}

///|
async test "civic salon scenario can define a building protocol without registry code" {
  let root = cleaned_civic_protocol_test_root(
    "/tmp/moontown-civic-salon-generic-building",
  )
  let scenario = {
    ..test_civic_salon_scenario(),
    id: "future-energy-forum",
    title: "Future Energy Forum Salon",
    building_id: "future-energy-forum",
    building_book_id: "future-energy-forum-book",
  }
  let summary = bootstrap_civic_salon_scenario(
    scenario,
    book_catalog_path="\{root}/catalog.json",
    round_id="future-energy-forum-round-1",
    round_number=1,
    workspace_base=root,
    reducer_mode=FixtureReducer,
  )
  assert_true(summary.contains("Future Energy Forum Salon"))
  assert_true(
    @fs.exists(
      "\{root}/books/future-energy-forum-book/book/moonbook-ui-state.json",
    ),
  )
  let projection = @fs.read_file(
    "\{root}/books/future-energy-forum-book/book/moonbook-ui-state.json",
  ).text()
  assert_true(projection.contains("\"book_id\": \"future-energy-forum-book\""))
  assert_true(projection.contains("\"projection_scope\": \"public\""))
  let protocol = civic_communication_protocol_for_scenario(scenario)
  assert_eq(protocol.building_id, "future-energy-forum")
  assert_eq(protocol.book_id, "future-energy-forum-book")
  assert_eq(protocol.input_channels.length(), 1)
  assert_eq(protocol.input_channels[0], "domain_perspective")
}
