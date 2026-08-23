///|
fn lifecycle_event(
  id : String,
  kind : String,
  at : String,
  issue? : String? = None,
) -> PackLifecycleEvent {
  {
    contract_id: pack_lifecycle_event_contract_id(),
    event_id: id,
    pack_id: "moonfind",
    version: "1.0.0",
    kind,
    occurred_at: at,
    evidence_refs: ["receipts/\{id}.json"],
    issue,
  }
}

///|
test "pack lifecycle follows validated install activation and projection" {
  let draft = draft_pack_lifecycle("moonfind", "1.0.0", "t0")
  let validated = reduce_pack_lifecycle(
    draft,
    lifecycle_event("e1", "validated", "t1"),
  )
  guard validated is Ok(validated) else { fail("expected validation") }
  let installed = reduce_pack_lifecycle(
    validated,
    lifecycle_event("e2", "installed", "t2"),
  )
  guard installed is Ok(installed) else { fail("expected installation") }
  let active = reduce_pack_lifecycle(
    installed,
    lifecycle_event("e3", "activated", "t3"),
  )
  guard active is Ok(active) else { fail("expected activation") }
  let projecting = reduce_pack_lifecycle(
    active,
    lifecycle_event("e4", "projection-accepted", "t4"),
  )
  guard projecting is Ok(projecting) else { fail("expected projection") }
  assert_eq(projecting.stage, "projecting")
  assert_eq(projecting.sequence, 4)
  assert_eq(projecting.last_projection_at, Some("t4"))
}

///|
test "pack lifecycle rejects skipped transitions and is retry idempotent" {
  let draft = draft_pack_lifecycle("moonfind", "1.0.0", "t0")
  assert_true(
    reduce_pack_lifecycle(draft, lifecycle_event("skip", "activated", "t1"))
    is Err(_),
  )
  let event = lifecycle_event("e1", "validated", "t1")
  guard reduce_pack_lifecycle(draft, event) is Ok(validated) else {
    fail("expected validation")
  }
  guard reduce_pack_lifecycle(validated, event) is Ok(retried) else {
    fail("expected idempotent retry")
  }
  assert_eq(retried.sequence, 1)
  assert_eq(retried.applied_event_ids, ["e1"])
}

///|
test "degraded projection requires an issue and can recover" {
  let draft = draft_pack_lifecycle("moonfind", "1.0.0", "t0")
  guard reduce_pack_lifecycle(draft, lifecycle_event("e1", "validated", "t1"))
    is Ok(validated) else {
    fail("expected validation")
  }
  guard reduce_pack_lifecycle(
      validated,
      lifecycle_event("e2", "installed", "t2"),
    )
    is Ok(installed) else {
    fail("expected installation")
  }
  guard reduce_pack_lifecycle(
      installed,
      lifecycle_event("e3", "activated", "t3"),
    )
    is Ok(active) else {
    fail("expected activation")
  }
  assert_true(
    reduce_pack_lifecycle(
      active,
      lifecycle_event("bad", "projection-rejected", "t4"),
    )
    is Err(_),
  )
  guard reduce_pack_lifecycle(
      active,
      lifecycle_event(
        "e4",
        "projection-rejected",
        "t4",
        issue=Some("stale schema"),
      ),
    )
    is Ok(degraded) else {
    fail("expected degraded state")
  }
  assert_eq(degraded.stage, "degraded")
  assert_eq(degraded.issue, Some("stale schema"))
  guard reduce_pack_lifecycle(
      degraded,
      lifecycle_event("e5", "projection-accepted", "t5"),
    )
    is Ok(recovered) else {
    fail("expected recovery")
  }
  assert_eq(recovered.stage, "projecting")
  assert_eq(recovered.issue, None)
}

///|
test "candidate receipt preserves bottom-up review boundary" {
  let candidate : TownPackCandidate = {
    contract_id: candidate_contract_id(),
    candidate_ref: "town/candidates/robotics-watch",
    origin_ref: "town/ideas/robotics-watch",
    target_pack_id: "moonfind",
    intake_operation_id: "research.candidate.intake",
    submitted_by: "robotics-salon",
    submitted_at: "t0",
    title: "Watch dexterous manipulation research",
    rationale: "The salon identified an unresolved evidence gap.",
    claim_ceiling: "research-evidence",
    evidence_refs: ["evidence/salon-12.json"],
    domain_payload: { "query": "dexterous manipulation" },
  }
  let submitted = submitted_candidate_receipt(candidate, "t0")
  guard transition_candidate_receipt(submitted, "route", "t1", []) is Ok(routed) else {
    fail("expected route")
  }
  guard transition_candidate_receipt(routed, "request-review", "t2", [])
    is Ok(pending) else {
    fail("expected review")
  }
  guard transition_candidate_receipt(pending, "accept", "t3", [
      "receipts/moonfind-intake.json",
    ])
    is Ok(accepted) else {
    fail("expected acceptance")
  }
  assert_eq(accepted.status, "accepted")
  assert_eq(accepted.sequence, 3)
  assert_true(accepted.evidence_refs.contains("receipts/moonfind-intake.json"))
}
