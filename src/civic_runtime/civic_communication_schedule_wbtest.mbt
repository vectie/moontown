///|
test "default civic communication-pattern schedules are explicit opt-in" {
  assert_eq(default_civic_communication_schedules().length(), 0)
}

///|
test "civic communication-pattern schedule uses real wall-clock due checks" {
  let schedule = daemon_civic_salon_schedule(next_due_ms=10UL)
  assert_true(!civic_communication_is_due(schedule, 9UL))
  assert_true(civic_communication_is_due(schedule, 10UL))
  let next = complete_civic_communication_schedule(
    schedule, 10UL, "future-energy-social-square-round-1", "done",
  )
  assert_eq(next.round_count, 1)
  assert_eq(next.last_run_ms, 10UL)
  assert_eq(next.next_due_ms, 1_800_010UL)
  assert_eq(next.latest_round_id, "future-energy-social-square-round-1")
}

///|
async test "scenario interval config controls generated schedule cadence" {
  let root = "/tmp/moontown-civic-salon-interval"
  @support.ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let scenario = {
    ..daemon_civic_salon_scenario(),
    interval_ms: Some(900_000UL),
  }
  let schedule = upsert_civic_communication_schedule_for_scenario(
    scenario,
    path=default_civic_communication_schedule_path(snapshot_path~),
    now_ms=123UL,
  )
  assert_eq(schedule.interval_ms, 900_000UL)
  assert_eq(schedule.next_due_ms, 123UL)
}

///|
test "civic salon round record captures exchange effectiveness" {
  let scenario = daemon_civic_salon_scenario()
  let participants = scenario.participants
  let ideas = scenario.ideas
  let metrics = civic_communication_metrics(scenario, participants, ideas)
  let schedule = daemon_civic_salon_schedule()
  let record = civic_communication_round_record(
    schedule, "future-energy-social-square-round-1", 7, 100UL, 200UL, metrics, "review",
    "round complete",
  )
  assert_eq(record.tick, 7)
  assert_eq(record.scenario_id, schedule.id)
  assert_eq(record.participant_count, 2)
  assert_eq(record.idea_count, 1)
  assert_eq(record.research_question_count, 2)
  assert_eq(record.participant_idea_links, 2)
  assert_eq(record.idea_return_home_count, 2)
  assert_true(record.structural_effectiveness_score > 0)
}

///|
test "civic salon due run summary keeps idle run and refresh states distinct" {
  assert_eq(
    civic_communication_due_run_summary([], [], 42UL),
    "No civic communication-pattern schedules due at now_ms=42.",
  )
  assert_true(
    civic_communication_due_run_summary(["round-a"], [], 42UL).has_prefix(
      "Ran 1 civic communication-pattern schedule(s): round-a",
    ),
  )
  assert_true(
    civic_communication_due_run_summary([], ["refresh-a"], 42UL).has_prefix(
      "Refreshed 1 civic communication-pattern projection(s): refresh-a",
    ),
  )
  assert_true(
    civic_communication_due_run_summary(["round-a"], ["refresh-a"], 42UL).contains(
      "refreshed 1 stale projection(s): refresh-a",
    ),
  )
}

///|
async test "persist civic salon schedule replaces only matching schedule" {
  let root = "/tmp/moontown-civic-salon-persist-schedule"
  @support.ignore_checked_command("rm", ["-rf", root])
  let path = "\{root}/schedules.json"
  let first = daemon_civic_salon_schedule()
  let second = {
    ..daemon_civic_salon_schedule(),
    id: "future-energy-policy-hall",
    title: "Future Energy Policy Hall",
  }
  save_civic_communication_schedules(path, [first, second])
  persist_civic_communication_schedule(path, first.id, {
    ..first,
    latest_summary: "claimed",
    next_due_ms: 300UL,
  })
  let schedules = load_or_create_civic_communication_schedules(path~)
  assert_eq(schedules.length(), 2)
  assert_eq(schedules[0].id, first.id)
  assert_eq(schedules[0].latest_summary, "claimed")
  assert_eq(schedules[0].next_due_ms, 300UL)
  assert_eq(schedules[1].id, second.id)
  assert_eq(schedules[1].latest_summary, "")
}
