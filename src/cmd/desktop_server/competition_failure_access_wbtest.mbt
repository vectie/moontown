///|
test "failed worker diagnostics stay in review while local evidence paths are hidden in every API response" {
  let fields = contest_fields(competition_access_fixture().to_json())
  let run = contest_fields(
    contest_array(Json::object(fields), "benchmark_runs")[0],
  )
  run["state"] = "failed".to_json()
  run["reason"] = "Failure(src/hackathon/evaluation_runner.mbt:12: /tmp/runner-private/log.txt)".to_json()
  run["evidence"] = Json::array([
    "ledger:worker-receipt".to_json(),
    "/tmp/runner-private/receipt.json".to_json(),
    "/Users/operator/runner/log.txt".to_json(),
  ])
  fields["benchmark_runs"] = Json::array([Json::object(run)])
  let state = @hackathon.decode_hackathon_state(Json::object(fields))
  let alice = PublicIdentity::{
    account_id: "alice-account",
    is_operator: false,
    is_enterprise_user: true,
  }
  let participant = hackathon_safe_projection(state, alice).stringify()
  assert_false(participant.contains("/tmp/"))
  assert_false(participant.contains("src/"))
  assert_false(participant.contains("/Users/"))
  assert_true(participant.contains("The review desk has the execution receipt"))
  for
    identity in [
      PublicIdentity::{
        account_id: "reviewer-account",
        is_operator: false,
        is_enterprise_user: true,
      },
      PublicIdentity::{
        account_id: "mayor-account",
        is_operator: true,
        is_enterprise_user: false,
      },
    ] {
    let projection = hackathon_safe_projection(state, identity)
    let projected_run = contest_array(projection, "benchmark_runs")[0]
    assert_true(projected_run is { "has_local_evidence": True, .. })
    assert_eq(contest_array(projected_run, "evidence"), [
      "ledger:worker-receipt".to_json(),
    ])
    assert_true(contest_string(projected_run, "reason").contains("Failure("))
  }
}

///|
test "workspace response cannot report an old reconciliation as ready for the current ledger" {
  let stale : Json = {
    "ready": true,
    "synced_revision": 5,
    "book_count": 2,
    "message": "Reconciled",
  }
  let projected = contest_workspace_sync_status(stale, 6)
  assert_true(
    projected is { "ready": False, "synced_revision": Number(5.0, ..), .. },
  )
  assert_eq(
    contest_string(projected, "message"),
    "Private MoonBook receipts need reconciliation for the current competition revision",
  )
  let current : Json = {
    "ready": true,
    "synced_revision": 6,
    "book_count": 2,
    "message": "Reconciled",
  }
  assert_eq(contest_workspace_sync_status(current, 6), current)
  assert_true(
    contest_workspace_sync_status(Json::null(), 6) is { "ready": False, .. },
  )
}
