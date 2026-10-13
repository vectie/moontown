///|
fn competition_access_fixture() -> @hackathon.HackathonState raise {
  let fields = contest_fields(@hackathon.empty_hackathon_state().to_json())
  fields["challenges"] = Json::array([
    {
      "id": "public-event",
      "name": "Contest Express",
      "topic": "Town service",
      "scope": "Benchmark",
      "possibility_wiki": "Public wiki",
      "first_person_solution": "I built it",
      "deadline_ms": "1000",
      "benchmark_version": 1,
      "benchmark_materials": ["public-material"],
      "evaluation_materials": ["private-review-guidance"],
      "rubric": [],
      "published": true,
    },
    {
      "id": "draft-event",
      "name": "Secret draft title",
      "topic": "Draft",
      "scope": "Draft",
      "possibility_wiki": "Draft",
      "first_person_solution": "Draft",
      "deadline_ms": "1000",
      "benchmark_version": 1,
      "benchmark_materials": ["draft-material"],
      "evaluation_materials": ["draft-guidance"],
      "rubric": [],
      "published": false,
    },
  ])
  fields["programs"] = Json::array([
    {
      "challenge_id": "public-event",
      "state": "open",
      "organizer": "Mayor",
      "timezone": "Asia/Shanghai",
      "registration_open_ms": "0",
      "registration_close_ms": "500",
      "submission_open_ms": "0",
      "review_close_ms": "2000",
      "max_team_size": 4,
      "daily_submission_limit": 3,
      "contact_url": "https://example.test/contact",
      "tracks": [],
      "prizes": [],
      "partners": [],
      "faq": [],
      "announcements": [],
      "evaluator_ids": ["reviewer-account"],
    },
  ])
  fields["teams"] = Json::array([
    {
      "id": "alice-team",
      "challenge_id": "public-event",
      "name": "Alice builders",
      "members": ["alice-account"],
    },
    {
      "id": "bob-team",
      "challenge_id": "public-event",
      "name": "Bob builders",
      "members": ["bob-account"],
    },
  ])
  fields["team_profiles"] = Json::array([
    {
      "team_id": "alice-team",
      "captain_id": "alice-account",
      "affiliation": "MoonTown",
      "track_id": "track-one",
    },
    {
      "team_id": "bob-team",
      "captain_id": "bob-account",
      "affiliation": "MoonTown",
      "track_id": "track-one",
    },
  ])
  fields["invitations"] = Json::array([
    {
      "id": "alice-invite",
      "team_id": "alice-team",
      "inviter_id": "alice-account",
      "invitee_id": "invited-account",
      "state": "pending",
      "created_ms": "10",
    },
    {
      "id": "bob-invite",
      "team_id": "bob-team",
      "inviter_id": "bob-account",
      "invitee_id": "other-account",
      "state": "pending",
      "created_ms": "10",
    },
  ])
  fields["submissions"] = Json::array([
    {
      "id": "alice-submission",
      "challenge_id": "public-event",
      "team_id": "alice-team",
      "version": 1,
      "artifact_url": "https://example.test/private-alice-artifact",
      "first_person_solution": "Alice solution",
      "submitted_ms": "20",
    },
    {
      "id": "bob-submission",
      "challenge_id": "public-event",
      "team_id": "bob-team",
      "version": 1,
      "artifact_url": "https://example.test/private-bob-artifact",
      "first_person_solution": "Bob solution",
      "submitted_ms": "20",
    },
  ])
  fields["submission_packages"] = Json::array([
    {
      "submission_id": "alice-submission",
      "track_id": "track-one",
      "materials": [
        {
          "kind": "source",
          "url": "https://example.test/private-alice-source",
          "sha256": "hash",
        },
      ],
      "benchmark_version": 1,
    },
  ])
  fields["benchmark_runs"] = Json::array([
    {
      "id": "alice-run",
      "submission_id": "alice-submission",
      "reviewer_id": "reviewer-account",
      "worker_run_id": "private-worker-id",
      "state": "review",
      "reason": "Measured",
      "input_hash": "private-input-hash",
      "output_hash": "private-output-hash",
      "benchmark_version": 1,
      "metrics": [{ "metric_id": "latency", "value": 10.0 }],
      "evidence": ["ledger:private-run-evidence"],
      "queued_ms": "30",
      "finished_ms": "40",
    },
  ])
  @hackathon.decode_hackathon_state(Json::object(fields))
}

///|
test "anonymous competition browse excludes drafts and private rosters and receipts" {
  let state = competition_access_fixture()
  let value = hackathon_competition_projection(state, None).stringify()
  assert_true(value.contains("public-material"))
  assert_true(value.contains("Alice builders"))
  assert_true(value.contains("\"role\":\"anonymous\""))
  for
    secret in [
      "Secret draft title", "private-review-guidance", "alice-account", "bob-account",
      "reviewer-account", "private-alice-artifact", "private-bob-artifact", "private-alice-source",
      "private-worker-id", "alice-invite",
    ] {
    assert_false(value.contains(secret))
  }
}

///|
test "team workbench exposes own receipts and invitation consent while hiding other team artifacts" {
  let state = competition_access_fixture()
  let alice = PublicIdentity::{
    account_id: "alice-account",
    is_operator: false,
    is_enterprise_user: true,
  }
  let value = hackathon_safe_projection(state, alice).stringify()
  assert_true(value.contains("private-alice-artifact"))
  assert_true(value.contains("private-alice-source"))
  assert_true(value.contains("alice-invite"))
  assert_true(value.contains("\"state\":\"review\""))
  for
    secret in [
      "private-bob-artifact", "bob-account", "bob-invite", "private-worker-id", "private-input-hash",
      "private-run-evidence", "reviewer-account", "private-review-guidance",
    ] {
    assert_false(value.contains(secret))
  }
  assert_true(
    hackathon_action_allowed(alice, state, "invite-member", {
      "team_id": "alice-team",
    }),
  )
  assert_false(
    hackathon_action_allowed(alice, state, "invite-member", {
      "team_id": "bob-team",
    }),
  )
  assert_false(
    hackathon_action_allowed(alice, state, "respond-invitation", {
      "invitation_id": "alice-invite",
      "member_id": "invited-account",
    }),
  )
  let invitee = PublicIdentity::{
    account_id: "invited-account",
    is_operator: false,
    is_enterprise_user: true,
  }
  assert_true(
    hackathon_action_allowed(invitee, state, "respond-invitation", {
      "invitation_id": "alice-invite",
    }),
  )
  assert_true(
    hackathon_safe_projection(state, invitee)
    .stringify()
    .contains("alice-invite"),
  )
}

///|
test "appointed evaluator has scoped review access and cannot publish or forge measured results" {
  let state = competition_access_fixture()
  let reviewer = PublicIdentity::{
    account_id: "reviewer-account",
    is_operator: false,
    is_enterprise_user: true,
  }
  let value = hackathon_safe_projection(state, reviewer).stringify()
  assert_true(value.contains("private-review-guidance"))
  assert_true(value.contains("private-alice-artifact"))
  assert_true(value.contains("private-bob-artifact"))
  assert_true(value.contains("private-run-evidence"))
  assert_true(value.contains("\"role\":\"evaluator\""))
  assert_true(
    hackathon_safe_projection(state, reviewer)
    is {
      "viewer": { "review_challenge_ids": Array([String("public-event")]), .. },
      ..
    },
  )
  assert_false(value.contains("bob-account"))
  assert_false(value.contains("alice-invite"))
  assert_true(
    hackathon_action_allowed(reviewer, state, "queue-benchmark", {
      "submission_id": "alice-submission",
    }),
  )
  assert_true(
    hackathon_action_allowed(reviewer, state, "approve-benchmark", {
      "run_id": "alice-run",
    }),
  )
  assert_false(
    hackathon_action_allowed(reviewer, state, "queue-benchmark", {
      "submission_id": "unknown-submission",
    }),
  )
  assert_false(hackathon_action_allowed(reviewer, state, "save-program", {}))
  assert_false(hackathon_action_allowed(reviewer, state, "resolve-appeal", {}))
  assert_false(
    hackathon_action_allowed(reviewer, state, "record-benchmark-result", {
      "run_id": "alice-run",
    }),
  )
  assert_true(
    hackathon_actor_payload(
      "queue-benchmark",
      { "reviewer_id": "forged" },
      reviewer,
    )
    is { "reviewer_id": String("reviewer-account"), .. },
  )
  let mayor = PublicIdentity::{
    account_id: "mayor-account",
    is_operator: true,
    is_enterprise_user: false,
  }
  assert_false(
    hackathon_action_allowed(mayor, state, "record-benchmark-result", {}),
  )
  assert_true(
    hackathon_safe_projection(state, mayor)
    .stringify()
    .contains("Secret draft title"),
  )
}

///|
async test "workspace reconciliation status is available only to Mayor responses" {
  let state = competition_access_fixture()
  let public_value = hackathon_response(state, None)
  assert_false(contest_fields(public_value).contains("workspace_sync"))
  let mayor = PublicIdentity::{
    account_id: "mayor-account",
    is_operator: true,
    is_enterprise_user: false,
  }
  let mayor_value = hackathon_response(state, Some(mayor))
  assert_true(contest_fields(mayor_value).contains("workspace_sync"))
  assert_true(contest_fields(mayor_value).contains("program_readiness"))
}

///|
test "local competition response declares trusted Mayor mode with the same board envelopes" {
  let value = local_hackathon_projection(competition_access_fixture())
  assert_true(
    value
    is {
      "viewer": {
        "account_id": String("local-mayor"),
        "local_operator": True,
        "can_publish": True,
        ..
      },
      "leaderboards": Object(_),
      "competition_boards": Object(_),
      ..
    },
  )
  assert_true(hackathon_public_path("/contest-express/login"))
  assert_true(hackathon_public_path("/hackathon.css"))
  assert_false(hackathon_public_path("/town.json"))
}

///|
test "hosted Mayor may reconcile MoonBook workspaces while team and evaluator accounts cannot" {
  let state = competition_access_fixture()
  let mayor = PublicIdentity::{
    account_id: "mayor-account",
    is_operator: true,
    is_enterprise_user: false,
  }
  assert_true(hackathon_action_allowed(mayor, state, "sync-workspaces", {}))
  for account_id in ["alice-account", "reviewer-account"] {
    let identity = PublicIdentity::{
      account_id,
      is_operator: false,
      is_enterprise_user: true,
    }
    assert_false(
      hackathon_action_allowed(identity, state, "sync-workspaces", {}),
    )
  }
}
