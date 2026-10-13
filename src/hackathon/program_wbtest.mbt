///|
fn program_test_brief() -> Challenge {
  {
    id: "river-ai",
    name: "River AI Sprint",
    topic: "River signals",
    scope: "Open data",
    possibility_wiki: "Map river changes",
    first_person_solution: "I compare sensors",
    deadline_ms: 5000UL,
    benchmark_version: 99,
    benchmark_materials: ["https://example.org/data"],
    evaluation_materials: ["https://example.org/rules"],
    rubric: [{ id: "quality", label: "Quality", max_points: 100, }],
    published: true,
  }
}

///|
fn program_test_program() -> CompetitionProgram {
  {
    challenge_id: "river-ai",
    state: "draft",
    organizer: "River Mayor",
    timezone: "Asia/Shanghai",
    registration_open_ms: 100UL,
    registration_close_ms: 3000UL,
    submission_open_ms: 200UL,
    review_close_ms: 6000UL,
    max_team_size: 4,
    daily_submission_limit: 3,
    contact_url: "mailto:mayor@example.org",
    tracks: [
      {
        id: "mapping",
        name: "Mapping",
        description: "Explain a map",
        scoring_mode: "rubric",
        runner_key: "",
        required_materials: ["source", "report"],
        metrics: [],
        gates: [],
      },
    ],
    prizes: [{ track_id: "mapping", place: "1", description: "Town medal", }],
    partners: [{ name: "River lab", url: "https://example.org/lab", }],
    faq: [{ category: "Teams", question: "How many?", answer: "Four", }],
    announcements: [],
    evaluator_ids: ["reviewer"],
  }
}

///|
fn program_test_action(
  state : HackathonState,
  action : String,
  payload : Json,
  now_ms : UInt64,
) -> HackathonState raise {
  guard apply_program_action(state, action, payload, now_ms) is Some(next) else {
    fail("expected program action")
  }
  next
}

///|
test "competition draft preview publication and final freeze" {
  let state = program_test_action(
    empty_hackathon_state(),
    "save-program",
    {
      "program": program_test_program().to_json(),
      "brief": program_test_brief().to_json(),
    },
    10UL,
  )
  assert_true(!state.challenges[0].published)
  assert_eq(state.challenges[0].benchmark_version, 1)
  assert_eq(program_readiness(state, "river-ai").length(), 0)
  let state = program_test_action(
    state,
    "publish-program",
    { "challenge_id": "river-ai" },
    20UL,
  )
  assert_true(state.challenges[0].published)
  assert_eq(state.programs[0].state, "open")
  let state = program_test_action(
    state,
    "announce",
    {
      "challenge_id": "river-ai",
      "id": "welcome",
      "title": "Welcome",
      "body": "Teams may register",
      "published_ms": 999,
    },
    50UL,
  )
  assert_eq(state.programs[0].announcements[0].published_ms, 50UL)
  let early = try {
    let _ = program_test_action(
      state,
      "transition-program",
      { "challenge_id": "river-ai", "state": "evaluating", "reason": "Review" },
      5000UL,
    )
    false
  } catch {
    _ => true
  }
  assert_true(early)
  let state = program_test_action(
    state,
    "transition-program",
    {
      "challenge_id": "river-ai",
      "state": "evaluating",
      "reason": "Review opens",
    },
    5001UL,
  )
  let state = program_test_action(
    state,
    "transition-program",
    {
      "challenge_id": "river-ai",
      "state": "final",
      "reason": "All reviews complete",
    },
    6000UL,
  )
  assert_eq(state.programs[0].state, "final")
  assert_true(
    state.programs[0].announcements.last().unwrap().body.contains(
      "All reviews complete",
    ),
  )
  assert_eq(
    state.programs[0].announcements.last().unwrap().published_ms,
    6000UL,
  )
  assert_true(state.program_history.length() >= 4)
  let frozen = try {
    let _ = program_test_action(
      state,
      "save-program",
      {
        "program": program_test_program().to_json(),
        "brief": program_test_brief().to_json(),
      },
      6001UL,
    )
    false
  } catch {
    _ => true
  }
  assert_true(frozen)
  let frozen = try {
    let _ = program_test_action(
      state,
      "transition-program",
      { "challenge_id": "river-ai", "state": "open", "reason": "Reopen" },
      6001UL,
    )
    false
  } catch {
    _ => true
  }
  assert_true(frozen)
  let frozen = try {
    let _ = program_test_action(
      state,
      "revise-benchmark",
      {
        "challenge_id": "river-ai",
        "benchmark_materials": ["https://example.org/new"],
        "evaluation_materials": ["https://example.org/rules"],
        "rubric": program_test_brief().rubric.to_json(),
      },
      6001UL,
    )
    false
  } catch {
    _ => true
  }
  assert_true(frozen)
  let announced = program_test_action(
    state,
    "announce",
    {
      "challenge_id": "river-ai",
      "id": "champions",
      "title": "Champion stories",
      "body": "Celebrating the results",
    },
    6001UL,
  )
  assert_eq(announced.programs[0].state, "final")
  assert_eq(announced.challenges.to_json(), state.challenges.to_json())
  assert_eq(
    announced.programs[0].announcements.last().unwrap().published_ms,
    6001UL,
  )
}

///|
test "preview retains incomplete drafts and rejects invalid metric contracts" {
  let brief = { ..program_test_brief(), scope: "", }
  let program = {
    ..program_test_program(),
    tracks: [],
    prizes: [],
    evaluator_ids: [],
  }
  let state = program_test_action(
    empty_hackathon_state(),
    "save-program",
    { "program": program.to_json(), "brief": brief.to_json() },
    10UL,
  )
  assert_eq(program_readiness(state, "river-ai").length(), 3)
  let rejected = try {
    let _ = program_test_action(
      state,
      "publish-program",
      { "challenge_id": "river-ai" },
      20UL,
    )
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
  let program = {
    ..program_test_program(),
    tracks: [
      {
        ..program_test_program().tracks[0],
        scoring_mode: "metric",
        runner_key: "runner",
        metrics: [
          {
            id: "latency",
            label: "Latency",
            unit: "ms",
            direction: "min",
            baseline: 0.0,
            weight: 1.0,
          },
        ],
      },
    ],
  }
  let rejected = try {
    let _ = program_test_action(
      state,
      "save-program",
      { "program": program.to_json(), "brief": program_test_brief().to_json() },
      20UL,
    )
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
}

///|
test "published amendments preserve lifecycle and archive benchmark versions" {
  let state = program_test_action(
    empty_hackathon_state(),
    "save-program",
    {
      "program": program_test_program().to_json(),
      "brief": program_test_brief().to_json(),
    },
    10UL,
  )
  let state = program_test_action(
    state,
    "publish-program",
    { "challenge_id": "river-ai" },
    20UL,
  )
  let state = program_test_action(
    state,
    "save-program",
    {
      "program": program_test_program().to_json(),
      "brief": {
        ..program_test_brief(),
        benchmark_materials: ["https://example.org/data-v2"],
      }.to_json(),
    },
    30UL,
  )
  assert_eq(state.programs[0].state, "open")
  assert_true(state.challenges[0].published)
  assert_eq(state.challenges[0].benchmark_version, 2)
  assert_eq(state.challenge_history[0].benchmark_version, 1)
  assert_true(
    state.programs[0].announcements.last().unwrap().body.contains(
      "benchmark version: 2",
    ),
  )
  assert_eq(state.programs[0].announcements.last().unwrap().published_ms, 30UL)
  let revised = program_test_action(
    state,
    "revise-benchmark",
    {
      "challenge_id": "river-ai",
      "benchmark_materials": state.challenges[0].benchmark_materials.to_json(),
      "evaluation_materials": state.challenges[0].evaluation_materials.to_json(),
      "rubric": state.challenges[0].rubric.to_json(),
    },
    40UL,
  )
  assert_eq(revised.challenges[0].benchmark_version, 3)
  assert_eq(
    revised.programs[0].announcements.last().unwrap().published_ms,
    40UL,
  )
}

///|
test "registered team contracts and active benchmark receipts survive amendments" {
  let state = program_test_action(
    empty_hackathon_state(),
    "save-program",
    {
      "program": program_test_program().to_json(),
      "brief": program_test_brief().to_json(),
    },
    10UL,
  )
  let state = program_test_action(
    state,
    "publish-program",
    { "challenge_id": "river-ai" },
    20UL,
  )
  let state = { ..state, teams: [sample_team("blue")], }
  let quota_change = try {
    let _ = program_test_action(
      state,
      "save-program",
      {
        "program": { ..program_test_program(), daily_submission_limit: 9, }.to_json(),
        "brief": program_test_brief().to_json(),
      },
      30UL,
    )
    false
  } catch {
    _ => true
  }
  assert_true(quota_change)
  let earlier_close = try {
    let _ = program_test_action(
      state,
      "save-program",
      {
        "program": program_test_program().to_json(),
        "brief": { ..program_test_brief(), deadline_ms: 4000UL, }.to_json(),
      },
      30UL,
    )
    false
  } catch {
    _ => true
  }
  assert_true(earlier_close)
  let state = {
    ..state,
    submissions: [sample_submission("blue-v1", "blue", 100UL)],
    benchmark_runs: [
      {
        id: "run-one",
        submission_id: "blue-v1",
        reviewer_id: "reviewer",
        worker_run_id: "",
        state: "running",
        reason: "",
        input_hash: "",
        output_hash: "",
        benchmark_version: 1,
        metrics: [],
        evidence: [],
        queued_ms: 100UL,
        finished_ms: 0UL,
      },
    ],
  }
  let changed_benchmark = try {
    let _ = program_test_action(
      state,
      "save-program",
      {
        "program": program_test_program().to_json(),
        "brief": {
          ..program_test_brief(),
          benchmark_materials: ["https://example.org/v2"],
        }.to_json(),
      },
      30UL,
    )
    false
  } catch {
    _ => true
  }
  assert_true(changed_benchmark)
  let changed_benchmark = try {
    let _ = program_test_action(
      state,
      "revise-benchmark",
      {
        "challenge_id": "river-ai",
        "benchmark_materials": ["https://example.org/v2"],
        "evaluation_materials": ["https://example.org/rules"],
        "rubric": program_test_brief().rubric.to_json(),
      },
      30UL,
    )
    false
  } catch {
    _ => true
  }
  assert_true(changed_benchmark)
  let changed_roster = try {
    let _ = program_test_action(
      state,
      "save-program",
      {
        "program": { ..program_test_program(), evaluator_ids: ["replacement"], }.to_json(),
        "brief": program_test_brief().to_json(),
      },
      30UL,
    )
    false
  } catch {
    _ => true
  }
  assert_true(changed_roster)
  let amended = program_test_action(
    state,
    "save-program",
    {
      "program": { ..program_test_program(), registration_close_ms: 3500UL, }.to_json(),
      "brief": program_test_brief().to_json(),
    },
    30UL,
  )
  assert_eq(amended.programs[0].registration_close_ms, 3500UL)
  assert_eq(amended.challenges[0].benchmark_version, 1)
}

///|
test "program calendar and legacy conversion cannot invalidate an existing challenge" {
  let invalid_time = try {
    let _ = program_test_action(
      empty_hackathon_state(),
      "save-program",
      {
        "program": { ..program_test_program(), submission_open_ms: 50UL, }.to_json(),
        "brief": program_test_brief().to_json(),
      },
      10UL,
    )
    false
  } catch {
    _ => true
  }
  assert_true(invalid_time)
  let invalid_timezone = try {
    let _ = program_test_action(
      empty_hackathon_state(),
      "save-program",
      {
        "program": {
          ..program_test_program(),
          timezone: "Shanghai Standard Time",
        }.to_json(),
        "brief": program_test_brief().to_json(),
      },
      10UL,
    )
    false
  } catch {
    _ => true
  }
  assert_true(invalid_timezone)
  let legacy = publish_challenge(empty_hackathon_state(), program_test_brief())
  let converted = try {
    let _ = program_test_action(
      legacy,
      "save-program",
      {
        "program": program_test_program().to_json(),
        "brief": program_test_brief().to_json(),
      },
      10UL,
    )
    false
  } catch {
    _ => true
  }
  assert_true(converted)
  let mismatch = try {
    let _ = program_test_action(
      empty_hackathon_state(),
      "save-program",
      {
        "program": program_test_program().to_json(),
        "brief": { ..program_test_brief(), id: "other-event", }.to_json(),
      },
      10UL,
    )
    false
  } catch {
    _ => true
  }
  assert_true(mismatch)
}

///|
test "legacy ledger decoding defaults competition arrays and retains receipts" {
  let json = empty_hackathon_state().to_json()
  guard json is Object(fields) else { fail("state object expected") }
  for
    key in [
      "programs", "team_profiles", "invitations", "submission_packages", "benchmark_runs",
      "appeals", "program_history",
    ] {
    fields.remove(key)
  }
  fields["revision"] = (42).to_json()
  fields["challenges"] = [program_test_brief()].to_json()
  let state = decode_hackathon_state(json)
  assert_eq(state.revision, 42)
  assert_eq(state.challenges[0].name, "River AI Sprint")
  assert_eq(state.programs.length(), 0)
  assert_eq(state.benchmark_runs.length(), 0)
}
