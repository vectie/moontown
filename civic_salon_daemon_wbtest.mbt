///|
test "default civic salon schedules are explicit opt-in" {
  assert_eq(default_civic_salon_schedules().length(), 0)
}

///|
test "civic salon schedule uses real wall-clock due checks" {
  let schedule = daemon_civic_salon_schedule(next_due_ms=10UL)
  assert_true(!civic_salon_is_due(schedule, 9UL))
  assert_true(civic_salon_is_due(schedule, 10UL))
  let next = complete_civic_salon_schedule(
    schedule, 10UL, "future-energy-social-square-round-1", "done",
  )
  assert_eq(next.round_count, 1)
  assert_eq(next.last_run_ms, 10UL)
  assert_eq(next.next_due_ms, 1_800_010UL)
  assert_eq(next.latest_round_id, "future-energy-social-square-round-1")
}

///|
test "civic salon round record captures exchange effectiveness" {
  let scenario = daemon_civic_salon_scenario()
  let participants = scenario.participants
  let ideas = scenario.ideas
  let metrics = civic_salon_metrics(scenario, participants, ideas)
  let schedule = daemon_civic_salon_schedule()
  let record = civic_salon_round_record(
    schedule, "future-energy-social-square-round-1", 7, 100UL, 200UL, metrics, "review",
    "round complete",
  )
  assert_eq(record.tick, 7)
  assert_eq(record.participant_count, 2)
  assert_eq(record.idea_count, 1)
  assert_eq(record.research_question_count, 2)
  assert_eq(record.participant_idea_links, 2)
  assert_eq(record.idea_return_home_count, 2)
  assert_true(record.structural_effectiveness_score > 0)
}

///|
async test "due civic salon rounds persist schedule and run ledger" {
  let root = "/tmp/moontown-civic-salon-daemon"
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let book_catalog_path = "\{root}/books/catalog.json"
  let schedule = daemon_civic_salon_schedule()
  save_civic_salon_schedules(
    default_civic_salon_schedule_path(snapshot_path~),
    [schedule],
  )
  write_text_file(
    civic_salon_scenario_path(schedule.id, snapshot_path~),
    daemon_civic_salon_scenario().to_json().stringify(indent=2),
  )
  let summary = run_due_civic_salons(
    snapshot_path~,
    book_catalog_path~,
    tick=3,
    now_ms=1_000UL,
    reducer_mode=FixtureReducer,
  )
  assert_true(summary.has_prefix("Ran 1 civic salon"))
  let schedule_path = default_civic_salon_schedule_path(snapshot_path~)
  let ledger_path = default_civic_salon_run_ledger_path(
    "future-energy-social-square",
    snapshot_path~,
  )
  assert_true(@fs.exists(schedule_path))
  assert_true(@fs.exists(ledger_path))
  let schedules = load_or_create_civic_salon_schedules(path=schedule_path)
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
  ignore_checked_command("rm", ["-rf", root])
  let snapshot_path = "\{root}/town.json"
  let book_catalog_path = "\{root}/books/catalog.json"
  let schedule = {
    ..daemon_civic_salon_schedule(),
    last_run_ms: 1_000UL,
    next_due_ms: 999_999UL,
    round_count: 2,
    latest_round_id: "future-energy-social-square-round-2",
    latest_summary: "round two finished",
  }
  save_civic_salon_schedules(
    default_civic_salon_schedule_path(snapshot_path~),
    [schedule],
  )
  write_text_file(
    civic_salon_scenario_path(schedule.id, snapshot_path~),
    daemon_civic_salon_scenario().to_json().stringify(indent=2),
  )
  write_text_file(
    civic_salon_projection_path(schedule, snapshot_path),
    "{\"book_id\":\"wenyu-social-square\",\"status_chips\":[{\"label\":\"round 1\",\"tone\":\"info\"}]}",
  )
  write_text_file(
    "\{root}/books/wenyu-social-square/raw/bootstrap/civic-salon-ideas.json",
    Json::object({ "ideas": daemon_civic_salon_scenario().ideas.to_json() }).stringify(
      indent=2,
    ),
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
  assert_true(refreshed.contains("future-energy-social-square-round-2"))
  assert_true(refreshed.contains("round 2"))
  let schedules = load_or_create_civic_salon_schedules(
    path=default_civic_salon_schedule_path(snapshot_path~),
  )
  let persisted = schedules.get(0).unwrap()
  assert_eq(persisted.round_count, 2)
  assert_eq(persisted.next_due_ms, 999_999UL)
}

///|
fn daemon_civic_salon_schedule(
  next_due_ms? : UInt64 = 0UL,
) -> CivicSalonSchedule {
  CivicSalonSchedule::new(
    id="future-energy-social-square",
    title="Future Energy Social Square Salon",
    building_id="social-square",
    topic="future energy",
    interval_ms=1_800_000UL,
    next_due_ms~,
    participant_book_ids=["future-energy-storage", "future-energy-grid-ai"],
  )
}

///|
fn daemon_civic_salon_scenario() -> CivicSalonScenario {
  {
    id: "future-energy-social-square",
    title: "Future Energy Social Square Salon",
    building_id: "social-square",
    building_book_id: "wenyu-social-square",
    domain_label: "future energy",
    topic: "future energy cross-area exchange",
    cadence: "operator-triggered salon",
    skill_name: "future-energy-salon",
    skill_description: "Exchange future-energy perspectives and reduce them into testable research questions.",
    protocol_channel: "domain_perspective",
    reduction_kind: "cross_area_research_idea",
    output_channel: "research_question_backlog",
    review_gate: "research_program_quality",
    review_owner: "keeper",
    review_reason: "keeper reviews novelty, feasibility, evidence gaps, and owner books",
    backlog_path: "wiki/queries/future-energy-salon.md",
    synthesis_path: "wiki/civic/future-energy-salon.md",
    metrics_path: "wiki/metrics/future-energy-salon.md",
    review_path: "wiki/reviews/future-energy-salon.md",
    returned_ideas_path: "wiki/queries/salon-returned-ideas.md",
    participant_contract_path: "raw/bootstrap/FUTURE_ENERGY_SALON_CONTRACT.md",
    quality_rules: [
      "Every output must connect more than one participant book.", "Every idea must include a testable next experiment.",
    ],
    skill_rules: [
      "Bring one domain-specific bottleneck.", "Turn disagreements into questions rather than accepted facts.",
    ],
    participants: [
      {
        book_id: "future-energy-storage",
        title: "Storage Desk",
        focus_area: "long-duration storage",
        perspective: "Storage bottlenecks determine whether intermittent supply becomes useful capacity.",
        cadence: "operator-triggered salon",
        current_question: "Which storage constraints most change deployment economics?",
        contribution: "Storage contributes cost, duration, degradation, and siting constraints.",
        next_artifact: "wiki/queries/storage-constraints.md",
      },
      {
        book_id: "future-energy-grid-ai",
        title: "Grid AI Desk",
        focus_area: "grid forecasting and autonomous control",
        perspective: "Grid AI matters only when it respects physical constraints and operator trust.",
        cadence: "operator-triggered salon",
        current_question: "Which control decisions are safe enough for autonomy?",
        contribution: "Grid AI contributes forecasting, dispatch policy, and operator-review loops.",
        next_artifact: "wiki/queries/grid-ai-control.md",
      },
    ],
    ideas: [
      {
        id: "storage-grid-control-contract",
        title: "Storage-Grid Control Contract",
        summary: "Define the interface between long-duration storage constraints and AI grid-control decisions.",
        participating_books: ["future-energy-storage", "future-energy-grid-ai"],
        research_questions: [
          "Which storage constraints must a grid-control model see before dispatch?",
          "What operator review gate is needed before autonomous storage dispatch?",
        ],
        why_it_matters: "It turns a cross-domain dependency into a concrete protocol contract.",
        next_experiment: "Prototype a dispatch schema that carries duration, degradation, confidence, and review status.",
      },
    ],
  }
}
