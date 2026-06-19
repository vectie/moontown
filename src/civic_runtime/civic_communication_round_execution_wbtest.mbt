///|
async test "due civic salon rounds persist schedule and run ledger" {
  let root = "/tmp/moontown-civic-salon-daemon"
  @support.ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let book_catalog_path = "\{root}/books/catalog.json"
  let schedule = daemon_civic_communication_schedule()
  save_civic_communication_schedules(
    default_civic_communication_schedule_path(snapshot_path~),
    [schedule],
  )
  @support.write_text_file(
    civic_communication_scenario_path(schedule.id, snapshot_path~),
    daemon_civic_communication_scenario().to_json().stringify(indent=2),
  )
  let summary = run_due_civic_communication_patterns(
    snapshot_path~,
    book_catalog_path~,
    tick=3,
    now_ms=1_000UL,
    reducer_mode=FixtureReducer,
  )
  assert_true(summary.has_prefix("Ran 1 civic communication-pattern"))
  let schedule_path = default_civic_communication_schedule_path(snapshot_path~)
  let ledger_path = default_civic_communication_run_ledger_path(
    "future-energy-social-square",
    snapshot_path~,
  )
  assert_true(@fs.exists(schedule_path))
  assert_true(@fs.exists(ledger_path))
  let schedules = load_or_create_civic_communication_schedules(
    path=schedule_path,
  )
  let persisted = schedules.get(0).unwrap()
  assert_eq(persisted.round_count, 1)
  assert_eq(persisted.next_due_ms, 1_801_000UL)
  assert_true(persisted.latest_round_id.contains("round-1"))
  let ledger = @fs.read_file(ledger_path).text()
  assert_true(ledger.contains("\"tick\":3"))
  assert_true(ledger.contains("\"idea_count\":1"))
  let projection = @fs.read_file(
    "\{root}/books/wenyu-social-square/book/moonbook-ui-state.json",
  ).text()
  assert_true(projection.contains("future-energy-social-square-round-1"))
  assert_true(projection.contains("round 1"))
}

///|
async test "stale civic salon projection refreshes without forcing another round" {
  let root = "/tmp/moontown-civic-salon-refresh"
  @support.ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let book_catalog_path = "\{root}/books/catalog.json"
  let schedule = {
    ..daemon_civic_communication_schedule(),
    last_run_ms: 1_000UL,
    next_due_ms: 999_999UL,
    round_count: 2,
    latest_round_id: "future-energy-social-square-round-2",
    latest_summary: "round two finished",
  }
  save_civic_communication_schedules(
    default_civic_communication_schedule_path(snapshot_path~),
    [schedule],
  )
  let scenario = daemon_civic_communication_scenario()
  @support.write_text_file(
    civic_communication_scenario_path(schedule.id, snapshot_path~),
    scenario.to_json().stringify(indent=2),
  )
  @support.write_text_file(
    civic_communication_projection_path_for_scenario(scenario, snapshot_path),
    "{\"book_id\":\"wenyu-social-square\",\"status_chips\":[{\"label\":\"round 1\",\"tone\":\"info\"}]}",
  )
  @support.write_text_file(
    "\{root}/books/wenyu-social-square/\{@civic.civic_reducer_output_relative_path()}",
    Json::object({
      "ideas": daemon_civic_communication_scenario().ideas.to_json(),
    }).stringify(indent=2),
  )
  let summary = run_due_civic_communication_patterns(
    snapshot_path~,
    book_catalog_path~,
    tick=99,
    now_ms=2_000UL,
  )
  assert_true(
    summary.has_prefix("Refreshed 1 civic communication-pattern projection"),
  )
  let refreshed = @fs.read_file(
    "\{root}/books/wenyu-social-square/book/moonbook-ui-state.json",
  ).text()
  assert_true(refreshed.contains("future-energy-social-square-round-2"))
  assert_true(refreshed.contains("round 2"))
  let schedules = load_or_create_civic_communication_schedules(
    path=default_civic_communication_schedule_path(snapshot_path~),
  )
  let persisted = schedules.get(0).unwrap()
  assert_eq(persisted.round_count, 2)
  assert_eq(persisted.next_due_ms, 999_999UL)
}

///|
async test "persisted civic reducer prefers scenario-specific output over shared building output" {
  let root = "/tmp/moontown-civic-salon-specific-output"
  @support.ignore_checked_command("rm", ["-rf", root])
  let scenario = daemon_civic_communication_scenario()
  let workspace_base = root
  let raw_root = "\{root}/books/wenyu-social-square/raw/bootstrap"
  @support.write_text_file(
    "\{raw_root}/civic-communication-results.json",
    Json::object({
      "ideas": [{ ..scenario.ideas[0], participating_books: ["other-book"] }].to_json(),
    }).stringify(indent=2),
  )
  @support.write_text_file(
    "\{raw_root}/future-energy-social-square-ideas.json",
    Json::object({ "ideas": scenario.ideas.to_json() }).stringify(indent=2),
  )
  let reduction = reduce_civic_communication_outputs(
    scenario,
    round_id="future-energy-social-square-round-1",
    round_number=1,
    workspace_base~,
    mode=PersistedReducer,
  )
  assert_true(reduction.status is Completed)
  assert_eq(reduction.ideas.length(), 1)
  assert_eq(reduction.ideas[0].id, "storage-grid-control-contract")
}

///|
async test "active civic schedule reconciles completed persisted reducer output" {
  let root = "/tmp/moontown-civic-salon-active-reconcile"
  @support.ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let book_catalog_path = "\{root}/books/catalog.json"
  let schedule = {
    ..daemon_civic_communication_schedule(next_due_ms=999_999UL),
    latest_round_id: "future-energy-social-square-round-1",
    latest_summary: "Running Future Energy Social Square Salon future-energy-social-square-round-1: MoonClaw reducer is still active.",
  }
  let scenario = daemon_civic_communication_scenario()
  save_civic_communication_schedules(
    default_civic_communication_schedule_path(snapshot_path~),
    [schedule],
  )
  @support.write_text_file(
    civic_communication_scenario_path(schedule.id, snapshot_path~),
    scenario.to_json().stringify(indent=2),
  )
  @support.write_text_file(
    "\{root}/books/wenyu-social-square/raw/bootstrap/future-energy-social-square-ideas.json",
    Json::object({ "ideas": scenario.ideas.to_json() }).stringify(indent=2),
  )
  let summary = run_due_civic_communication_patterns(
    snapshot_path~,
    book_catalog_path~,
    tick=100,
    now_ms=2_000UL,
  )
  assert_true(summary.contains("completed active reducer round"))
  let schedules = load_or_create_civic_communication_schedules(
    path=default_civic_communication_schedule_path(snapshot_path~),
  )
  let persisted = schedules.get(0).unwrap()
  assert_eq(persisted.round_count, 1)
  assert_eq(persisted.latest_round_id, "future-energy-social-square-round-1")
  assert_true(persisted.latest_summary.contains("Seeded"))
}
