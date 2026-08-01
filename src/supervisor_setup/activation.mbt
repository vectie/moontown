///|
fn activation_request_json(
  actor_user_id : String,
  draft : SupervisorActivationDraft,
) -> Json {
  {
    "actorUserId": actor_user_id,
    "commandId": draft.command_id,
    "expectedVersion": draft.expected_version,
    "expectedCursor": draft.expected_cursor,
    "runtimeExpectedCursor": wire_int_or_null(draft.runtime_expected_cursor),
  }
}

///|
pub async fn SupervisorSetupApplication::activate_profile(
  self : SupervisorSetupApplication,
  actor_user_id : String,
  draft : SupervisorActivationDraft,
  now_ms~ : UInt64,
) -> Json {
  supervisor_store_mutex.acquire()
  defer supervisor_store_mutex.release()
  let store = self.load_store()
  let request_digest = sha256_json(
    activation_request_json(actor_user_id, draft),
  )
  match
    idempotent_response(
      store,
      actor_user_id,
      draft.command_id,
      "profile.activate",
      request_digest,
    ) {
    Some(response) => return response
    None => ()
  }
  if store.cursor != draft.expected_cursor {
    fail("supervisor setup cursor conflict")
  }
  let current = latest_profile_for_owner(store, actor_user_id).unwrap_or_else(() => {
    fail("supervisor profile does not exist")
  })
  if current.revision != draft.expected_version {
    fail("supervisor profile version conflict")
  }
  if !current.ready() {
    fail("supervisor profile is not ready or consent is incomplete")
  }
  let activation : SupervisorProfileActivationPayload = {
    contract_id: "moonsuite.supervisor-profile-activation.v1",
    supervisor_id: current.profile_id,
    profile_id: current.profile_id,
    profile_version: current.revision,
    profile_digest: current.content_digest,
    source_product: "moontown",
    runtime_profile: profile_content_json(current),
    runtime_binding: {
      "workspace_id": current.bindings.workspace_id,
      "building_id": current.bindings.building_id,
      "book_ids": current.bindings.book_ids.to_json(),
      "model": "gpt-5.6-sol",
      "max_active_workers": current.bindings.max_active_workers,
      "source_request_digest": request_digest,
    },
    activated_at: now_ms.to_string(),
  }
  let handoff_request_digest = sha256_json(
    supervisor_activation_payload_wire_json(activation),
  )
  let handoff : SupervisorActivationHandoff = {
    schema: "moontown.supervisor-activation-handoff.v1",
    handoff_id: "supervisor-activation-\{draft.command_id}",
    owner_user_id: actor_user_id,
    target_runtime: "moonclaw",
    payload_schema: activation.contract_id,
    payload: activation,
    command_id: draft.command_id,
    request_digest: handoff_request_digest,
    expected_cursor: draft.runtime_expected_cursor,
    status: "pending_transport",
    revision: 1,
    claimed_by: None,
    runtime_command: None,
    runtime_receipt: None,
    created_at_ms: now_ms,
  }
  let next_cursor = store.cursor + 1
  let updated = {
    ..store,
    cursor: next_cursor,
    profiles: store.profiles,
    activation_handoffs: store.activation_handoffs + [handoff],
    audit_events: store.audit_events +
    [
      {
        event_id: "audit-\{draft.command_id}",
        command_id: draft.command_id,
        actor_user_id,
        action: "supervisor.activation.requested",
        object_id: current.profile_id,
        from_revision: current.revision,
        to_revision: current.revision,
        cursor: next_cursor,
        recorded_at_ms: now_ms,
      },
    ],
  }
  let response : Json = {
    "ok": true,
    "schema": "moontown.supervisor-activation-response.v1",
    "cursor": next_cursor,
    "profile": supervisor_profile_projection(current),
    "activation": {
      "handoffId": handoff.handoff_id,
      "status": handoff.status,
      "targetRuntime": handoff.target_runtime,
      "requestDigest": handoff.request_digest,
    },
    "bookkeeperState": "not_requested",
  }
  self.save_store(
    append_idempotency(
      updated,
      actor_user_id,
      draft.command_id,
      "profile.activate",
      request_digest,
      response,
    ),
  )
  response
}

///|
fn latest_activation_handoff(
  store : SupervisorSetupStore,
  handoff_id : String,
) -> SupervisorActivationHandoff? {
  let mut latest : SupervisorActivationHandoff? = None
  for handoff in store.activation_handoffs {
    if handoff.handoff_id == handoff_id &&
      latest.map(item => item.revision < handoff.revision).unwrap_or(true) {
      latest = Some(handoff)
    }
  }
  latest
}

///|
fn valid_moonclaw_authority(value : Json) -> Bool {
  guard value is Object(fields) else { return false }
  let principal = json_object(fields, "principal")
  json_string(fields, "contract_id") == "moonsuite.authority-decision-ref.v1" &&
  !json_string(fields, "decision_id").is_empty() &&
  json_string(fields, "digest").has_prefix("sha256:") &&
  json_string(fields, "digest").length() == 71 &&
  !json_string(fields, "decided_at").is_empty() &&
  !json_string(fields, "expires_at").is_empty() &&
  json_string(principal, "contract_id") == "moonsuite.principal-ref.v1" &&
  !json_string(principal, "principal_id").is_empty() &&
  !json_string(principal, "kind").is_empty() &&
  !json_string(principal, "issuer").is_empty() &&
  !json_string(principal, "subject").is_empty()
}

///|
pub async fn SupervisorSetupApplication::runtime_handoffs(
  self : SupervisorSetupApplication,
) -> Json {
  let store = self.load_store()
  let activations : Array[Json] = []
  let seen : Array[String] = []
  for handoff in store.activation_handoffs.rev() {
    if !seen.contains(handoff.handoff_id) {
      seen.push(handoff.handoff_id)
      activations.push(supervisor_activation_handoff_wire_json(handoff))
    }
  }
  let executions : Array[Json] = []
  for handoff in store.execution_handoffs {
    executions.push(supervisor_execution_handoff_wire_json(handoff))
  }
  {
    "ok": true,
    "schema": "moontown.runtime-handoff-outbox.v1",
    "cursor": store.cursor,
    "activationHandoffs": activations.to_json(),
    "executionHandoffs": executions,
  }
}

///|
pub async fn SupervisorSetupApplication::claim_activation_handoff(
  self : SupervisorSetupApplication,
  transport_id : String,
  body : String,
) -> Json {
  supervisor_store_mutex.acquire()
  defer supervisor_store_mutex.release()
  let parsed = @json.parse(body)
  guard parsed is Object(fields) else { fail("claim body must be an object") }
  let handoff_id = json_string_alias(fields, "handoffId", "handoff_id")
  let expected_cursor = json_int_alias(
    fields, "expectedCursor", "expected_cursor",
  )
  let evaluated_at = json_string_alias(fields, "evaluatedAt", "evaluated_at")
  let authority = fields.get("authority").unwrap_or(Json::null())
  if handoff_id.is_empty() ||
    expected_cursor < 0 ||
    evaluated_at.is_empty() ||
    !valid_moonclaw_authority(authority) {
    fail(
      "claim requires handoffId, expectedCursor, evaluatedAt, and exact authority",
    )
  }
  let store = self.load_store()
  let current = latest_activation_handoff(store, handoff_id).unwrap_or_else(() => {
    fail("activation handoff not found")
  })
  if current.status == "claimed_for_transport" &&
    current.claimed_by == Some(transport_id) {
    return {
      "ok": true,
      "cursor": store.cursor,
      "handoffId": current.handoff_id,
      "status": current.status,
      "moonclawCommand": current.runtime_command.unwrap_or(Json::null()),
    }
  }
  if store.cursor != expected_cursor {
    fail("supervisor setup cursor conflict")
  }
  if current.status != "pending_transport" && current.status != "runtime_failed" {
    fail("activation handoff is not pending transport")
  }
  let command : Json = {
    "contract_id": "moonclaw.supervisor-command.v1",
    "command_id": current.command_id,
    "request_digest": current.request_digest,
    "issued_at": current.created_at_ms.to_string(),
    "expected_cursor": wire_int_or_null(current.expected_cursor),
    "authority": authority,
    "evaluated_at": evaluated_at,
    "profile": supervisor_activation_payload_wire_json(current.payload),
  }
  guard authority is Object(authority_fields) else {
    fail("MoonClaw authority must be an object")
  }
  if json_string(authority_fields, "digest") != current.request_digest {
    fail("MoonClaw authority digest must match the exact activation payload")
  }
  let claimed = {
    ..current,
    status: "claimed_for_transport",
    revision: current.revision + 1,
    claimed_by: Some(transport_id),
    runtime_command: Some(command),
  }
  let next = {
    ..store,
    cursor: store.cursor + 1,
    activation_handoffs: store.activation_handoffs + [claimed],
  }
  self.save_store(next)
  {
    "ok": true,
    "cursor": next.cursor,
    "handoffId": claimed.handoff_id,
    "status": claimed.status,
    "moonclawCommand": command,
  }
}

///|
pub async fn SupervisorSetupApplication::reconcile_activation_handoff(
  self : SupervisorSetupApplication,
  transport_id : String,
  body : String,
) -> Json {
  supervisor_store_mutex.acquire()
  defer supervisor_store_mutex.release()
  let parsed = @json.parse(body)
  guard parsed is Object(fields) else {
    fail("reconcile body must be an object")
  }
  let handoff_id = json_string_alias(fields, "handoffId", "handoff_id")
  let expected_cursor = json_int_alias(
    fields, "expectedCursor", "expected_cursor",
  )
  let receipt = fields.get("receipt").unwrap_or(Json::null())
  guard receipt is Object(receipt_fields) else {
    fail("MoonClaw receipt is required")
  }
  let store = self.load_store()
  let current = latest_activation_handoff(store, handoff_id).unwrap_or_else(() => {
    fail("activation handoff not found")
  })
  match current.runtime_receipt {
    Some(previous) if previous == receipt =>
      return {
        "ok": true,
        "cursor": store.cursor,
        "handoffId": current.handoff_id,
        "status": current.status,
        "bookkeeperState": "not_requested",
      }
    _ => ()
  }
  if store.cursor != expected_cursor {
    fail("supervisor setup cursor conflict")
  }
  if current.claimed_by != Some(transport_id) ||
    current.status != "claimed_for_transport" {
    fail("transport does not own the claimed activation handoff")
  }
  if json_string(receipt_fields, "command_id") != current.command_id ||
    json_string(receipt_fields, "request_digest") != current.request_digest {
    fail("MoonClaw receipt does not match the exact activation command")
  }
  let runtime_status = json_string(receipt_fields, "status")
  let response_fields = json_object(receipt_fields, "response")
  let response_profile = json_object(response_fields, "profile")
  let receipt_cursor = json_int_alias(receipt_fields, "cursor", "cursor")
  let response_cursor = json_int_alias(response_fields, "cursor", "cursor")
  if json_string(receipt_fields, "contract_id") !=
    "moonclaw.supervisor-command-receipt.v1" ||
    json_string(receipt_fields, "supervisor_id") !=
    current.payload.supervisor_id ||
    runtime_status != "accepted" ||
    json_string(response_fields, "contract_id") !=
    "moonclaw.supervisor-state.v1" ||
    json_string(response_fields, "supervisor_id") !=
    current.payload.supervisor_id ||
    json_string_alias(response_fields, "activeRunId", "active_run_id").is_empty() ||
    receipt_cursor < 0 ||
    response_cursor != receipt_cursor ||
    json_string_alias(response_profile, "profileId", "profile_id") !=
    current.payload.profile_id ||
    json_int_alias(response_profile, "profileVersion", "profile_version") !=
    current.payload.profile_version ||
    json_string_alias(response_profile, "profileDigest", "profile_digest") !=
    current.payload.profile_digest {
    fail("MoonClaw receipt must accept the exact activated profile identity")
  }
  let reconciled = {
    ..current,
    status: "runtime_acknowledged",
    revision: current.revision + 1,
    runtime_receipt: Some(receipt),
  }
  let next = {
    ..store,
    cursor: store.cursor + 1,
    activation_handoffs: store.activation_handoffs + [reconciled],
    profiles: store.profiles,
    audit_events: store.audit_events +
    [
      {
        event_id: "audit-reconcile-\{current.command_id}-\{current.revision}",
        command_id: current.command_id,
        actor_user_id: transport_id,
        action: "supervisor.activation.reconciled",
        object_id: current.payload.profile_id,
        from_revision: current.payload.profile_version,
        to_revision: current.payload.profile_version,
        cursor: store.cursor + 1,
        recorded_at_ms: current.created_at_ms,
      },
    ],
  }
  self.save_store(next)
  {
    "ok": true,
    "cursor": next.cursor,
    "handoffId": reconciled.handoff_id,
    "status": reconciled.status,
    "bookkeeperState": "not_requested",
    "profile": supervisor_profile_runtime_projection(
      latest_profile_for_owner(store, current.owner_user_id).unwrap(),
      Some(reconciled),
      latest_runtime_observation(store, current.payload.profile_id),
    ),
  }
}
