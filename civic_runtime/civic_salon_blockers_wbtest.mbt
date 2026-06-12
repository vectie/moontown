///|
async test "invalid civic scenario blocks instead of crashing protocol seeding" {
  let root = "/tmp/moontown-civic-salon-invalid-output"
  @support.ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let book_catalog_path = "\{root}/books/catalog.json"
  let schedule = daemon_civic_salon_schedule()
  let scenario = { ..daemon_civic_salon_scenario(), participants: [] }
  save_civic_salon_schedules(
    default_civic_salon_schedule_path(snapshot_path~),
    [schedule],
  )
  @support.write_text_file(
    civic_salon_scenario_path(schedule.id, snapshot_path~),
    scenario.to_json().stringify(indent=2),
  )
  let summary = run_due_civic_salons(
    snapshot_path~,
    book_catalog_path~,
    tick=5,
    now_ms=1_000UL,
    reducer_mode=FixtureReducer,
  )
  assert_true(summary.contains("invalid civic communication-pattern output"))
  assert_true(summary.contains("scenario has no participant workspaces"))
  let schedules = load_or_create_civic_salon_schedules(
    path=default_civic_salon_schedule_path(snapshot_path~),
  )
  match schedules {
    [persisted, ..] => {
      assert_eq(persisted.round_count, 0)
      assert_true(persisted.latest_summary.has_prefix("Blocked "))
    }
    [] => fail("expected persisted schedule")
  }
}

///|
async test "invalid civic idea participant reference is reviewable blocker" {
  let root = "/tmp/moontown-civic-salon-invalid-reference"
  @support.ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let book_catalog_path = "\{root}/books/catalog.json"
  let schedule = daemon_civic_salon_schedule()
  let base = daemon_civic_salon_scenario()
  let bad_idea = {
    ..base.ideas[0],
    participating_books: ["future-energy-storage", "missing-book"],
  }
  let scenario = { ..base, ideas: [bad_idea] }
  save_civic_salon_schedules(
    default_civic_salon_schedule_path(snapshot_path~),
    [schedule],
  )
  @support.write_text_file(
    civic_salon_scenario_path(schedule.id, snapshot_path~),
    scenario.to_json().stringify(indent=2),
  )
  let summary = run_due_civic_salons(
    snapshot_path~,
    book_catalog_path~,
    tick=6,
    now_ms=1_000UL,
    reducer_mode=FixtureReducer,
  )
  assert_true(summary.contains("references non-participant book"))
  assert_true(summary.contains("missing-book"))
}

///|
test "live civic reducer statuses remain running rather than blocked" {
  assert_true(
    civic_salon_reduction_status_live(
      @core.TaskExecutionStatus::ProposalImported,
    ),
  )
  assert_true(
    civic_salon_reduction_status_live(@core.TaskExecutionStatus::RunConfirmed),
  )
  assert_true(
    civic_salon_reduction_status_live(@core.TaskExecutionStatus::Running),
  )
  assert_true(
    !civic_salon_reduction_status_live(@core.TaskExecutionStatus::Failed),
  )
  assert_true(
    !civic_salon_reduction_status_live(@core.TaskExecutionStatus::Completed),
  )
}

///|
test "legacy pending civic blocker summaries normalize to running" {
  let summary = "Blocked Social Square Match Market round-3: MoonClaw reducer did not produce a valid non-empty CivicSalonIdea contract. status=RunConfirmed; MoonClaw run run-1 is Pending."
  let normalized = normalize_civic_pending_summary(summary)
  assert_true(normalized.has_prefix("Running Social Square Match Market"))
  assert_true(!normalized.has_prefix("Blocked "))
}
