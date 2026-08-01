///| This adapter joins two existing MoonTown domains without creating another

///| runtime: marketplace owns request/decision state; supervisor_setup owns

///| the generic MoonClaw outbox and validated receipts.

///|
fn bridge_object(value : Json) -> Map[String, Json] raise {
  match value {
    Object(fields) => fields
    _ => fail("marketplace execution bridge expected an object")
  }
}

///|
fn bridge_string(fields : Map[String, Json], key : String) -> String {
  match fields.get(key) {
    Some(String(value)) => value
    _ => ""
  }
}

///|
fn bridge_int(fields : Map[String, Json], key : String) -> Int {
  match fields.get(key) {
    Some(Number(value, ..)) => value.to_int()
    _ => 0
  }
}

///|
fn bridge_int64(fields : Map[String, Json], key : String) -> Int64 {
  match fields.get(key) {
    Some(Number(value, ..)) => value.to_int64()
    Some(String(value)) => @string.parse_int64(value) catch { _ => 0L }
    _ => 0L
  }
}

///|
fn bridge_bool(fields : Map[String, Json], key : String) -> Bool {
  fields.get(key) is Some(True)
}

///|
fn bridge_strings(fields : Map[String, Json], key : String) -> Array[String] {
  match fields.get(key) {
    Some(Array(values)) =>
      values.filter_map(value => {
        match value {
          String(text) => Some(text)
          _ => None
        }
      })
    _ => []
  }
}

///|
fn bridge_action_request(result : Json) -> Map[String, Json] raise {
  let root = bridge_object(result)
  let payload = bridge_object(root.get("payload").unwrap_or(Json::null()))
  bridge_object(payload.get("action_request").unwrap_or(Json::null()))
}

///| Preserve a durable marketplace decision when the optional MoonClaw handoff
///| cannot start yet. Supervisor activation is a recoverable next step, not a
///| failed decision, so clients receive the accepted request and can offer the
///| existing retry action without displaying a false save error.
fn marketplace_pending_handoff_result(
  operation : String,
  marketplace_result : Json,
) -> Json raise {
  let root = bridge_object(marketplace_result)
  let payload = bridge_object(root.get("payload").unwrap_or(Json::null()))
  {
    "ok": true,
    "operation": operation,
    "payload": {
      "action_request": payload
      .get("action_request")
      .unwrap_or(Json::null()),
      "execution_handoff": Json::null(),
      "handoff_status": "supervisor_activation_required",
      "message": "The decision is saved. Activate a delegation-enabled supervisor, then retry the MoonClaw handoff.",
    },
  }
}

///|
fn bridge_profile_context(
  snapshot : Json,
) -> (Int, Int, Int, String, String, String, String) raise {
  let root = bridge_object(snapshot)
  let profile = bridge_object(root.get("profile").unwrap_or(Json::null()))
  let bindings = bridge_object(profile.get("bindings").unwrap_or(Json::null()))
  let readiness = bridge_object(root.get("readiness").unwrap_or(Json::null()))
  let book_ids = bridge_strings(bindings, "bookIds")
  let active_run_id = bridge_string(profile, "activeRunId")
  let town_cursor = bridge_int(root, "cursor")
  let runtime_cursor = bridge_int(profile, "runtimeCursor")
  let profile_version = bridge_int(profile, "revision")
  if !bridge_bool(readiness, "ready") ||
    active_run_id.is_empty() ||
    town_cursor <= 0 ||
    runtime_cursor < 0 ||
    profile_version <= 0 ||
    book_ids.length() != 1 {
    fail("publisher supervisor is not ready for bounded delegation")
  }
  (
    town_cursor,
    runtime_cursor,
    profile_version,
    active_run_id,
    bridge_string(bindings, "workspaceId"),
    bridge_string(bindings, "buildingId"),
    book_ids[0],
  )
}

///|
fn existing_marketplace_handoff(
  outbox : Json,
  command_id : String,
  publisher_id : String,
) -> Json? {
  let root = match outbox {
    Object(fields) => fields
    _ => return None
  }
  guard root.get("executionHandoffs") is Some(Array(handoffs)) else {
    return None
  }
  for handoff in handoffs.rev() {
    guard handoff is Object(fields) else { continue }
    if bridge_string(fields, "command_id") == command_id &&
      bridge_string(fields, "owner_user_id") == publisher_id &&
      bridge_string(fields, "action") == "delegate" {
      return Some(handoff)
    }
  }
  None
}

///|
fn marketplace_delegate_payload(
  request : Map[String, Json],
  snapshot : Json,
) -> Json raise {
  let (
    town_cursor,
    runtime_cursor,
    profile_version,
    active_run_id,
    workspace_id,
    building_id,
    book_id,
  ) = bridge_profile_context(snapshot)
  let bounds = bridge_object(
    request.get("execution_bounds").unwrap_or(Json::null()),
  )
  let request_id = bridge_string(request, "request_id")
  let action_id = bridge_string(request, "action_id")
  let listing_id = bridge_string(request, "listing_id")
  let instruction = bridge_string(request, "instruction")
  if request_id.is_empty() || action_id.is_empty() || instruction.is_empty() {
    fail("approved marketplace action is incomplete")
  }
  {
    "commandId": "marketplace-\{request_id}",
    "parentRunId": active_run_id,
    "expectedVersion": profile_version,
    "expectedCursor": town_cursor,
    "runtimeExpectedCursor": runtime_cursor,
    "instruction": instruction,
    "task": {
      "taskId": request_id,
      "conversationId": active_run_id,
      "title": "Marketplace \{action_id}: \{listing_id}",
      "cwd": "",
      "model": "gpt-5.6-sol",
      "webSearch": bridge_bool(bounds, "web_search"),
      "metadata": {
        "workspace_id": workspace_id,
        "building_id": building_id,
        "book_id": book_id,
        "marketplace_request_id": request_id,
        "marketplace_listing_id": listing_id,
        "marketplace_action_id": action_id,
      },
    },
    "scope": {
      "claimCeiling": bridge_string(bounds, "claim_ceiling"),
      "budget": {
        "maxCostMicroUsd": bridge_int64(bounds, "max_cost_micro_usd"),
        "maxRuntimeMs": bridge_int64(bounds, "max_runtime_ms"),
        "maxTokens": bridge_int64(bounds, "max_tokens"),
        "maxArtifacts": bridge_int(bounds, "max_artifacts"),
      },
      "artifactPrefixes": ["books/\{book_id}/artifacts"],
      "expiresAt": bridge_string(bounds, "expires_at"),
    },
  }
}

///|
async fn complete_marketplace_action_operation(
  operation : String,
  opaque_session : String,
  payload_text : String,
  marketplace_result : Json,
  now_ms~ : UInt64,
) -> Json {
  if operation == "decide-action-request" {
    let payload = bridge_object(@json.parse(payload_text))
    if bridge_string(payload, "decision").to_lower() != "accept" {
      return marketplace_result
    }
  }
  let request = bridge_action_request(marketplace_result)
  let publisher_id = bridge_string(request, "publisher_principal_id")
  let request_id = bridge_string(request, "request_id")
  let request_version = bridge_int(request, "version")
  if publisher_id.is_empty() || request_id.is_empty() || request_version <= 0 {
    fail("marketplace action decision lacks durable identity")
  }
  let supervisor = @supervisor_setup.default_supervisor_setup_application()
  let command_id = "marketplace-\{request_id}"
  let existing = existing_marketplace_handoff(
    supervisor.runtime_handoffs(),
    command_id,
    publisher_id,
  )
  let supervisor_result : Json = match existing {
    Some(handoff) => {
      let fields = bridge_object(handoff)
      let recovered : Json = {
        "ok": true,
        "handoffId": bridge_string(fields, "handoff_id"),
        "status": bridge_string(fields, "status"),
        "recovered": true,
      }
      recovered
    }
    None =>
      supervisor.request_run_delegate(
        publisher_id,
        marketplace_delegate_payload(
          request,
          supervisor.query_profile(publisher_id),
        ).stringify(),
        now_ms~,
      )
  }
  let supervisor_fields = bridge_object(supervisor_result)
  let handoff_id = bridge_string(supervisor_fields, "handoffId")
  if handoff_id.is_empty() {
    fail("supervisor did not return a durable execution handoff")
  }
  let bind_payload : Json = {
    "request_id": request_id,
    "expected_version": request_version,
    "handoff_id": handoff_id,
  }
  let bound = marketplace_application().execute(
    opaque_session,
    "bind-action-handoff",
    bind_payload.stringify(),
    "",
    now_ms~,
  )
  let bound_fields = bridge_object(bound)
  let response_payload = bridge_object(
    bound_fields.get("payload").unwrap_or(Json::null()),
  )
  {
    "ok": true,
    "operation": operation,
    "payload": {
      "action_request": response_payload
      .get("action_request")
      .unwrap_or(Json::null()),
      "execution_handoff": supervisor_result,
    },
  }
}

///|
async fn sync_marketplace_execution_receipt(
  request_body : String,
  supervisor_result : Json,
  now_ms~ : UInt64,
) -> Json {
  let request = bridge_object(@json.parse(request_body))
  let result = bridge_object(supervisor_result)
  let receipt = match request.get("receipt") {
    Some(Object(fields)) => fields
    _ => Map([])
  }
  let worker = match receipt.get("worker") {
    Some(Object(fields)) => fields
    _ => Map([])
  }
  let worker_status = bridge_string(worker, "execution_status")
  marketplace_application().reconcile_runtime_handoff(
    {
      handoff_id: bridge_string(result, "handoffId"),
      runtime_status: if worker_status.is_empty() {
        bridge_string(result, "status")
      } else {
        worker_status
      },
      worker_run_id: bridge_string(worker, "worker_run_id"),
      result_summary: bridge_string(worker, "summary"),
      result_evidence_refs: bridge_strings(worker, "artifact_refs"),
    },
    now_ms~,
  )
}

///|
async fn sync_marketplace_action_lineage(
  supervisor : @supervisor_setup.SupervisorSetupApplication,
  now_ms~ : UInt64,
) -> Json {
  let mut synced = 0
  for lineage in supervisor.execution_lineage_projection() {
    guard lineage is Object(fields) else { continue }
    let status = {
      let runtime = bridge_string(fields, "runtimeExecutionStatus")
      if runtime.is_empty() {
        bridge_string(fields, "status")
      } else {
        runtime
      }
    }
    let summary = match fields.get("summary") {
      Some(String(value)) => value
      _ =>
        match fields.get("error") {
          Some(String(value)) => value
          _ => ""
        }
    }
    let reconciled = marketplace_application().reconcile_runtime_handoff(
      {
        handoff_id: bridge_string(fields, "handoffId"),
        runtime_status: status,
        worker_run_id: bridge_string(fields, "runId"),
        result_summary: summary,
        result_evidence_refs: bridge_strings(fields, "artifactRefs"),
      },
      now_ms~,
    ) catch {
      _ => Json::null()
    }
    if reconciled != Json::null() {
      synced += 1
    }
  }
  { "ok": true, "synced": synced }
}
