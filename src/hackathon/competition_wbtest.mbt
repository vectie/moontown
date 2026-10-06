///|
fn sample_challenge() -> Challenge {
  {
    id: "river-ai",
    name: "River AI Sprint",
    topic: "Find useful river signals",
    scope: "Open data and public explanation",
    possibility_wiki: "A sensor map might reveal seasonal changes.",
    first_person_solution: "I would compare sensor readings and publish a map.",
    deadline_ms: 5000UL,
    benchmark_version: 1,
    benchmark_materials: ["https://example.org/data.csv"],
    evaluation_materials: ["https://example.org/rules.md"],
    rubric: [
      { id: "quality", label: "Quality", max_points: 60, },
      { id: "clarity", label: "Clarity", max_points: 40, },
    ],
    published: false,
  }
}

///|
fn sample_team(id : String) -> Team {
  {
    id,
    challenge_id: "river-ai",
    name: "Team \{id}",
    members: ["resident-\{id}"],
  }
}

///|
fn sample_submission(
  id : String,
  team_id : String,
  time : UInt64,
) -> Submission {
  {
    id,
    challenge_id: "river-ai",
    team_id,
    version: 0,
    artifact_url: "https://example.org/\{id}",
    first_person_solution: "I mapped the measurements.",
    submitted_ms: time,
  }
}

///|
fn sample_evaluation(
  id : String,
  quality : Int,
  clarity : Int,
  time : UInt64,
) -> Evaluation {
  {
    submission_id: id,
    benchmark_version: 1,
    reviewer: "reviewer-1",
    scores: [
      { criterion_id: "quality", points: quality, evidence: "Measured output", },
      {
        criterion_id: "clarity",
        points: clarity,
        evidence: "Reviewed explanation",
      },
    ],
    total: 999,
    evaluated_ms: time,
  }
}

///|
test "mayor publishes brief and teams get versioned submissions" {
  let state = publish_challenge(empty_hackathon_state(), sample_challenge())
  assert_true(state.challenges[0].published)
  let state = register_team(state, sample_team("blue"))
  let state = join_team(state, "blue", "resident-2")
  assert_eq(state.teams[0].members.length(), 2)
  let state = submit_solution(state, sample_submission("blue-1", "blue", 100UL))
  let state = submit_solution(state, sample_submission("blue-2", "blue", 200UL))
  assert_eq(state.submissions[0].version, 1)
  assert_eq(state.submissions[1].version, 2)
  assert_eq(state.revision, 5)
}

///|
test "evaluation recomputes score and leaderboard uses current benchmark" {
  let state = publish_challenge(empty_hackathon_state(), sample_challenge())
  let state = register_team(state, sample_team("blue"))
  let state = register_team(state, sample_team("red"))
  let state = submit_solution(state, sample_submission("blue-1", "blue", 100UL))
  let state = submit_solution(state, sample_submission("red-1", "red", 100UL))
  let state = record_evaluation(
    state,
    sample_evaluation("blue-1", 40, 30, 300UL),
  )
  let state = record_evaluation(
    state,
    sample_evaluation("red-1", 50, 35, 400UL),
  )
  let board = leaderboard(state, "river-ai")
  assert_eq(board.length(), 2)
  assert_eq(board[0].team_id, "red")
  assert_eq(board[0].total, 85)
  assert_eq(board[1].rank, 2)
  let revised = revise_benchmark(
    state,
    "river-ai",
    ["https://example.org/data-v2.csv"],
    ["https://example.org/rules-v2.md"],
    sample_challenge().rubric,
  )
  assert_eq(revised.challenges[0].benchmark_version, 2)
  assert_eq(revised.challenge_history[0].benchmark_version, 1)
  assert_eq(leaderboard(revised, "river-ai").length(), 0)
}

///|
test "corrected evaluation supersedes earlier score for a submission" {
  let state = publish_challenge(empty_hackathon_state(), sample_challenge())
  let state = register_team(state, sample_team("blue"))
  let state = submit_solution(state, sample_submission("blue-1", "blue", 100UL))
  let state = record_evaluation(
    state,
    sample_evaluation("blue-1", 60, 40, 200UL),
  )
  assert_eq(leaderboard(state, "river-ai")[0].total, 100)
  let state = record_evaluation(
    state,
    sample_evaluation("blue-1", 40, 30, 300UL),
  )
  assert_eq(leaderboard(state, "river-ai")[0].total, 70)
  let conflict = record_evaluation(state, {
    ..sample_evaluation("blue-1", 40, 30, 400UL),
    reviewer: "resident-blue",
  }) catch {
    _ => empty_hackathon_state()
  }
  assert_eq(conflict.revision, 0)
}

///|
test "deadline and unsupported scoring are rejected" {
  let state = publish_challenge(empty_hackathon_state(), sample_challenge())
  let state = register_team(state, sample_team("blue"))
  let late = submit_solution(state, sample_submission("late", "blue", 5001UL)) catch {
    _ => empty_hackathon_state()
  }
  assert_eq(late.revision, 0)
  let state = submit_solution(state, sample_submission("blue-1", "blue", 100UL))
  let invalid = record_evaluation(
    state,
    sample_evaluation("blue-1", 61, 40, 200UL),
  ) catch {
    _ => empty_hackathon_state()
  }
  assert_eq(invalid.revision, 0)
}

///|
async test "action store persists revisions and uses server submission time" {
  let path = "/tmp/moontown-hackathon-\{@env.now()}-test.json"
  let state = apply_hackathon_action(
    "publish",
    sample_challenge().to_json(),
    10UL,
    path~,
  )
  assert_eq(state.revision, 1)
  let state = apply_hackathon_action(
    "register-team",
    sample_team("blue").to_json(),
    20UL,
    path~,
  )
  assert_eq(state.revision, 2)
  let payload = sample_submission("blue-1", "blue", 1UL).to_json()
  if payload is Object(fields) {
    fields.remove("version")
    fields.remove("submitted_ms")
  }
  let state = apply_hackathon_action("submit", payload, 300UL, path~)
  assert_eq(state.submissions[0].submitted_ms, 300UL)
  assert_eq(load_hackathons(path~).revision, 3)
}
