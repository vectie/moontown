///|
async test "locked competition workflow keeps actor receipts and private books after reload" {
  let root = @fs.realpath(@fs.tmpdir(prefix="contest-express-workflow-"))
  defer @fs.rmdir(root, recursive=true)
  let path = root + "/hackathons.json"
  let _ = apply_hackathon_action(
    "save-program",
    { "program": program_test_program(), "brief": program_test_brief() },
    10UL,
    path~,
    actor_id=Some("mayor"),
    actor_is_operator=true,
  )
  let _ = apply_hackathon_action(
    "publish-program",
    { "challenge_id": "river-ai" },
    20UL,
    path~,
    actor_id=Some("mayor"),
    actor_is_operator=true,
  )
  let _ = apply_hackathon_action(
    "register-competition-team",
    {
      "team": {
        "id": "builders",
        "challenge_id": "river-ai",
        "name": "Builders",
        "members": ["alice"],
      },
      "profile": {
        "team_id": "builders",
        "captain_id": "alice",
        "affiliation": "Town lab",
        "track_id": "mapping",
      },
    },
    300UL,
    path~,
    actor_id=Some("alice"),
  )
  let denied = try {
    let _ = apply_hackathon_action(
      "invite-member",
      {
        "id": "forged",
        "team_id": "builders",
        "inviter_id": "alice",
        "invitee_id": "bob",
      },
      350UL,
      path~,
      actor_id=Some("outsider"),
    )
    false
  } catch {
    _ => true
  }
  assert_true(denied)
  let _ = apply_hackathon_action(
    "invite-member",
    {
      "id": "invite-bob",
      "team_id": "builders",
      "inviter_id": "alice",
      "invitee_id": "bob",
    },
    400UL,
    path~,
    actor_id=Some("alice"),
  )
  let denied = try {
    let _ = apply_hackathon_action(
      "respond-invitation",
      { "invitation_id": "invite-bob", "member_id": "bob", "accept": true },
      450UL,
      path~,
      actor_id=Some("outsider"),
    )
    false
  } catch {
    _ => true
  }
  assert_true(denied)
  let _ = apply_hackathon_action(
    "respond-invitation",
    { "invitation_id": "invite-bob", "member_id": "spoof", "accept": true },
    500UL,
    path~,
    actor_id=Some("bob"),
  )
  let state = apply_hackathon_action(
    "submit-package",
    {
      "submission": {
        "id": "builders-v1",
        "challenge_id": "river-ai",
        "team_id": "builders",
        "artifact_url": "https://example.org/demo",
        "first_person_solution": "We compared river sensor evidence",
      },
      "package": {
        "submission_id": "builders-v1",
        "track_id": "mapping",
        "benchmark_version": 999,
        "materials": [
          {
            "kind": "source",
            "url": "https://example.org/source",
            "sha256": "a".repeat(64),
          },
          {
            "kind": "report",
            "url": "https://example.org/report",
            "sha256": "b".repeat(64),
          },
        ],
      },
    },
    1000UL,
    path~,
    actor_id=Some("bob"),
  )
  assert_eq(state.submissions[0].submitted_ms, 1000UL)
  assert_eq(state.submissions[0].version, 1)
  assert_eq(state.submission_packages[0].benchmark_version, 1)
  let denied = try {
    let _ = apply_hackathon_action(
      "evaluate",
      {
        "submission_id": "builders-v1",
        "benchmark_version": 1,
        "reviewer": "reviewer",
        "scores": [
          { "criterion_id": "quality", "points": 100, "evidence": "No proof" },
        ],
      },
      1100UL,
      path~,
      actor_id=Some("bob"),
    )
    false
  } catch {
    _ => true
  }
  assert_true(denied)
  let state = apply_hackathon_action(
    "evaluate",
    {
      "submission_id": "builders-v1",
      "benchmark_version": 1,
      "reviewer": "spoof",
      "scores": [
        {
          "criterion_id": "quality",
          "points": 83,
          "evidence": "Verified readings and reproducible method",
        },
      ],
    },
    1200UL,
    path~,
    actor_id=Some("reviewer"),
  )
  assert_eq(state.evaluations[0].reviewer, "reviewer")
  assert_eq(state.evaluations[0].total, 83)
  let board = competition_leaderboard(state, "river-ai", "mapping")
  assert_eq(board[0].team_name, "Builders")
  assert_eq(board[0].score, 83.0)
  let _ = apply_hackathon_action(
    "open-appeal",
    {
      "id": "appeal-proof",
      "submission_id": "builders-v1",
      "member_id": "spoof",
      "reason": "Recheck the calibration evidence",
    },
    1300UL,
    path~,
    actor_id=Some("alice"),
  )
  let _ = apply_hackathon_action(
    "transition-program",
    {
      "challenge_id": "river-ai",
      "state": "evaluating",
      "reason": "Submission deadline passed",
    },
    5001UL,
    path~,
    actor_id=Some("mayor"),
    actor_is_operator=true,
  )
  let denied = try {
    let _ = apply_hackathon_action(
      "transition-program",
      {
        "challenge_id": "river-ai",
        "state": "final",
        "reason": "Publish prizes",
      },
      5500UL,
      path~,
      actor_id=Some("mayor"),
      actor_is_operator=true,
    )
    false
  } catch {
    _ => true
  }
  assert_true(denied)
  let _ = apply_hackathon_action(
    "resolve-appeal",
    {
      "appeal_id": "appeal-proof",
      "resolution": "Calibration evidence reviewed; retain score",
    },
    5600UL,
    path~,
    actor_id=Some("mayor"),
    actor_is_operator=true,
  )
  let state = apply_hackathon_action(
    "transition-program",
    {
      "challenge_id": "river-ai",
      "state": "final",
      "reason": "All accepted work reviewed and appeals resolved",
    },
    6000UL,
    path~,
    actor_id=Some("mayor"),
    actor_is_operator=true,
  )
  let reloaded = load_hackathons(path~)
  assert_eq(reloaded.revision, state.revision)
  assert_eq(
    competition_leaderboard(reloaded, "river-ai", "mapping")[0].status,
    "final",
  )
  assert_eq(reloaded.appeals[0].member_id, "alice")
  assert_eq(reloaded.teams[0].members.length(), 2)
  assert_true(
    competition_workspace_sync_status(path~)
    is { "ready": True, "book_count": Number(2), .. },
  )
  let team_root = path + ".books/contest-team-builders"
  assert_true(@fs.exists(team_root + "/wiki/index.md"))
  let receipt = @fs.read_file(
    team_root + "/raw/contest-express/revision-\{state.revision}.json",
  ).text()
  assert_true(
    receipt.contains("builders-v1") &&
    receipt.contains("Calibration evidence reviewed"),
  )
  let catalog : Array[@moonbook.BookCatalogEntry] = @json.from_json(
    @json.parse(@fs.read_file(path + ".moonbooks.json").text()),
  )
  assert_eq(catalog.length(), 2)
  assert_true(catalog.all(book => book.memory_scope is BookPrivate))
}

///|
async test "event and team books use disjoint identities for ambiguous valid slugs" {
  let root = @fs.realpath(@fs.tmpdir(prefix="contest-express-book-identities-"))
  defer @fs.rmdir(root, recursive=true)
  let path = root + "/hackathons.json"
  let state = {
    ..empty_hackathon_state(),
    revision: 1,
    challenges: [
      { ..program_test_brief(), id: "river", },
      { ..program_test_brief(), id: "river-team-blue", },
    ],
    teams: [
      { id: "blue", challenge_id: "river", name: "Blue", members: ["alice"], },
    ],
  }
  assert_true(
    reconcile_competition_workspaces(state, path~)
    is { "ready": True, "book_count": Number(3), .. },
  )
  let catalog : Array[@moonbook.BookCatalogEntry] = @json.from_json(
    @json.parse(@fs.read_file(path + ".moonbooks.json").text()),
  )
  assert_eq(catalog[0].id, "contest-event-river")
  assert_eq(catalog[1].id, "contest-event-river-team-blue")
  assert_eq(catalog[2].id, "contest-team-blue")
  assert_true(catalog[1].workspace_root != catalog[2].workspace_root)
  let event = @fs.read_file(
    catalog[1].workspace_root + "/raw/contest-express/revision-1.json",
  ).text()
  let team = @fs.read_file(
    catalog[2].workspace_root + "/raw/contest-express/revision-1.json",
  ).text()
  assert_true(
    event.contains("book-receipt.v1") && !event.contains("\"members\""),
  )
  assert_true(team.contains("team-receipt.v1") && team.contains("alice"))
}

///|
async test "book projection failure is visible and reconstructable without duplicating ledger state" {
  let root = @fs.realpath(@fs.tmpdir(prefix="contest-express-book-repair-"))
  defer @fs.rmdir(root, recursive=true)
  let path = root + "/hackathons.json"
  @fs.write_file(path + ".books", "blocked directory", create_mode=CreateNew)
  let state = apply_hackathon_action(
    "publish",
    { ..program_test_brief(), benchmark_version: 1, }.to_json(),
    10UL,
    path~,
  )
  assert_eq(state.revision, 1)
  assert_eq(load_hackathons(path~).revision, 1)
  assert_true(
    competition_workspace_sync_status(path~) is { "ready": False, .. },
  )
  @fs.remove(path + ".books")
  let repaired = apply_hackathon_action(
    "sync-workspaces",
    Json::object(Map([])),
    20UL,
    path~,
    actor_id=Some("mayor"),
    actor_is_operator=true,
  )
  assert_eq(repaired.revision, 1)
  assert_true(competition_workspace_sync_status(path~) is { "ready": True, .. })
}
