///|
test "hosted hackathon identity requires active account and supported role" {
  let team = parse_public_identity({
    "account_id": "account-alice",
    "state": "Active",
    "roles": ["EnterpriseUser"],
  })
  assert_true(team is Some(_))
  assert_true(
    parse_public_identity({
      "account_id": "account-alice",
      "state": "Suspended",
      "roles": ["EnterpriseUser"],
    })
    is None,
  )
  assert_true(
    parse_public_identity({ "state": "Active", "roles": ["PlatformOperator"] })
    is None,
  )
  assert_true(
    parse_public_identity({
      "account_id": "account-alice",
      "state": "Active",
      "roles": ["AuditReader"],
    })
    is None,
  )
}

///|
test "hosted team actions bind membership to authenticated account" {
  let alice = PublicIdentity::{
    account_id: "account-alice",
    is_operator: false,
    is_enterprise_user: true,
  }
  let mayor = PublicIdentity::{
    account_id: "account-mayor",
    is_operator: true,
    is_enterprise_user: false,
  }
  let state : @hackathon.HackathonState = @json.from_json({
    "schema": "moontown.contest-express.hackathon.v1",
    "revision": 1,
    "challenges": [],
    "challenge_history": [],
    "teams": [
      {
        "id": "team-alice",
        "challenge_id": "challenge-one",
        "name": "Alice Team",
        "members": ["account-alice"],
      },
    ],
    "submissions": [],
    "evaluations": [],
  })
  let own_team : Json = {
    "id": "team-two",
    "challenge_id": "challenge-one",
    "name": "Second Team",
    "members": ["account-alice"],
  }
  assert_true(hackathon_action_allowed(alice, state, "register-team", own_team))
  assert_false(
    hackathon_action_allowed(alice, state, "register-team", {
      "id": "team-other",
      "challenge_id": "challenge-one",
      "name": "Other Team",
      "members": ["account-bob"],
    }),
  )
  assert_false(
    hackathon_action_allowed(alice, state, "register-team", {
      "id": "team-other",
      "challenge_id": "challenge-one",
      "name": "Other Team",
      "members": ["account-alice", "account-bob"],
    }),
  )
  let own_submission : Json = {
    "id": "submission-one",
    "challenge_id": "challenge-one",
    "team_id": "team-alice",
    "version": 99,
    "artifact_url": "https://example.test/solution",
    "first_person_solution": "We built it.",
    "submitted_ms": 1,
  }
  assert_true(hackathon_action_allowed(alice, state, "submit", own_submission))
  assert_false(hackathon_action_allowed(mayor, state, "submit", own_submission))
  assert_false(hackathon_action_allowed(alice, state, "evaluate", {}))
  assert_true(hackathon_action_allowed(mayor, state, "evaluate", {}))
  assert_true(
    hackathon_action_allowed(alice, state, "join-team", {
      "team_id": "team-alice",
      "member_id": "account-bob",
    }),
  )
  assert_true(
    hackathon_actor_payload(
      "join-team",
      { "team_id": "team-alice", "member_id": "account-bob" },
      alice,
    )
    is { "member_id": String("account-alice"), .. },
  )
}

///|
test "hosted projection redacts evaluator inputs and other team members" {
  let alice = PublicIdentity::{
    account_id: "account-alice",
    is_operator: false,
    is_enterprise_user: true,
  }
  let state : @hackathon.HackathonState = @json.from_json({
    "schema": "moontown.contest-express.hackathon.v1",
    "revision": 1,
    "challenges": [
      {
        "id": "challenge-one",
        "name": "Moon Build",
        "topic": "Build a town service",
        "scope": "One week",
        "possibility_wiki": "Ideas",
        "first_person_solution": "I will build a service",
        "deadline_ms": "999999",
        "benchmark_version": 1,
        "benchmark_materials": ["public-benchmark"],
        "evaluation_materials": ["secret-evaluation-material"],
        "rubric": [],
        "published": true,
      },
    ],
    "challenge_history": [],
    "teams": [
      {
        "id": "team-bob",
        "challenge_id": "challenge-one",
        "name": "Bob Team",
        "members": ["account-bob"],
      },
    ],
    "submissions": [],
    "evaluations": [],
  })
  let projected = hackathon_safe_projection(state, alice).stringify()
  assert_true(projected.contains("public-benchmark"))
  assert_false(projected.contains("secret-evaluation-material"))
  assert_false(projected.contains("account-bob"))
  assert_true(projected.contains("\"can_evaluate\":false"))
}

///|
test "hosted evaluation reviewer is authenticated actor" {
  let mayor = PublicIdentity::{
    account_id: "account-mayor",
    is_operator: true,
    is_enterprise_user: false,
  }
  let rewritten = hackathon_actor_payload(
    "evaluate",
    { "reviewer": "forged", "scores": [] },
    mayor,
  )
  assert_true(rewritten is { "reviewer": String("account-mayor"), .. })
}
