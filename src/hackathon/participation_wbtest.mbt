///|
fn participation_test_program() -> CompetitionProgram {
  {
    challenge_id: "river-ai",
    state: "open",
    organizer: "Mayor",
    timezone: "UTC",
    registration_open_ms: 10UL,
    registration_close_ms: 2000UL,
    submission_open_ms: 100UL,
    review_close_ms: 6000UL,
    max_team_size: 2,
    daily_submission_limit: 2,
    contact_url: "https://example.org/help",
    tracks: [
      {
        id: "map",
        name: "Map",
        description: "Maps",
        scoring_mode: "rubric",
        runner_key: "",
        required_materials: ["code", "report"],
        metrics: [],
        gates: [],
      },
    ],
    prizes: [],
    partners: [],
    faq: [],
    announcements: [],
    evaluator_ids: ["reviewer-1"],
  }
}

///|
fn participation_test_state() -> HackathonState raise {
  let state = publish_challenge(empty_hackathon_state(), sample_challenge())
  { ..state, programs: [participation_test_program()], }
}

///|
fn participation_register_payload(id : String, captain : String) -> Json {
  let team : Team = { ..sample_team(id), members: [captain], }
  let profile : TeamProfile = {
    team_id: id,
    captain_id: captain,
    affiliation: "Residents",
    track_id: "map",
  }
  { "team": team.to_json(), "profile": profile.to_json() }
}

///|
fn participation_test_apply(
  state : HackathonState,
  action : String,
  payload : Json,
  now_ms : UInt64,
) -> HackathonState raise {
  guard apply_participation_action(state, action, payload, now_ms) is Some(next) else {
    fail("test action was not handled")
  }
  next
}

///|
fn participation_test_rejected(
  state : HackathonState,
  action : String,
  payload : Json,
  now_ms : UInt64,
) -> Bool {
  try apply_participation_action(state, action, payload, now_ms) catch {
    _ => true
  } noraise {
    _ => false
  }
}

///|
fn participation_package_payload(id : String) -> Json {
  let bundle : SubmissionPackage = {
    submission_id: id,
    track_id: "map",
    materials: [
      {
        kind: "code",
        url: "https://example.org/code",
        sha256: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
      },
      {
        kind: "report",
        url: "https://example.org/report",
        sha256: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
      },
    ],
    benchmark_version: 99,
  }
  {
    "submission": sample_submission(id, "blue", 999999UL).to_json(),
    "package": bundle.to_json(),
  }
}

///|
test "competition registration requires captain consent and a configured track" {
  let state = participation_test_state()
  assert_true(
    participation_test_rejected(
      state,
      "register-competition-team",
      participation_register_payload("blue", "captain"),
      9UL,
    ),
  )
  assert_true(
    participation_test_rejected(
      state,
      "register-competition-team",
      participation_register_payload("blue", "captain"),
      2001UL,
    ),
  )
  let state = participation_test_apply(
    state,
    "register-competition-team",
    participation_register_payload("blue", "captain"),
    10UL,
  )
  assert_eq(state.teams[0].members, ["captain"])
  assert_eq(state.team_profiles[0].captain_id, "captain")
  assert_true(
    participation_test_rejected(
      state,
      "register-competition-team",
      participation_register_payload("red", "captain"),
      20UL,
    ),
  )
  let invalid_profile : TeamProfile = {
    team_id: "red",
    captain_id: "other",
    affiliation: "",
    track_id: "missing",
  }
  assert_true(
    participation_test_rejected(
      state,
      "register-competition-team",
      {
        "team": sample_team("red").to_json(),
        "profile": invalid_profile.to_json(),
      },
      20UL,
    ),
  )
  try register_team(state, sample_team("legacy")) catch {
    _ => ()
  } noraise {
    _ => fail("legacy registration bypassed the program")
  }
}

///|
test "invitations bind captain and recipient and recheck capacity on acceptance" {
  let state = participation_test_apply(
    participation_test_state(),
    "register-competition-team",
    participation_register_payload("blue", "captain"),
    20UL,
  )
  assert_true(
    participation_test_rejected(
      state,
      "invite-member",
      {
        "id": "bad",
        "team_id": "blue",
        "inviter_id": "stranger",
        "invitee_id": "alice",
      },
      30UL,
    ),
  )
  let state = participation_test_apply(
    state,
    "invite-member",
    {
      "id": "alice-invite",
      "team_id": "blue",
      "inviter_id": "captain",
      "invitee_id": "alice",
    },
    30UL,
  )
  let state = participation_test_apply(
    state,
    "invite-member",
    {
      "id": "bob-invite",
      "team_id": "blue",
      "inviter_id": "captain",
      "invitee_id": "bob",
    },
    31UL,
  )
  assert_eq(state.teams[0].members.length(), 1)
  assert_eq(state.invitations[0].created_ms, 30UL)
  assert_true(
    participation_test_rejected(
      state,
      "respond-invitation",
      { "invitation_id": "alice-invite", "member_id": "bob", "accept": true },
      40UL,
    ),
  )
  let state = participation_test_apply(
    state,
    "respond-invitation",
    { "invitation_id": "alice-invite", "member_id": "alice", "accept": true },
    40UL,
  )
  assert_eq(state.teams[0].members, ["captain", "alice"])
  assert_true(
    participation_test_rejected(
      state,
      "respond-invitation",
      { "invitation_id": "bob-invite", "member_id": "bob", "accept": true },
      50UL,
    ),
  )
  let state = participation_test_apply(
    state,
    "respond-invitation",
    { "invitation_id": "bob-invite", "member_id": "bob", "accept": false },
    3000UL,
  )
  assert_eq(state.invitations[1].state, "declined")
  try join_team(state, "blue", "bypass") catch {
    _ => ()
  } noraise {
    _ => fail("legacy join bypassed consent")
  }
  assert_true(
    participation_test_rejected(
      state,
      "remove-member",
      { "team_id": "blue", "captain_id": "alice", "member_id": "captain" },
      60UL,
    ),
  )
  let state = participation_test_apply(
    state,
    "remove-member",
    { "team_id": "blue", "captain_id": "captain", "member_id": "alice" },
    60UL,
  )
  assert_eq(state.teams[0].members, ["captain"])
}

///|
test "packages validate required materials hashes track quota and benchmark snapshot" {
  let state = participation_test_apply(
    participation_test_state(),
    "register-competition-team",
    participation_register_payload("blue", "captain"),
    20UL,
  )
  assert_true(
    participation_test_rejected(
      state,
      "submit-package",
      participation_package_payload("early"),
      99UL,
    ),
  )
  let payload = participation_package_payload("bad")
  let request : SubmissionPackageRequest = @json.from_json(payload)
  let bundle = request.package
  for
    invalid in [
      { ..bundle, track_id: "missing", },
      { ..bundle, materials: [bundle.materials[0]], },
      {
        ..bundle,
        materials: [
          { ..bundle.materials[0], sha256: "bad", },
          bundle.materials[1],
        ],
      },
      {
        ..bundle,
        materials: [
          { ..bundle.materials[0], url: "file:///private/code", },
          bundle.materials[1],
        ],
      },
    ] {
    assert_true(
      participation_test_rejected(
        state,
        "submit-package",
        {
          "submission": request.submission.to_json(),
          "package": invalid.to_json(),
        },
        100UL,
      ),
    )
  }
  let state = participation_test_apply(
    state,
    "submit-package",
    participation_package_payload("one"),
    100UL,
  )
  assert_eq(state.submissions[0].submitted_ms, 100UL)
  assert_eq(state.submission_packages[0].benchmark_version, 1)
  let state = participation_test_apply(
    state,
    "submit-package",
    participation_package_payload("two"),
    200UL,
  )
  assert_eq(state.submissions[1].version, 2)
  assert_true(
    participation_test_rejected(
      state,
      "submit-package",
      participation_package_payload("three"),
      300UL,
    ),
  )
  let extended = {
    ..state,
    challenges: [{ ..state.challenges[0], deadline_ms: 86401000UL, }],
  }
  let next_day = participation_test_apply(
    extended,
    "submit-package",
    participation_package_payload("tomorrow"),
    86400100UL,
  )
  assert_eq(next_day.submissions.length(), 3)
  assert_true(
    participation_test_rejected(
      state,
      "submit-package",
      participation_package_payload("late"),
      5001UL,
    ),
  )
  try submit_solution(state, sample_submission("bypass", "blue", 300UL)) catch {
    _ => ()
  } noraise {
    _ => fail("legacy submission bypassed the package")
  }
  let state = { ..state, programs: [{ ..state.programs[0], state: "final", }], }
  assert_true(
    participation_test_rejected(
      state,
      "submit-package",
      participation_package_payload("frozen"),
      300UL,
    ),
  )
  try
    revise_benchmark(
      state,
      "river-ai",
      ["new"],
      ["new"],
      sample_challenge().rubric,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("final benchmark changed")
  }
}

///|
test "invitation acceptance rechecks one team per event and review preserves submission snapshot" {
  let state = participation_test_apply(
    participation_test_state(),
    "register-competition-team",
    participation_register_payload("blue", "captain"),
    20UL,
  )
  let state = participation_test_apply(
    state,
    "invite-member",
    {
      "id": "alice",
      "team_id": "blue",
      "inviter_id": "captain",
      "invitee_id": "alice",
    },
    30UL,
  )
  let state = participation_test_apply(
    state,
    "register-competition-team",
    participation_register_payload("red", "alice"),
    35UL,
  )
  assert_true(
    participation_test_rejected(
      state,
      "respond-invitation",
      { "invitation_id": "alice", "member_id": "alice", "accept": true },
      40UL,
    ),
  )
  let state = participation_test_apply(
    state,
    "submit-package",
    participation_package_payload("one"),
    100UL,
  )
  let reviewed = record_evaluation(
    state,
    sample_evaluation("one", 40, 30, 200UL),
  )
  assert_eq(reviewed.evaluations[0].total, 70)
  let revised = revise_benchmark(
    reviewed,
    "river-ai",
    ["https://example.org/v2"],
    ["https://example.org/rules-v2"],
    sample_challenge().rubric,
  )
  let amended_review = record_evaluation(revised, {
    ..sample_evaluation("one", 40, 30, 200UL),
    benchmark_version: 2,
  })
  assert_eq(amended_review.submission_packages[0].benchmark_version, 1)
  assert_eq(amended_review.evaluations[1].benchmark_version, 2)
  let metric = {
    ..state,
    programs: [
      {
        ..state.programs[0],
        tracks: [{ ..state.programs[0].tracks[0], scoring_mode: "metric", }],
      },
    ],
  }
  let injected = { ..metric, evaluations: reviewed.evaluations, }
  assert_true(leaderboard(injected, "river-ai").is_empty())
  try record_evaluation(metric, sample_evaluation("one", 40, 30, 200UL)) catch {
    _ => ()
  } noraise {
    _ => fail("manual points ranked a metric track")
  }
  let frozen = {
    ..reviewed,
    programs: [{ ..reviewed.programs[0], state: "final", }],
  }
  try record_evaluation(frozen, sample_evaluation("one", 40, 30, 300UL)) catch {
    _ => ()
  } noraise {
    _ => fail("final review changed")
  }
}
