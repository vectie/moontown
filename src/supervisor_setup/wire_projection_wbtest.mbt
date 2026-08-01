///|
async test "profile GET emits optional identity and consent as scalar or null" {
  let root = @fs.tmpdir(prefix="moontown-supervisor-wire-profile-")
  let application = supervisor_setup_application(root)
  let draft = {
    ..supervisor_test_draft("wire-profile-save-1", 0),
    avatar_url: Some("avatar://otter-steward"),
  }
  ignore(application.save_profile_draft("user-a", draft, now_ms=1234UL))
  let response = application.query_profile("user-a")
  guard response is Object(fields) &&
    fields.get("profile") is Some(Object(profile)) &&
    profile.get("identity") is Some(Object(identity)) &&
    profile.get("consent") is Some(Object(consent)) else {
    fail("profile GET must expose identity and consent objects")
  }
  assert_eq(
    identity.get("avatarUrl"),
    Some("avatar://otter-steward".to_json()),
  )
  assert_eq(consent.get("confirmedAtMs"), Some(1234UL.to_json()))

  let absent = {
    ..application.load_store().profiles[0],
    identity: { display_name: "Aster", avatar_url: None },
    consent: { ..application.load_store().profiles[0].consent, confirmed_at_ms: None },
  }
  guard supervisor_profile_projection(absent) is Object(absent_profile) &&
    absent_profile.get("identity") is Some(Object(absent_identity)) &&
    absent_profile.get("consent") is Some(Object(absent_consent)) else {
    fail("profile projection must remain an object")
  }
  assert_eq(absent_identity.get("avatarUrl"), Some(Json::null()))
  assert_eq(absent_consent.get("confirmedAtMs"), Some(Json::null()))
}

///|
async test "activation execution lifecycle and review wires never wrap option values" {
  let root = @fs.tmpdir(prefix="moontown-supervisor-wire-outboxes-")
  let application = supervisor_setup_application(root)
  let draft = {
    ..supervisor_test_draft("wire-profile-seed-1", 0),
    avatar_url: Some("avatar://moon-lantern"),
  }
  ignore(application.save_profile_draft("user-a", draft, now_ms=1000UL))
  ignore(
    application.activate_profile(
      "user-a",
      {
        command_id: "wire-activate-1",
        expected_version: 1,
        expected_cursor: 1,
        runtime_expected_cursor: Some(9),
      },
      now_ms=2000UL,
    ),
  )
  let queued_activation = latest_activation_handoff(
    application.load_store(),
    "supervisor-activation-wire-activate-1",
  ).unwrap()
  let pending_outbox = application.runtime_handoffs()
  guard pending_outbox is Object(pending_fields) &&
    json_array(pending_fields, "activationHandoffs").get(0) is Some(Object(pending)) else {
    fail("activation outbox must contain the queued handoff")
  }
  assert_eq(pending.get("expected_cursor"), Some((9 : Int).to_json()))
  assert_eq(pending.get("claimed_by"), Some(Json::null()))
  assert_eq(pending.get("runtime_command"), Some(Json::null()))
  guard pending.get("payload") is Some(Object(payload)) &&
    payload.get("runtime_profile") is Some(Object(runtime_profile)) &&
    runtime_profile.get("identity") is Some(Object(runtime_identity)) &&
    runtime_profile.get("consent") is Some(Object(runtime_consent)) else {
    fail("activation wire must retain the canonical runtime profile")
  }
  assert_eq(
    runtime_identity.get("avatarUrl"),
    Some("avatar://moon-lantern".to_json()),
  )
  assert_eq(runtime_consent.get("confirmedAtMs"), Some(1000UL.to_json()))

  let activation_claim = application.claim_activation_handoff(
    "moondesk-wire",
    supervisor_test_json_string({
      "handoffId": queued_activation.handoff_id,
      "expectedCursor": 2,
      "evaluatedAt": "2026-08-01T00:00:01Z",
      "authority": supervisor_test_authority(
        queued_activation.request_digest,
      ),
    }),
  )
  guard activation_claim is Object(activation_claim_fields) &&
    activation_claim_fields.get("moonclawCommand") is Some(Object(activation_command)) else {
    fail("activation claim must expose the exact MoonClaw command")
  }
  assert_eq(
    activation_command.get("expected_cursor"),
    Some((9 : Int).to_json()),
  )

  let execution : SupervisorExecutionHandoff = {
    schema: "moontown.supervisor-execution-handoff.v2",
    handoff_id: "supervisor-execution-wire-child-stop-1",
    command_id: "wire-child-stop-1",
    request_digest: "sha256:" + "a".repeat(64),
    owner_user_id: "user-a",
    supervisor_profile_id: "supervisor-user-a",
    parent_run_id: "supervisor-run-1",
    target_run_id: Some("worker-run-1"),
    action: "child_stop",
    instruction: "Stop the bounded worker.",
    target_runtime: "moonclaw",
    command_kind: execution_command_kind("child_stop"),
    worker_task: None,
    worker_bounds: None,
    worker_bounds_source: "not_applicable",
    transport_request_digest: None,
    transport_endpoint: None,
    transport_request: None,
    runtime_command: None,
    expected_cursor: Some(12),
    status: "pending_transport",
    revision: 1,
    claimed_by: None,
    runtime_receipt: None,
    created_at_ms: 3000UL,
  }
  let after_activation_claim = application.load_store()
  application.save_store({
    ..after_activation_claim,
    cursor: 4,
    execution_handoffs: after_activation_claim.execution_handoffs + [execution],
  })
  let lifecycle_outbox = application.runtime_handoffs()
  guard lifecycle_outbox is Object(lifecycle_fields) &&
    json_array(lifecycle_fields, "executionHandoffs").get(0) is Some(Object(lifecycle)) else {
    fail("execution outbox must contain the lifecycle handoff")
  }
  assert_eq(
    lifecycle.get("target_run_id"),
    Some("worker-run-1".to_json()),
  )
  assert_eq(lifecycle.get("expected_cursor"), Some((12 : Int).to_json()))
  assert_eq(lifecycle.get("worker_task"), Some(Json::null()))
  assert_eq(lifecycle.get("worker_bounds"), Some(Json::null()))

  let transport_request : Json = {
    "supervisor_id": execution.supervisor_profile_id,
    "worker_run_id": "worker-run-1",
    "force": false,
    "reason": execution.instruction,
  }
  let transport_digest = sha256_json(transport_request)
  let execution_claim = application.claim_execution_handoff(
    "moondesk-wire",
    supervisor_test_json_string({
      "handoffId": execution.handoff_id,
      "expectedCursor": 4,
      "sourceRequestDigest": execution.request_digest,
      "transportRequestDigest": transport_digest,
      "transportEndpoint": "worker-stop",
      "transportRequest": transport_request,
      "runtimeCommand": supervisor_test_runtime_command(
        execution,
        transport_request,
        transport_digest,
      ),
    }),
  )
  guard execution_claim is Object(execution_claim_fields) &&
    execution_claim_fields.get("executionHandoff") is Some(Object(claimed_execution)) else {
    fail("execution claim must expose the canonical lifecycle handoff")
  }
  assert_eq(
    claimed_execution.get("target_run_id"),
    Some("worker-run-1".to_json()),
  )
  assert_eq(
    claimed_execution.get("transport_endpoint"),
    Some("worker-stop".to_json()),
  )
  assert_eq(
    claimed_execution.get("claimed_by"),
    Some("moondesk-wire".to_json()),
  )
  assert_eq(
    claimed_execution.get("expected_cursor"),
    Some((12 : Int).to_json()),
  )

  let review : BookkeeperExactReviewRequest = {
    schema: "moonbook/bookkeeper-product-outcome-submission@1.0.0",
    request_id: "bookkeeper-wire-review-1",
    owner_user_id: "user-a",
    run_id: "worker-run-1",
    state: "pending_bookkeeper",
    product_outcome_submission: { "contract_version": "fixture" },
    source_outcome_digest: "sha256:" + "b".repeat(64),
    review_intent: { "schema": "fixture" },
    revision: 1,
    claimed_by: None,
    resume_state: None,
    bookkeeper_receipt: None,
    created_at_ms: 4000UL,
  }
  let after_execution_claim = application.load_store()
  application.save_store({
    ..after_execution_claim,
    review_requests: after_execution_claim.review_requests + [review],
  })
  let review_outbox = application.bookkeeper_outbox()
  guard review_outbox is Object(review_fields) &&
    json_array(review_fields, "requests").get(0) is Some(Object(projected_review)) else {
    fail("Bookkeeper outbox must contain the pending exact review")
  }
  assert_eq(projected_review.get("claimed_by"), Some(Json::null()))
  assert_eq(projected_review.get("resume_state"), Some(Json::null()))
  assert_eq(projected_review.get("bookkeeper_receipt"), Some(Json::null()))
  let review_claim = application.claim_bookkeeper_review(
    "moondesk-wire",
    supervisor_test_json_string({
      "requestId": review.request_id,
      "expectedCursor": 5,
    }),
  )
  guard review_claim is Object(review_claim_fields) else {
    fail("Bookkeeper claim must be an object")
  }
  assert_eq(
    review_claim_fields.get("resumeState"),
    Some("pending_bookkeeper".to_json()),
  )
}
