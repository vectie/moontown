///|
fn latest_execution_handoff(
  store : SupervisorSetupStore,
  handoff_id : String,
) -> SupervisorExecutionHandoff? {
  let mut latest : SupervisorExecutionHandoff? = None
  for handoff in store.execution_handoffs {
    if handoff.handoff_id == handoff_id &&
      latest.map(item => item.revision < handoff.revision).unwrap_or(true) {
      latest = Some(handoff)
    }
  }
  latest
}

///|
fn execution_receipt_status_allowed(status : String) -> Bool {
  status == "accepted" || status == "rejected" || status == "failed"
}

///|
fn validate_execution_command_receipt(
  receipt_fields : Map[String, Json],
  current : SupervisorExecutionHandoff,
) -> String raise {
  let status = json_string(receipt_fields, "status")
  let expected_digest = current.transport_request_digest.unwrap_or("")
  if json_string(receipt_fields, "contract_id") !=
    "moonclaw.supervisor-command-receipt.v1" ||
    json_string(receipt_fields, "command_id") != current.command_id ||
    expected_digest.is_empty() ||
    json_string(receipt_fields, "request_digest") != expected_digest ||
    json_string(receipt_fields, "supervisor_id") !=
    current.supervisor_profile_id ||
    !execution_receipt_status_allowed(status) {
    fail("MoonClaw execution receipt does not match the exact command identity")
  }
  status
}

///|
fn worker_execution_status_allowed(status : String) -> Bool {
  status == "pending_provider" ||
  status == "running" ||
  status == "waiting_for_input" ||
  status == "succeeded" ||
  status == "failed" ||
  status == "cancelled"
}

///|
fn execution_transport_endpoint(action : String) -> String {
  match action {
    "message" => "message"
    "steer" => "steer"
    "delegate" => "delegate"
    "wake" => "wake"
    "supervisor_stop" => "stop"
    "supervisor_resume" => "retry-resume"
    "child_stop" => "worker-stop"
    "child_steer" => "worker-steer"
    "child_retry" => "worker-retry-resume"
    _ => ""
  }
}

///|
fn valid_sha256_digest(value : String) -> Bool {
  value.has_prefix("sha256:") && value.length() == 71
}

///|
fn validate_delegate_transport_request(
  request_fields : Map[String, Json],
  current : SupervisorExecutionHandoff,
) -> Unit raise {
  guard current.worker_task is Some(task) &&
    current.worker_bounds is Some(bounds) else {
    fail("delegate handoff has no durable bounded assignment")
  }
  let transport_task = json_object(request_fields, "task")
  let transport_metadata = json_object(transport_task, "metadata")
  let durable_metadata = match task.metadata {
    Object(fields) => fields
    _ => Map([])
  }
  let transport_scope = json_object(request_fields, "scope")
  let transport_budget = json_object(transport_scope, "budget")
  if json_string(request_fields, "instruction") != current.instruction ||
    json_string(transport_task, "task_id") != task.task_id ||
    json_string(transport_task, "conversation_id") != task.conversation_id ||
    json_string(transport_task, "title") != task.title ||
    !json_string(transport_task, "cwd").has_prefix("/") ||
    json_string(transport_task, "model") != task.model ||
    json_bool_alias(transport_task, "web_search", "web_search") !=
    task.web_search ||
    json_string(transport_metadata, "workspace_id") !=
    json_string_alias(durable_metadata, "workspaceId", "workspace_id") ||
    json_string(transport_metadata, "book_id") !=
    json_string_alias(durable_metadata, "bookId", "book_id") ||
    json_string(transport_scope, "claim_ceiling") != bounds.claim_ceiling ||
    json_string(transport_budget, "max_cost_micro_usd") !=
    bounds.budget.max_cost_micro_usd.to_string() ||
    json_string(transport_budget, "max_runtime_ms") !=
    bounds.budget.max_runtime_ms.to_string() ||
    json_string(transport_budget, "max_tokens") !=
    bounds.budget.max_tokens.to_string() ||
    json_int_alias(transport_budget, "max_artifacts", "max_artifacts") !=
    bounds.budget.max_artifacts ||
    json_strings_alias(
      transport_scope, "artifact_prefixes", "artifact_prefixes",
    ) !=
    bounds.artifact_prefixes ||
    json_string(transport_scope, "expires_at") != bounds.expires_at {
    fail(
      "transport delegate payload does not preserve the exact Town task and scope",
    )
  }
}

///|
fn validate_execution_transport_request(
  request : Json,
  current : SupervisorExecutionHandoff,
) -> Unit raise {
  guard request is Object(request_fields) else {
    fail("execution claim transportRequest must be an object")
  }
  if json_string(request_fields, "supervisor_id") !=
    current.supervisor_profile_id {
    fail("transport request supervisor identity does not match Town")
  }
  if current.action == "delegate" {
    validate_delegate_transport_request(request_fields, current)
  } else if current.action == "message" || current.action == "steer" {
    let message = json_object(request_fields, "message")
    if json_string(message, "content") != current.instruction ||
      json_string(message, "conversation_id") != current.parent_run_id {
      fail("transport message content does not match Town")
    }
  } else if current.action == "wake" {
    if json_string(request_fields, "run_id") != current.parent_run_id {
      fail("transport wake request does not target the active supervisor run")
    }
  } else if current.action == "supervisor_stop" {
    let reason = if current.instruction.is_blank() {
      "MoonTown requested cancellation of run \{current.parent_run_id}"
    } else {
      current.instruction
    }
    if json_string(request_fields, "reason") != reason ||
      request_fields.get("force") != Some(false.to_json()) {
      fail("transport supervisor stop request does not match Town")
    }
  } else if current.action == "supervisor_resume" {
    if json_string(request_fields, "action") != "Resume" {
      fail("transport supervisor resume request does not match Town")
    }
  } else if current.action == "child_steer" {
    let metadata = json_object(request_fields, "metadata")
    if json_string(request_fields, "worker_run_id") !=
      current.target_run_id.unwrap_or("") ||
      json_string(request_fields, "instruction") != current.instruction ||
      json_string(metadata, "source") != "moontown" ||
      json_string(metadata, "handoff_id") != current.handoff_id ||
      json_string(metadata, "parent_run_id") != current.parent_run_id ||
      json_string(metadata, "command_kind") != current.command_kind {
      fail("transport child-steer request does not match Town")
    }
  } else if current.action == "child_stop" {
    let reason = if current.instruction.is_blank() {
      "MoonTown requested bounded worker cancellation"
    } else {
      current.instruction
    }
    if json_string(request_fields, "worker_run_id") !=
      current.target_run_id.unwrap_or("") ||
      request_fields.get("force") != Some(false.to_json()) ||
      json_string(request_fields, "reason") != reason {
      fail("transport child stop request does not match Town")
    }
  } else if current.action == "child_retry" {
    let reason = if current.instruction.is_blank() {
      "MoonTown requested bounded worker retry"
    } else {
      current.instruction
    }
    if json_string(request_fields, "worker_run_id") !=
      current.target_run_id.unwrap_or("") ||
      json_string(request_fields, "reason") != reason {
      fail("transport child lifecycle request does not match Town")
    }
  }
}

///|
fn validate_optional_runtime_command(
  runtime_command : Json,
  current : SupervisorExecutionHandoff,
  transport_request : Json,
  transport_digest : String,
) -> Unit raise {
  if runtime_command == Json::null() {
    return
  }
  guard runtime_command is Object(command_fields) &&
    command_fields.get("envelope") is Some(Object(envelope_fields)) else {
    fail("runtimeCommand must contain an exact MoonClaw envelope")
  }
  let authority = json_object(envelope_fields, "authority")
  let principal = json_object(authority, "principal")
  let evaluated_at = json_string(envelope_fields, "evaluated_at")
  let authority_expires_at = json_string(authority, "expires_at")
  let operation_fields : Map[String, Json] = Map([])
  for key, value in command_fields {
    if key != "envelope" {
      operation_fields[key] = value
    }
  }
  if Json::object(operation_fields) != transport_request ||
    json_string(envelope_fields, "contract_id") !=
    "moonclaw.supervisor-command.v1" ||
    json_string(envelope_fields, "command_id") != current.command_id ||
    json_string(envelope_fields, "request_digest") != transport_digest ||
    json_string(envelope_fields, "issued_at") !=
    current.created_at_ms.to_string() ||
    evaluated_at.is_empty() ||
    envelope_fields.get("expected_cursor") !=
    Some(wire_int_or_null(current.expected_cursor)) ||
    !valid_moonclaw_authority(Json::object(authority)) ||
    json_string(authority, "digest") != transport_digest ||
    json_string(authority, "decided_at") != evaluated_at ||
    authority_expires_at <= evaluated_at ||
    json_string(principal, "contract_id") != "moonsuite.principal-ref.v1" ||
    json_string(principal, "principal_id") != "moonclaw-daemon" ||
    json_string(principal, "kind") != "service" ||
    json_string(principal, "issuer") != "moonclaw" ||
    json_string(principal, "subject") != "local-daemon" {
    fail("runtimeCommand envelope does not bind the exact transport request")
  }
}

///|
fn validate_delegate_result(
  value : Json,
  current : SupervisorExecutionHandoff,
) -> String raise {
  guard value is Object(result_fields) &&
    json_string(result_fields, "contract_id") ==
    "moonclaw.supervisor-delegate-intent-result.v1" &&
    result_fields.get("receipt") is Some(Object(receipt_fields)) &&
    result_fields.get("worker") is Some(Object(worker_fields)) else {
    fail(
      "delegate reconcile requires the exact MoonClaw delegate-intent result",
    )
  }
  let receipt_status = validate_execution_command_receipt(
    receipt_fields, current,
  )
  if receipt_status != "accepted" {
    fail(
      "MoonClaw delegate receipt must be accepted before worker lineage exists",
    )
  }
  let worker_run_id = json_string(worker_fields, "worker_run_id")
  let worker_job_id = json_string(worker_fields, "worker_job_id")
  let execution_status = json_string(worker_fields, "execution_status")
  if json_string(worker_fields, "contract_id") !=
    "moonclaw.supervisor-worker-status.v1" ||
    json_string(worker_fields, "supervisor_id") != current.supervisor_profile_id ||
    json_string(worker_fields, "parent_run_id") != current.parent_run_id ||
    worker_run_id.is_empty() ||
    worker_job_id.is_empty() ||
    !worker_execution_status_allowed(execution_status) {
    fail(
      "delegate result worker identity, parent lineage, or status is invalid",
    )
  }
  let response = json_object(receipt_fields, "response")
  if json_string(response, "worker_run_id") != worker_run_id ||
    json_string(response, "worker_job_id") != worker_job_id ||
    !worker_execution_status_allowed(json_string(response, "execution_status")) {
    fail("delegate receipt response must bind the same exact worker lineage")
  }
  let receipt_execution_status = json_string(response, "execution_status")
  let mut provider_transition_evidence = receipt_execution_status ==
    execution_status
  match result_fields.get("provider_receipt") {
    Some(Null) | None =>
      provider_transition_evidence = provider_transition_evidence ||
        receipt_fields.get("duplicate") == Some(true.to_json())
    Some(Object(provider_fields)) => {
      if json_string(provider_fields, "contract_id") !=
        "moonclaw.supervisor-command-receipt.v1" ||
        json_string(provider_fields, "supervisor_id") !=
        current.supervisor_profile_id ||
        json_string(provider_fields, "status") != "accepted" {
        fail(
          "delegate provider receipt is not an exact accepted MoonClaw receipt",
        )
      }
      let provider_response = json_object(provider_fields, "response")
      provider_transition_evidence = provider_transition_evidence ||
        (
          json_string(provider_response, "worker_run_id") == worker_run_id &&
          json_string(provider_response, "worker_job_id") == worker_job_id &&
          json_string(provider_response, "execution_status") == execution_status
        )
    }
    _ => fail("delegate provider_receipt must be an exact receipt or null")
  }
  if !provider_transition_evidence {
    fail(
      "delegate worker status transition lacks exact provider receipt evidence",
    )
  }
  execution_status
}

///|
pub async fn SupervisorSetupApplication::claim_execution_handoff(
  self : SupervisorSetupApplication,
  transport_id : String,
  body : String,
) -> Json {
  supervisor_store_mutex.acquire()
  defer supervisor_store_mutex.release()
  let parsed = @json.parse(body)
  guard parsed is Object(fields) else {
    fail("execution claim body must be an object")
  }
  let handoff_id = json_string_alias(fields, "handoffId", "handoff_id")
  let expected_cursor = json_int_alias(
    fields, "expectedCursor", "expected_cursor",
  )
  let source_request_digest = json_string_alias(
    fields, "sourceRequestDigest", "source_request_digest",
  )
  let transport_request_digest = json_string_alias(
    fields, "transportRequestDigest", "transport_request_digest",
  )
  let transport_endpoint = json_string_alias(
    fields, "transportEndpoint", "transport_endpoint",
  )
  let transport_request = match fields.get("transportRequest") {
    Some(value) => value
    None => fields.get("transport_request").unwrap_or(Json::null())
  }
  let runtime_command = match fields.get("runtimeCommand") {
    Some(value) => value
    None => fields.get("runtime_command").unwrap_or(Json::null())
  }
  let store = self.load_store()
  let current = latest_execution_handoff(store, handoff_id).unwrap_or_else(() => {
    fail("execution handoff not found")
  })
  if current.status == "claimed_for_transport" &&
    current.claimed_by == Some(transport_id) {
    if current.request_digest != source_request_digest ||
      current.transport_request_digest != Some(transport_request_digest) ||
      current.transport_endpoint != Some(transport_endpoint) ||
      current.transport_request != Some(transport_request) ||
      (
        runtime_command != Json::null() &&
        current.runtime_command != Some(runtime_command)
      ) {
      fail("execution transport retry does not match the stored exact mapping")
    }
    return {
      "ok": true,
      "cursor": store.cursor,
      "handoffId": current.handoff_id,
      "status": current.status,
      "executionHandoff": supervisor_execution_handoff_wire_json(current),
    }
  }
  if store.cursor != expected_cursor {
    fail("supervisor setup cursor conflict")
  }
  if current.status != "pending_transport" && current.status != "runtime_failed" {
    fail("execution handoff is not claimable")
  }
  if source_request_digest != current.request_digest ||
    !valid_sha256_digest(transport_request_digest) ||
    transport_endpoint != execution_transport_endpoint(current.action) ||
    sha256_json(transport_request) != transport_request_digest {
    fail(
      "execution transport source digest, endpoint, or request digest is invalid",
    )
  }
  if current.runtime_command is None && runtime_command == Json::null() {
    fail(
      "first execution claim requires the exact envelope-bearing runtimeCommand",
    )
  }
  validate_execution_transport_request(transport_request, current)
  validate_optional_runtime_command(
    runtime_command, current, transport_request, transport_request_digest,
  )
  match current.transport_request_digest {
    Some(previous) if previous != transport_request_digest ||
      current.transport_endpoint != Some(transport_endpoint) ||
      current.transport_request != Some(transport_request) =>
      fail("execution transport mapping cannot be replaced after release")
    _ => ()
  }
  if current.runtime_command is Some(previous_command) &&
    runtime_command != Json::null() &&
    runtime_command != previous_command {
    fail("execution runtime command cannot be replaced after release")
  }
  let claimed = {
    ..current,
    status: "claimed_for_transport",
    revision: current.revision + 1,
    claimed_by: Some(transport_id),
    transport_request_digest: Some(transport_request_digest),
    transport_endpoint: Some(transport_endpoint),
    transport_request: Some(transport_request),
    runtime_command: if runtime_command == Json::null() {
      current.runtime_command
    } else {
      Some(runtime_command)
    },
  }
  let next = {
    ..store,
    cursor: store.cursor + 1,
    execution_handoffs: store.execution_handoffs + [claimed],
  }
  self.save_store(next)
  {
    "ok": true,
    "cursor": next.cursor,
    "handoffId": claimed.handoff_id,
    "status": claimed.status,
    "executionHandoff": supervisor_execution_handoff_wire_json(claimed),
  }
}

///|
pub async fn SupervisorSetupApplication::reconcile_execution_handoff(
  self : SupervisorSetupApplication,
  transport_id : String,
  body : String,
) -> Json {
  supervisor_store_mutex.acquire()
  defer supervisor_store_mutex.release()
  let parsed = @json.parse(body)
  guard parsed is Object(fields) else {
    fail("execution reconcile body must be an object")
  }
  let handoff_id = json_string_alias(fields, "handoffId", "handoff_id")
  let expected_cursor = json_int_alias(
    fields, "expectedCursor", "expected_cursor",
  )
  let receipt = fields.get("receipt").unwrap_or(Json::null())
  let store = self.load_store()
  let current = latest_execution_handoff(store, handoff_id).unwrap_or_else(() => {
    fail("execution handoff not found")
  })
  match current.runtime_receipt {
    Some(previous) if previous == receipt =>
      return {
        "ok": true,
        "cursor": store.cursor,
        "handoffId": current.handoff_id,
        "status": current.status,
      }
    _ => ()
  }
  if store.cursor != expected_cursor {
    fail("supervisor setup cursor conflict")
  }
  if current.claimed_by != Some(transport_id) ||
    current.status != "claimed_for_transport" {
    fail("transport does not own the claimed execution handoff")
  }
  let acknowledged = if current.action == "delegate" {
    ignore(validate_delegate_result(receipt, current))
    true
  } else {
    guard receipt is Object(receipt_fields) else {
      fail("MoonClaw execution receipt is required")
    }
    validate_execution_command_receipt(receipt_fields, current) == "accepted"
  }
  let reconciled = {
    ..current,
    status: if acknowledged {
      "runtime_acknowledged"
    } else {
      "runtime_failed"
    },
    revision: current.revision + 1,
    runtime_receipt: Some(receipt),
  }
  let next = {
    ..store,
    cursor: store.cursor + 1,
    execution_handoffs: store.execution_handoffs + [reconciled],
  }
  self.save_store(next)
  {
    "ok": true,
    "cursor": next.cursor,
    "handoffId": handoff_id,
    "status": reconciled.status,
  }
}
