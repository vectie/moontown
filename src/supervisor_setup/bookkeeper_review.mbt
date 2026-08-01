///|
fn latest_review_request(
  store : SupervisorSetupStore,
  request_id : String,
) -> BookkeeperExactReviewRequest? {
  let mut latest : BookkeeperExactReviewRequest? = None
  for request in store.review_requests {
    if request.request_id == request_id &&
      latest.map(item => item.revision < request.revision).unwrap_or(true) {
      latest = Some(request)
    }
  }
  latest
}

///|
fn bookkeeper_human_gate_state(state : String) -> Bool {
  state == "deliverable_review_required" ||
  state == "assessment_review_required" ||
  state == "proposal_review_required"
}

///|
fn bookkeeper_terminal_state(state : String) -> Bool {
  state == "closed_no_capability_change" ||
  state == "reviewed_proposal_handed_off" ||
  state == "deliverable_rejected" ||
  state == "assessment_rejected" ||
  state == "proposal_rejected"
}

///|
fn bookkeeper_receipt_state_allowed(state : String) -> Bool {
  bookkeeper_human_gate_state(state) || bookkeeper_terminal_state(state)
}

///|
fn bookkeeper_projection_state(state : String) -> String {
  if bookkeeper_human_gate_state(state) {
    "pending_human_gate"
  } else {
    state
  }
}

///|
fn review_response(
  store : SupervisorSetupStore,
  request : BookkeeperExactReviewRequest,
) -> Json {
  {
    "ok": true,
    "cursor": store.cursor,
    "requestId": request.request_id,
    "reviewState": request.state,
    "projectionState": bookkeeper_projection_state(request.state),
    "pendingHumanGate": bookkeeper_human_gate_state(request.state),
    "acceptedMemoryChanged": false,
  }
}

///|
fn review_receipt_seen(
  store : SupervisorSetupStore,
  request_id : String,
  receipt : Json,
) -> Bool {
  store.review_requests.any(request => {
    request.request_id == request_id &&
    request.bookkeeper_receipt == Some(receipt)
  })
}

///|
fn runtime_observed_review_ready_submission(
  store : SupervisorSetupStore,
  supervisor_profile_id : String,
  run_id : String,
  submission : Json,
) -> Bool {
  guard latest_runtime_observation(store, supervisor_profile_id)
    is Some(observation) &&
    observation.status_projection is Object(status_fields) else {
    return false
  }
  for worker in json_array(status_fields, "workers") {
    guard worker is Object(worker_fields) else { continue }
    if json_string(worker_fields, "worker_run_id") == run_id &&
      json_string(worker_fields, "outcome_evidence_status") == "review_ready" &&
      !json_string(worker_fields, "outcome_source_event_id").is_empty() &&
      worker_fields.get("outcome_evidence_candidate") == Some(submission) {
      return true
    }
  }
  false
}

///|
pub async fn SupervisorSetupApplication::request_bookkeeper_review(
  self : SupervisorSetupApplication,
  actor_user_id : String,
  body : String,
  now_ms~ : UInt64,
) -> Json {
  let parsed = @json.parse(body)
  guard parsed is Object(fields) else {
    fail("review decision body must be an object")
  }
  let command_id = json_string_alias(fields, "commandId", "command_id")
  let run_id = json_string_alias(fields, "runId", "run_id")
  let decision = json_string(fields, "decision").to_lower()
  let summary = json_string(fields, "summary")
  let expected_cursor = json_int_alias(
    fields, "expectedCursor", "expected_cursor",
  )
  let outcome_submission = match fields.get("outcomeSubmission") {
    Some(value) => value
    None => fields.get("product_outcome_submission").unwrap_or(Json::null())
  }
  if command_id.is_empty() ||
    run_id.is_empty() ||
    summary.is_empty() ||
    expected_cursor < 0 ||
    !(decision == "request_review" || decision == "request_bookkeeper_review") ||
    outcome_submission == Json::null() {
    fail(
      "Bookkeeper review request requires an exact MoonClaw outcomeSubmission",
    )
  }
  guard outcome_submission is Object(outcome_fields) else {
    fail("MoonClaw outcomeSubmission must be an object")
  }
  let exact_submission_ref = json_object(outcome_fields, "submission")
  let exact_evidence = match outcome_fields.get("evidence_refs") {
    Some(Array(values)) => values
    _ => []
  }
  if json_string(outcome_fields, "contract_version") !=
    "moonbook.bookkeeper.product_outcome_submission.v1" ||
    json_string(outcome_fields, "source_product") != "moonclaw" ||
    json_string(exact_submission_ref, "record_id").is_empty() ||
    json_string(exact_submission_ref, "record_version").is_empty() ||
    json_string(exact_submission_ref, "record_digest").is_empty() ||
    exact_evidence.is_empty() {
    fail(
      "review requires MoonClaw's exact evidence-bound ProductOutcomeSubmission",
    )
  }
  for evidence in exact_evidence {
    guard evidence is Object(evidence_fields) &&
      !json_string(evidence_fields, "reference_id").is_empty() &&
      !json_string(evidence_fields, "reference_version").is_empty() &&
      !json_string(evidence_fields, "digest").is_empty() &&
      !json_string(evidence_fields, "provenance_ref").is_empty() else {
      fail("MoonClaw outcome evidence reference is incomplete")
    }
  }
  supervisor_store_mutex.acquire()
  defer supervisor_store_mutex.release()
  let store = self.load_store()
  let normalized : Json = {
    "actorUserId": actor_user_id,
    "commandId": command_id,
    "runId": run_id,
    "decision": decision,
    "summary": summary,
    "expectedCursor": expected_cursor,
    "outcomeSubmissionDigest": sha256_json(outcome_submission),
  }
  let request_digest = sha256_json(normalized)
  match
    idempotent_response(
      store, actor_user_id, command_id, "review.request", request_digest,
    ) {
    Some(response) => return response
    None => ()
  }
  if store.cursor != expected_cursor {
    fail("supervisor setup cursor conflict")
  }
  let profile = latest_profile_for_owner(store, actor_user_id).unwrap_or_else(() => {
    fail("supervisor profile does not exist")
  })
  if !profile.ready() || profile.authority_ceiling != RequestBookkeeperReview {
    fail("supervisor lacks consent or authority to request Bookkeeper review")
  }
  if !runtime_observed_review_ready_submission(
      store,
      profile.profile_id,
      run_id,
      outcome_submission,
    ) {
    fail(
      "Bookkeeper review requires the exact review_ready child outcome observed from MoonClaw",
    )
  }
  let request_id = "bookkeeper-product-outcome-\{command_id}"
  let review_intent : Json = {
    "schema": "moontown.run-review-intent.v1",
    "request_id": request_id,
    "run_id": run_id,
    "actor_user_id": actor_user_id,
    "supervisor_profile_id": profile.profile_id,
    "supervisor_profile_version": profile.revision,
    "decision": "request_bookkeeper_acceptance",
    "summary": summary,
    "recorded_at": now_ms,
  }
  let source_outcome_digest = sha256_json(outcome_submission)
  let request : BookkeeperExactReviewRequest = {
    schema: "moonbook/bookkeeper-product-outcome-submission@1.0.0",
    request_id,
    owner_user_id: actor_user_id,
    run_id,
    state: "pending_bookkeeper",
    product_outcome_submission: outcome_submission,
    source_outcome_digest,
    review_intent,
    revision: 1,
    claimed_by: None,
    resume_state: None,
    bookkeeper_receipt: None,
    created_at_ms: now_ms,
  }
  let next_cursor = store.cursor + 1
  let updated = {
    ..store,
    cursor: next_cursor,
    review_requests: store.review_requests + [request],
    audit_events: store.audit_events +
    [
      {
        event_id: "audit-\{command_id}",
        command_id,
        actor_user_id,
        action: "bookkeeper.outcome.submit.requested",
        object_id: run_id,
        from_revision: profile.revision,
        to_revision: profile.revision,
        cursor: next_cursor,
        recorded_at_ms: now_ms,
      },
    ],
  }
  let response : Json = {
    "ok": true,
    "schema": "moontown.bookkeeper-review-response.v1",
    "cursor": next_cursor,
    "runId": run_id,
    "requestId": request_id,
    "reviewState": "pending_bookkeeper",
    "projectionState": "pending_bookkeeper",
    "pendingHumanGate": false,
    "bookkeeperOperation": "bookkeeper.outcome.submit",
    "acceptedMemoryChanged": false,
  }
  self.save_store(
    append_idempotency(
      updated, actor_user_id, command_id, "review.request", request_digest, response,
    ),
  )
  response
}

///|
pub async fn SupervisorSetupApplication::bookkeeper_outbox(
  self : SupervisorSetupApplication,
) -> Json {
  let store = self.load_store()
  let requests : Array[Json] = []
  let seen : Array[String] = []
  for request in store.review_requests.rev() {
    if !seen.contains(request.request_id) {
      seen.push(request.request_id)
      let projected = bookkeeper_review_request_wire_json(request)
      guard projected is Object(request_fields) else { continue }
      request_fields["projection_state"] = bookkeeper_projection_state(
        request.state,
      ).to_json()
      request_fields["pending_human_gate"] = bookkeeper_human_gate_state(
        request.state,
      ).to_json()
      requests.push(Json::object(request_fields))
    }
  }
  {
    "ok": true,
    "schema": "moontown.bookkeeper-outbox.v1",
    "cursor": store.cursor,
    "requests": requests.to_json(),
  }
}

///|
pub async fn SupervisorSetupApplication::claim_bookkeeper_review(
  self : SupervisorSetupApplication,
  transport_id : String,
  body : String,
) -> Json {
  supervisor_store_mutex.acquire()
  defer supervisor_store_mutex.release()
  let parsed = @json.parse(body)
  guard parsed is Object(fields) else {
    fail("Bookkeeper claim body must be an object")
  }
  let request_id = json_string_alias(fields, "requestId", "request_id")
  let expected_cursor = json_int_alias(
    fields, "expectedCursor", "expected_cursor",
  )
  let store = self.load_store()
  let current = latest_review_request(store, request_id).unwrap_or_else(() => {
    fail("Bookkeeper review request not found")
  })
  if current.state == "claimed_for_transport" &&
    current.claimed_by == Some(transport_id) {
    return {
      "ok": true,
      "cursor": store.cursor,
      "requestId": request_id,
      "state": current.state,
      "resumeState": wire_string_or_null(current.resume_state),
      "projectionState": current.resume_state
      .map(bookkeeper_projection_state)
      .unwrap_or("claimed_for_transport"),
      "operation": "bookkeeper.outcome.submit",
      "submission": current.product_outcome_submission,
    }
  }
  if store.cursor != expected_cursor {
    fail("supervisor setup cursor conflict")
  }
  if current.state != "pending_bookkeeper" &&
    !bookkeeper_human_gate_state(current.state) {
    fail(
      "Bookkeeper review request is not pending transport or human-gate replay",
    )
  }
  let claimed = {
    ..current,
    state: "claimed_for_transport",
    revision: current.revision + 1,
    claimed_by: Some(transport_id),
    resume_state: Some(current.state),
  }
  let next = {
    ..store,
    cursor: store.cursor + 1,
    review_requests: store.review_requests + [claimed],
  }
  self.save_store(next)
  {
    "ok": true,
    "cursor": next.cursor,
    "requestId": request_id,
    "state": claimed.state,
    "resumeState": wire_string_or_null(claimed.resume_state),
    "projectionState": claimed.resume_state
    .map(bookkeeper_projection_state)
    .unwrap_or("claimed_for_transport"),
    "operation": "bookkeeper.outcome.submit",
    "submission": claimed.product_outcome_submission,
  }
}

///|
pub async fn SupervisorSetupApplication::reconcile_bookkeeper_review(
  self : SupervisorSetupApplication,
  transport_id : String,
  body : String,
) -> Json {
  supervisor_store_mutex.acquire()
  defer supervisor_store_mutex.release()
  let parsed = @json.parse(body)
  guard parsed is Object(fields) else {
    fail("Bookkeeper reconcile body must be an object")
  }
  let request_id = json_string_alias(fields, "requestId", "request_id")
  let expected_cursor = json_int_alias(
    fields, "expectedCursor", "expected_cursor",
  )
  let receipt = fields.get("receipt").unwrap_or(Json::null())
  guard receipt is Object(receipt_fields) else {
    fail("Bookkeeper receipt is required")
  }
  let store = self.load_store()
  let current = latest_review_request(store, request_id).unwrap_or_else(() => {
    fail("Bookkeeper review request not found")
  })
  if current.state == "claimed_for_transport" &&
    current.claimed_by == Some(transport_id) &&
    current.bookkeeper_receipt == Some(receipt) {
    if store.cursor != expected_cursor {
      fail("supervisor setup cursor conflict")
    }
    let resume_state = current.resume_state.unwrap_or("pending_bookkeeper")
    if !bookkeeper_human_gate_state(resume_state) {
      fail("exact Bookkeeper receipt replay cannot resume an unknown gate")
    }
    let released = {
      ..current,
      state: resume_state,
      revision: current.revision + 1,
      claimed_by: None,
      resume_state: None,
    }
    let next = {
      ..store,
      cursor: store.cursor + 1,
      review_requests: store.review_requests + [released],
    }
    self.save_store(next)
    return review_response(next, released)
  }
  if review_receipt_seen(store, request_id, receipt) &&
    current.state != "claimed_for_transport" {
    return review_response(store, current)
  }
  if store.cursor != expected_cursor {
    fail("supervisor setup cursor conflict")
  }
  if current.claimed_by != Some(transport_id) ||
    current.state != "claimed_for_transport" {
    fail("transport does not own the claimed Bookkeeper review request")
  }
  guard current.product_outcome_submission is Object(submission_fields) else {
    fail("stored Bookkeeper submission is invalid")
  }
  let expected_submission = json_object(submission_fields, "submission")
  let receipt_submission = json_object(receipt_fields, "submission")
  if json_string(expected_submission, "record_id") !=
    json_string(receipt_submission, "record_id") ||
    json_string(expected_submission, "record_version") !=
    json_string(receipt_submission, "record_version") ||
    json_string(expected_submission, "record_digest") !=
    json_string(receipt_submission, "record_digest") {
    fail(
      "Bookkeeper receipt does not replay the exact product outcome submission",
    )
  }
  let state = json_string(receipt_fields, "state")
  if !bookkeeper_receipt_state_allowed(state) {
    fail(
      "Bookkeeper receipt state must be an exact human gate or terminal state",
    )
  }
  let reconciled = {
    ..current,
    state,
    revision: current.revision + 1,
    claimed_by: None,
    resume_state: None,
    bookkeeper_receipt: Some(receipt),
  }
  let next = {
    ..store,
    cursor: store.cursor + 1,
    review_requests: store.review_requests + [reconciled],
  }
  self.save_store(next)
  review_response(next, reconciled)
}
