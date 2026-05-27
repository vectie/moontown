///|
test "civic salon schedule uses real wall-clock due checks" {
  let schedule = CivicSalonSchedule::new(
    id="embodied-robotics-social-square",
    title="Embodied Robotics Social Square Salon",
    building_id="social-square",
    topic="embodied robotics",
    interval_ms=1_800_000UL,
    next_due_ms=10UL,
  )
  assert_true(!civic_salon_is_due(schedule, 9UL))
  assert_true(civic_salon_is_due(schedule, 10UL))
  let next = complete_civic_salon_schedule(
    schedule, 10UL, "embodied-robotics-social-square-round-1", "done",
  )
  assert_eq(next.round_count, 1)
  assert_eq(next.last_run_ms, 10UL)
  assert_eq(next.next_due_ms, 1_800_010UL)
  assert_eq(next.latest_round_id, "embodied-robotics-social-square-round-1")
}

///|
test "civic salon round record captures exchange effectiveness" {
  let participants = embodied_robotics_participant_books()
  let ideas = embodied_robotics_salon_ideas()
  let metrics = embodied_robotics_salon_metrics(participants, ideas)
  let schedule = default_civic_salon_schedules().get(0).unwrap()
  let record = civic_salon_round_record(
    schedule, "embodied-robotics-social-square-round-1", 7, 100UL, 200UL, metrics,
    "review", "round complete",
  )
  assert_eq(record.tick, 7)
  assert_eq(record.participant_count, 10)
  assert_eq(record.idea_count, 5)
  assert_eq(record.research_question_count, 15)
  assert_eq(record.participant_idea_links, 21)
  assert_eq(record.idea_return_home_count, 21)
  assert_eq(record.structural_effectiveness_score, 100)
}

///|
async test "due civic salon rounds persist schedule and run ledger" {
  let root = "/tmp/moontown-civic-salon-daemon"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let book_catalog_path = "\{root}/books/catalog.json"
  let summary = run_due_civic_salons(
    snapshot_path~,
    book_catalog_path~,
    tick=3,
    now_ms=1_000UL,
  )
  assert_true(summary.has_prefix("Ran 1 civic salon"))
  let schedule_path = default_civic_salon_schedule_path(snapshot_path~)
  let ledger_path = default_civic_salon_run_ledger_path(
    "embodied-robotics-social-square",
    snapshot_path~,
  )
  assert_true(@fs.exists(schedule_path))
  assert_true(@fs.exists(ledger_path))
  let schedules = load_or_create_civic_salon_schedules(path=schedule_path)
  let schedule = schedules.get(0).unwrap()
  assert_eq(schedule.round_count, 1)
  assert_eq(schedule.next_due_ms, 1_801_000UL)
  assert_true(schedule.latest_round_id.contains("round-1"))
  let ledger = @fs.read_file(ledger_path).text()
  assert_true(ledger.contains("\"tick\":3"))
  assert_true(ledger.contains("\"idea_count\":5"))
  let projection = @fs.read_file(
    "\{root}/books/wenyu-social-square/book/moonbook-ui-state.json",
  ).text()
  assert_true(projection.contains("embodied-robotics-social-square-round-1"))
  assert_true(projection.contains("round 1"))
}

///|
async test "stale civic salon projection refreshes without forcing another round" {
  let root = "/tmp/moontown-civic-salon-refresh"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let book_catalog_path = "\{root}/books/catalog.json"
  let schedule = {
    ..default_civic_salon_schedules().get(0).unwrap(),
    last_run_ms: 1_000UL,
    next_due_ms: 999_999UL,
    round_count: 2,
    latest_round_id: "embodied-robotics-social-square-round-2",
    latest_summary: "round two finished",
  }
  save_civic_salon_schedules(
    default_civic_salon_schedule_path(snapshot_path~),
    [schedule],
  )
  write_text_file(
    civic_salon_projection_path(schedule, snapshot_path),
    "{\"book_id\":\"wenyu-social-square\",\"status_chips\":[{\"label\":\"round 1\",\"tone\":\"info\"}]}",
  )
  let summary = run_due_civic_salons(
    snapshot_path~,
    book_catalog_path~,
    tick=99,
    now_ms=2_000UL,
  )
  assert_true(summary.has_prefix("Refreshed 1 civic salon projection"))
  let refreshed = @fs.read_file(
    "\{root}/books/wenyu-social-square/book/moonbook-ui-state.json",
  ).text()
  assert_true(refreshed.contains("embodied-robotics-social-square-round-2"))
  assert_true(refreshed.contains("round 2"))
  let schedules = load_or_create_civic_salon_schedules(
    path=default_civic_salon_schedule_path(snapshot_path~),
  )
  let persisted = schedules.get(0).unwrap()
  assert_eq(persisted.round_count, 2)
  assert_eq(persisted.next_due_ms, 999_999UL)
}
