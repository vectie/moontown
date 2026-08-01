///|
pub async fn SupervisorSetupApplication::request_run_steer(
  self : SupervisorSetupApplication,
  actor_user_id : String,
  body : String,
  now_ms~ : UInt64,
) -> Json {
  self.request_run_action(actor_user_id, body, "steer", now_ms~)
}

///|
pub async fn SupervisorSetupApplication::request_message(
  self : SupervisorSetupApplication,
  actor_user_id : String,
  body : String,
  now_ms~ : UInt64,
) -> Json {
  self.request_run_action(actor_user_id, body, "message", now_ms~)
}

///|
pub async fn SupervisorSetupApplication::request_run_delegate(
  self : SupervisorSetupApplication,
  actor_user_id : String,
  body : String,
  now_ms~ : UInt64,
) -> Json {
  self.request_run_action(actor_user_id, body, "delegate", now_ms~)
}

///|
pub async fn SupervisorSetupApplication::request_supervisor_wake(
  self : SupervisorSetupApplication,
  actor_user_id : String,
  body : String,
  now_ms~ : UInt64,
) -> Json {
  self.request_run_action(actor_user_id, body, "wake", now_ms~)
}

///|
pub async fn SupervisorSetupApplication::request_supervisor_stop(
  self : SupervisorSetupApplication,
  actor_user_id : String,
  body : String,
  now_ms~ : UInt64,
) -> Json {
  self.request_run_action(actor_user_id, body, "supervisor_stop", now_ms~)
}

///|
pub async fn SupervisorSetupApplication::request_supervisor_resume(
  self : SupervisorSetupApplication,
  actor_user_id : String,
  body : String,
  now_ms~ : UInt64,
) -> Json {
  self.request_run_action(actor_user_id, body, "supervisor_resume", now_ms~)
}

///|
pub async fn SupervisorSetupApplication::request_run_cancel(
  self : SupervisorSetupApplication,
  actor_user_id : String,
  body : String,
  now_ms~ : UInt64,
) -> Json {
  self.request_run_action(actor_user_id, body, "child_stop", now_ms~)
}

///|
pub async fn SupervisorSetupApplication::request_child_run_steer(
  self : SupervisorSetupApplication,
  actor_user_id : String,
  body : String,
  now_ms~ : UInt64,
) -> Json {
  self.request_run_action(actor_user_id, body, "child_steer", now_ms~)
}

///|
pub async fn SupervisorSetupApplication::request_run_retry(
  self : SupervisorSetupApplication,
  actor_user_id : String,
  body : String,
  now_ms~ : UInt64,
) -> Json {
  self.request_run_action(actor_user_id, body, "child_retry", now_ms~)
}

///|
async fn SupervisorSetupApplication::request_run_action(
  self : SupervisorSetupApplication,
  actor_user_id : String,
  body : String,
  action : String,
  now_ms~ : UInt64,
) -> Json {
  let parsed = @json.parse(body)
  guard parsed is Object(fields) else {
    fail("supervisor execution body must be an object")
  }
  let command_id = json_string_alias(fields, "commandId", "command_id")
  let parent_run_id = json_string_alias(fields, "parentRunId", "parent_run_id")
  let requested_target_run_id = json_string_alias(
    fields, "targetRunId", "target_run_id",
  )
  let legacy_target_run_id = json_string_alias(fields, "runId", "run_id")
  let target_run_id = if requested_target_run_id.is_empty() {
    legacy_target_run_id
  } else {
    requested_target_run_id
  }
  let instruction = {
    let direct = json_string(fields, "instruction")
    if !direct.is_empty() {
      direct
    } else {
      let message = json_string(fields, "message")
      if message.is_empty() {
        json_string(fields, "body")
      } else {
        message
      }
    }
  }
  let expected_version = json_int_alias(
    fields, "expectedVersion", "expected_version",
  )
  let expected_cursor = json_int_alias(
    fields, "expectedCursor", "expected_cursor",
  )
  let runtime_expected_cursor = {
    let value = json_int_alias(
      fields, "runtimeExpectedCursor", "runtime_expected_cursor",
    )
    if value < 0 {
      None
    } else {
      Some(value)
    }
  }
  if command_id.is_empty() ||
    parent_run_id.is_empty() ||
    expected_version < 1 ||
    expected_cursor < 0 ||
    !execution_action_allowed(action) {
    fail(
      "supervisor execution requires commandId, parentRunId, instruction, expectedVersion, expectedCursor, and an exact bounded action",
    )
  }
  if (
      action == "message" ||
      action == "steer" ||
      action == "delegate" ||
      action == "child_steer"
    ) &&
    instruction.is_empty() {
    fail(
      "message, steer, delegate, and child_steer require a composed instruction",
    )
  }
  if (
      action == "child_stop" ||
      action == "child_steer" ||
      action == "child_retry"
    ) &&
    target_run_id.is_empty() {
    fail("child run control requires the receipt-backed targetRunId")
  }
  let (worker_task, worker_bounds, worker_bounds_source) = if action ==
    "delegate" {
    let (task, bounds, source) = parse_supervisor_worker_assignment(fields)
    (Some(task), Some(bounds), source)
  } else {
    (None, None, "not_applicable")
  }
  let durable_target_run_id = if action == "delegate" {
    None
  } else if target_run_id.is_empty() {
    Some(parent_run_id)
  } else {
    Some(target_run_id)
  }
  supervisor_store_mutex.acquire()
  defer supervisor_store_mutex.release()
  let store = self.load_store()
  let normalized : Json = {
    "actorUserId": actor_user_id,
    "commandId": command_id,
    "parentRunId": parent_run_id,
    "targetRunId": wire_string_or_null(durable_target_run_id),
    "action": action,
    "instruction": instruction,
    "task": supervisor_worker_task_wire_or_null(worker_task),
    "workerBounds": supervisor_worker_bounds_wire_or_null(worker_bounds),
    "workerBoundsSource": worker_bounds_source,
    "expectedVersion": expected_version,
    "expectedCursor": expected_cursor,
    "runtimeExpectedCursor": wire_int_or_null(runtime_expected_cursor),
  }
  let request_digest = sha256_json(normalized)
  let operation = "execution.\{action}"
  match
    idempotent_response(
      store, actor_user_id, command_id, operation, request_digest,
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
  if profile.revision != expected_version || !profile.ready() {
    fail("supervisor profile version is stale or not ready")
  }
  if profile.authority_ceiling == SuggestOnly &&
    action != "message" &&
    action != "steer" {
    fail(
      "suggest-only supervisors may message or steer, but cannot delegate or control child/external work",
    )
  }
  let activation = latest_activation_for_profile(store, profile.profile_id)
  let active_parent_run_id = activation_runtime_run_id(activation)
  if active_parent_run_id != Some(parent_run_id) {
    fail("parentRunId must be the exact receipt-backed active supervisor run")
  }
  let command_kind = execution_command_kind(action)
  let handoff : SupervisorExecutionHandoff = {
    schema: "moontown.supervisor-execution-handoff.v2",
    handoff_id: "supervisor-execution-\{command_id}",
    command_id,
    request_digest: sha256_json({
      "supervisor_profile_id": profile.profile_id,
      "parent_run_id": parent_run_id,
      "target_run_id": wire_string_or_null(durable_target_run_id),
      "action": action,
      "instruction": instruction,
      "command_kind": command_kind,
      "task": supervisor_worker_task_wire_or_null(worker_task),
      "worker_bounds": supervisor_worker_bounds_wire_or_null(worker_bounds),
      "worker_bounds_source": worker_bounds_source,
    }),
    owner_user_id: actor_user_id,
    supervisor_profile_id: profile.profile_id,
    parent_run_id,
    target_run_id: durable_target_run_id,
    action,
    instruction,
    target_runtime: "moonclaw",
    command_kind,
    worker_task,
    worker_bounds,
    worker_bounds_source,
    transport_request_digest: None,
    transport_endpoint: None,
    transport_request: None,
    runtime_command: None,
    expected_cursor: runtime_expected_cursor,
    status: "pending_transport",
    revision: 1,
    claimed_by: None,
    runtime_receipt: None,
    created_at_ms: now_ms,
  }
  let next_cursor = store.cursor + 1
  let updated = {
    ..store,
    cursor: next_cursor,
    execution_handoffs: store.execution_handoffs + [handoff],
    audit_events: store.audit_events +
    [
      {
        event_id: "audit-\{command_id}",
        command_id,
        actor_user_id,
        action: "supervisor.\{action}.requested",
        object_id: durable_target_run_id.unwrap_or(parent_run_id),
        from_revision: profile.revision,
        to_revision: profile.revision,
        cursor: next_cursor,
        recorded_at_ms: now_ms,
      },
    ],
  }
  let response : Json = {
    "ok": true,
    "schema": "moontown.supervisor-execution-response.v2",
    "cursor": next_cursor,
    "handoffId": handoff.handoff_id,
    "parentRunId": parent_run_id,
    "targetRunId": wire_string_or_null(durable_target_run_id),
    "action": action,
    "commandKind": command_kind,
    "task": supervisor_worker_task_wire_or_null(worker_task),
    "scope": supervisor_worker_bounds_wire_or_null(worker_bounds),
    "workerBoundsSource": worker_bounds_source,
    "status": handoff.status,
    "targetRuntime": handoff.target_runtime,
  }
  self.save_store(
    append_idempotency(
      updated, actor_user_id, command_id, operation, request_digest, response,
    ),
  )
  response
}
