///|
fn evaluation_fixture() -> HackathonState {
  let brief = { ..program_test_brief(), published: true, benchmark_version: 1, }
  let track : CompetitionTrack = {
    id: "speed",
    name: "Speed",
    description: "Measured",
    scoring_mode: "metric",
    runner_key: "trusted",
    required_materials: ["source"],
    metrics: [
      {
        id: "latency",
        label: "Latency",
        unit: "ms",
        direction: "min",
        baseline: 100.0,
        weight: 3.0,
      },
      {
        id: "quality",
        label: "Quality",
        unit: "%",
        direction: "max",
        baseline: 80.0,
        weight: 1.0,
      },
    ],
    gates: [
      {
        id: "quality-gate",
        label: "Quality",
        metric_id: "quality",
        comparison: "gte",
        threshold: 75.0,
      },
    ],
  }
  let program = { ..program_test_program(), state: "open", tracks: [track], }
  let team : Team = {
    id: "alpha",
    challenge_id: brief.id,
    name: "Alpha",
    members: ["captain"],
  }
  let submission : Submission = {
    id: "alpha-v1",
    challenge_id: brief.id,
    team_id: team.id,
    version: 1,
    artifact_url: "https://example.org/artifact",
    first_person_solution: "I benchmark it",
    submitted_ms: 1000UL,
  }
  {
    ..empty_hackathon_state(),
    challenges: [brief],
    programs: [program],
    teams: [team],
    submissions: [submission],
    submission_packages: [
      {
        submission_id: submission.id,
        track_id: track.id,
        materials: [
          {
            kind: "source",
            url: submission.artifact_url,
            sha256: "a".repeat(64),
          },
        ],
        benchmark_version: 1,
      },
    ],
  }
}

///|
fn evaluation_action(
  state : HackathonState,
  action : String,
  payload : Json,
  time : UInt64,
) -> HackathonState raise {
  guard apply_evaluation_action(state, action, payload, time) is Some(next) else {
    fail("evaluation action expected")
  }
  next
}

///|
fn evaluation_queue(state : HackathonState) -> HackathonState raise {
  evaluation_action(
    state,
    "queue-benchmark",
    { "id": "run-one", "submission_id": "alpha-v1", "reviewer_id": "reviewer" },
    1100UL,
  )
}

///|
fn evaluation_measure(
  state : HackathonState,
  quality : Double,
) -> HackathonState raise {
  let state = evaluation_action(
    state,
    "start-benchmark",
    { "run_id": "run-one" },
    1200UL,
  )
  let result : BenchmarkResult = {
    run_id: "run-one",
    worker_run_id: "worker-one",
    metrics: [
      { metric_id: "latency", value: 50.0, },
      { metric_id: "quality", value: quality, },
    ],
    evidence: ["https://example.org/receipt"],
    input_hash: "a".repeat(64),
    output_hash: "b".repeat(64),
    success: true,
    reason: "",
  }
  evaluation_action(state, "record-benchmark-result", result.to_json(), 1300UL)
}

///|
test "benchmark approvals, weighted baseline ratios, qualification and final readiness" {
  let state = evaluation_queue(evaluation_fixture())
  assert_true(!competition_finalization_ready(state, "river-ai"))
  let state = evaluation_measure(state, 80.0)
  assert_eq(competition_leaderboard(state, "river-ai", "speed").length(), 0)
  let state = evaluation_action(
    state,
    "approve-benchmark",
    { "run_id": "run-one", "reviewer_id": "reviewer" },
    1400UL,
  )
  let board = competition_leaderboard(state, "river-ai", "speed")
  assert_eq(board[0].score, 175.0)
  assert_eq(board[0].status, "provisional")
  assert_true(competition_finalization_ready(state, "river-ai"))
  let state = evaluation_action(
    state,
    "open-appeal",
    {
      "id": "appeal-one",
      "submission_id": "alpha-v1",
      "member_id": "captain",
      "reason": "Please recheck quality",
    },
    1500UL,
  )
  assert_true(!competition_finalization_ready(state, "river-ai"))
  let state = evaluation_action(
    state,
    "resolve-appeal",
    { "appeal_id": "appeal-one", "resolution": "Reviewed retained evidence" },
    1600UL,
  )
  assert_true(competition_finalization_ready(state, "river-ai"))
  assert_eq(state.appeals[0].resolved_ms, 1600UL)
  let state = { ..state, programs: [{ ..state.programs[0], state: "final", }], }
  assert_eq(
    competition_leaderboard(state, "river-ai", "speed")[0].status,
    "final",
  )
  let frozen = try {
    let _ = evaluation_action(
      state,
      "queue-benchmark",
      {
        "id": "run-two",
        "submission_id": "alpha-v1",
        "reviewer_id": "reviewer",
      },
      1700UL,
    )
    false
  } catch {
    _ => true
  }
  assert_true(frozen)
  let state = evaluation_measure(evaluation_queue(evaluation_fixture()), 70.0)
  let state = evaluation_action(
    state,
    "approve-benchmark",
    { "run_id": "run-one", "reviewer_id": "reviewer" },
    1400UL,
  )
  assert_eq(competition_leaderboard(state, "river-ai", "speed").length(), 0)
  assert_true(
    state.benchmark_runs[0].reason.contains(
      "Unranked: qualification gates failed",
    ),
  )
  assert_true(
    state.benchmark_runs[0].reason.contains(
      "quality measured 70 %; requires at least 75 %",
    ),
  )
  assert_true(competition_finalization_ready(state, "river-ai"))
}

///|
test "approved unqualified receipts explain every failing gate without entering the board" {
  let fixture = evaluation_fixture()
  let track = fixture.programs[0].tracks[0]
  let gates = track.gates.copy()
  gates.push({
    id: "latency-gate",
    label: "Latency ceiling",
    metric_id: "latency",
    comparison: "lte",
    threshold: 40.0,
  })
  let state = {
    ..fixture,
    programs: [{ ..fixture.programs[0], tracks: [{ ..track, gates, }], }],
  }
  let state = evaluation_measure(evaluation_queue(state), 70.0)
  let state = evaluation_action(
    state,
    "approve-benchmark",
    { "run_id": "run-one", "reviewer_id": "reviewer" },
    1400UL,
  )
  assert_eq(state.benchmark_runs[0].state, "approved")
  assert_true(
    state.benchmark_runs[0].reason.contains(
      "quality measured 70 %; requires at least 75 %",
    ),
  )
  assert_true(
    state.benchmark_runs[0].reason.contains(
      "latency measured 50 ms; requires at most 40 ms",
    ),
  )
  assert_eq(competition_leaderboard(state, "river-ai", "speed").length(), 0)
  assert_true(competition_finalization_ready(state, "river-ai"))
}

///|
test "reviewer roster conflicts, incomplete metrics, stale versions and failed retries preserve receipts" {
  let base = evaluation_fixture()
  let unauthorized = try {
    let _ = evaluation_action(
      base,
      "queue-benchmark",
      {
        "id": "run-one",
        "submission_id": "alpha-v1",
        "reviewer_id": "outsider",
      },
      1100UL,
    )
    false
  } catch {
    _ => true
  }
  assert_true(unauthorized)
  let incomplete = try {
    validate_measured_metrics(base.programs[0].tracks[0], [
      { metric_id: "latency", value: 50.0, },
    ])
    false
  } catch {
    _ => true
  }
  assert_true(incomplete)
  let conflict = {
    ..base,
    programs: [{ ..base.programs[0], evaluator_ids: ["captain"], }],
  }
  let rejected = try {
    let _ = evaluation_action(
      conflict,
      "queue-benchmark",
      { "id": "run-one", "submission_id": "alpha-v1", "reviewer_id": "captain" },
      1100UL,
    )
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
  let stale = {
    ..base,
    challenges: [{ ..base.challenges[0], benchmark_version: 2, }],
  }
  let rerun = evaluation_queue(stale)
  assert_eq(rerun.benchmark_runs[0].benchmark_version, 2)
  assert_eq(rerun.submission_packages[0].benchmark_version, 1)
  let state = evaluation_action(
    evaluation_queue(base),
    "start-benchmark",
    { "run_id": "run-one" },
    1200UL,
  )
  let result = failed_benchmark_result(
    state, "run-one", "GPU worker unavailable",
  )
  let state = evaluation_action(
    state,
    "record-benchmark-result",
    result.to_json(),
    1300UL,
  )
  assert_eq(state.benchmark_runs[0].state, "failed")
  assert_eq(competition_leaderboard(state, "river-ai", "speed").length(), 0)
  let state = evaluation_action(
    state,
    "retry-benchmark",
    { "run_id": "run-one" },
    1400UL,
  )
  assert_eq(state.benchmark_runs.length(), 2)
  assert_eq(state.benchmark_runs[0].reason, "GPU worker unavailable")
  assert_eq(state.benchmark_runs[1].state, "queued")
  let state = evaluation_action(
    state,
    "recover-interrupted-benchmark",
    {
      "run_id": state.benchmark_runs[1].id,
      "reason": "Operator recovered abandoned queue",
    },
    1500UL,
  )
  assert_eq(state.benchmark_runs[1].state, "failed")
  assert_true(!state.benchmark_runs[1].evidence.is_empty())
}

///|
async test "trusted process worker creates hashed receipts, rejects missing registry and bounds duration" {
  let root = "/tmp/contest-runner-test-" + @env.now().to_string()
  let state = evaluation_queue(evaluation_fixture())
  let registry = root + "/runners.json"
  @support.ensure_parent_directory(registry)
  let output : Json = {
    "metrics": [
      { "metric_id": "latency", "value": 50.0 },
      { "metric_id": "quality", "value": 80.0 },
    ],
    "evidence": ["fixture-process-executed"],
  }
  let runner : CompetitionRunner = {
    key: "trusted",
    program: "/bin/echo",
    args: [output.stringify()],
    cwd: "/tmp",
    timeout_ms: 1000,
  }
  @fs.write_file(
    registry,
    [runner].to_json().stringify(),
    create_mode=CreateNew,
  )
  let result = execute_configured_benchmark(
    state,
    "run-one",
    registry_path=registry,
    receipt_root=root + "/success",
  )
  assert_true(result.success)
  assert_true(benchmark_hash_valid(result.input_hash))
  assert_true(benchmark_hash_valid(result.output_hash))
  assert_true(@fs.exists(root + "/success/run-one/receipt.json"))
  let result = execute_configured_benchmark(
    state,
    "run-one",
    registry_path=root + "/missing",
    receipt_root=root + "/missing-result",
  )
  assert_true(!result.success)
  let sleepy = { ..runner, program: "/bin/sleep", args: ["5"], timeout_ms: 10, }
  @fs.write_file(
    registry,
    [sleepy].to_json().stringify(),
    create_mode=CreateOrTruncate,
  )
  let result = execute_configured_benchmark(
    state,
    "run-one",
    registry_path=registry,
    receipt_root=root + "/timeout",
  )
  assert_true(!result.success)
  assert_true(result.reason.contains("TimeoutError"))
}

///|
test "benchmark amendment closes stale worker results and accepts zero maximizing metrics" {
  let state = evaluation_action(
    evaluation_queue(evaluation_fixture()),
    "start-benchmark",
    { "run_id": "run-one" },
    1200UL,
  )
  let state = {
    ..state,
    challenges: [{ ..state.challenges[0], benchmark_version: 2, }],
  }
  let result : BenchmarkResult = {
    run_id: "run-one",
    worker_run_id: "worker",
    metrics: [
      { metric_id: "latency", value: 50.0, },
      { metric_id: "quality", value: 0.0, },
    ],
    evidence: ["receipt"],
    input_hash: "a".repeat(64),
    output_hash: "b".repeat(64),
    success: true,
    reason: "",
  }
  let state = evaluation_action(
    state,
    "record-benchmark-result",
    result.to_json(),
    1300UL,
  )
  assert_eq(state.benchmark_runs[0].state, "failed")
  assert_true(state.benchmark_runs[0].reason.contains("version changed"))
  let state = evaluation_action(
    state,
    "retry-benchmark",
    { "run_id": "run-one" },
    1400UL,
  )
  assert_eq(state.benchmark_runs[1].benchmark_version, 2)
  validate_measured_metrics(state.programs[0].tracks[0], result.metrics)
  let rejected = try {
    validate_measured_metrics(state.programs[0].tracks[0], [
      { metric_id: "latency", value: 0.0, },
      { metric_id: "quality", value: 80.0, },
    ])
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
}

///|
async test "background worker claims queue and records review receipt without human approval" {
  let now = @env.now()
  let root = "/tmp/contest-queue-worker-" + now.to_string()
  let path = root + "/hackathons.json"
  let registry = root + "/runners.json"
  @support.ensure_parent_directory(path)
  let fixture = evaluation_queue(evaluation_fixture())
  let state = {
    ..fixture,
    programs: [{ ..fixture.programs[0], review_close_ms: now + 60000UL, }],
    challenges: [{ ..fixture.challenges[0], deadline_ms: now + 30000UL, }],
  }
  @fs.write_file(path, state.to_json().stringify(), create_mode=CreateNew)
  let output : Json = {
    "metrics": [
      { "metric_id": "latency", "value": 50.0 },
      { "metric_id": "quality", "value": 80.0 },
    ],
    "evidence": ["trusted-queue-worker-fixture"],
  }
  let runner : CompetitionRunner = {
    key: "trusted",
    program: "/bin/echo",
    args: [output.stringify()],
    cwd: "/tmp",
    timeout_ms: 1000,
  }
  @fs.write_file(
    registry,
    [runner].to_json().stringify(),
    create_mode=CreateNew,
  )
  assert_true(
    process_next_competition_benchmark(
      path~,
      registry_path=registry,
      receipt_root=root + "/receipts",
    ),
  )
  let state = load_hackathons(path~)
  assert_eq(state.benchmark_runs[0].state, "review")
  assert_eq(competition_leaderboard(state, "river-ai", "speed").length(), 0)
  assert_true(
    !process_next_competition_benchmark(
      path~,
      registry_path=registry,
      receipt_root=root + "/receipts",
    ),
  )
}
