///|
/// MoonBit's derived `ToJson` representation for `Option` is an internal
/// persistence detail. External contracts require the contained scalar/object
/// directly, or JSON null when the value is absent.
fn wire_string_or_null(value : String?) -> Json {
  match value {
    Some(item) => item.to_json()
    None => Json::null()
  }
}

///|
fn wire_int_or_null(value : Int?) -> Json {
  match value {
    Some(item) => item.to_json()
    None => Json::null()
  }
}

///|
fn wire_uint64_or_null(value : UInt64?) -> Json {
  match value {
    Some(item) => item.to_json()
    None => Json::null()
  }
}

///|
fn wire_json_or_null(value : Json?) -> Json {
  match value {
    Some(item) => item
    None => Json::null()
  }
}

///|
fn supervisor_worker_task_wire_json(task : SupervisorWorkerTask) -> Json {
  {
    "task_id": task.task_id,
    "conversation_id": task.conversation_id,
    "title": task.title,
    "cwd": task.cwd,
    "model": task.model,
    "web_search": task.web_search,
    "metadata": task.metadata,
  }
}

///|
fn supervisor_worker_task_wire_or_null(
  task : SupervisorWorkerTask?,
) -> Json {
  match task {
    Some(item) => supervisor_worker_task_wire_json(item)
    None => Json::null()
  }
}

///|
fn supervisor_worker_budget_wire_json(
  budget : SupervisorWorkerBudget,
) -> Json {
  {
    "max_cost_micro_usd": budget.max_cost_micro_usd,
    "max_runtime_ms": budget.max_runtime_ms,
    "max_tokens": budget.max_tokens,
    "max_artifacts": budget.max_artifacts,
  }
}

///|
fn supervisor_worker_bounds_wire_json(
  bounds : SupervisorWorkerBounds,
) -> Json {
  {
    "claim_ceiling": bounds.claim_ceiling,
    "budget": supervisor_worker_budget_wire_json(bounds.budget),
    "artifact_prefixes": bounds.artifact_prefixes,
    "expires_at": bounds.expires_at,
  }
}

///|
fn supervisor_worker_bounds_wire_or_null(
  bounds : SupervisorWorkerBounds?,
) -> Json {
  match bounds {
    Some(item) => supervisor_worker_bounds_wire_json(item)
    None => Json::null()
  }
}

///|
fn supervisor_activation_payload_wire_json(
  payload : SupervisorProfileActivationPayload,
) -> Json {
  {
    "contract_id": payload.contract_id,
    "supervisor_id": payload.supervisor_id,
    "profile_id": payload.profile_id,
    "profile_version": payload.profile_version,
    "profile_digest": payload.profile_digest,
    "source_product": payload.source_product,
    "runtime_profile": payload.runtime_profile,
    "runtime_binding": payload.runtime_binding,
    "activated_at": payload.activated_at,
  }
}

///|
fn supervisor_activation_handoff_wire_json(
  handoff : SupervisorActivationHandoff,
) -> Json {
  {
    "schema": handoff.schema,
    "handoff_id": handoff.handoff_id,
    "owner_user_id": handoff.owner_user_id,
    "target_runtime": handoff.target_runtime,
    "payload_schema": handoff.payload_schema,
    "payload": supervisor_activation_payload_wire_json(handoff.payload),
    "command_id": handoff.command_id,
    "request_digest": handoff.request_digest,
    "expected_cursor": wire_int_or_null(handoff.expected_cursor),
    "status": handoff.status,
    "revision": handoff.revision,
    "claimed_by": wire_string_or_null(handoff.claimed_by),
    "runtime_command": wire_json_or_null(handoff.runtime_command),
    "runtime_receipt": wire_json_or_null(handoff.runtime_receipt),
    "created_at_ms": handoff.created_at_ms,
  }
}

///|
fn supervisor_execution_handoff_wire_json(
  handoff : SupervisorExecutionHandoff,
) -> Json {
  {
    "schema": handoff.schema,
    "handoff_id": handoff.handoff_id,
    "command_id": handoff.command_id,
    "request_digest": handoff.request_digest,
    "owner_user_id": handoff.owner_user_id,
    "supervisor_profile_id": handoff.supervisor_profile_id,
    "parent_run_id": handoff.parent_run_id,
    "target_run_id": wire_string_or_null(handoff.target_run_id),
    "action": handoff.action,
    "instruction": handoff.instruction,
    "target_runtime": handoff.target_runtime,
    "command_kind": handoff.command_kind,
    "worker_task": supervisor_worker_task_wire_or_null(handoff.worker_task),
    "worker_bounds": supervisor_worker_bounds_wire_or_null(
      handoff.worker_bounds,
    ),
    "worker_bounds_source": handoff.worker_bounds_source,
    "transport_request_digest": wire_string_or_null(
      handoff.transport_request_digest,
    ),
    "transport_endpoint": wire_string_or_null(handoff.transport_endpoint),
    "transport_request": wire_json_or_null(handoff.transport_request),
    "runtime_command": wire_json_or_null(handoff.runtime_command),
    "expected_cursor": wire_int_or_null(handoff.expected_cursor),
    "status": handoff.status,
    "revision": handoff.revision,
    "claimed_by": wire_string_or_null(handoff.claimed_by),
    "runtime_receipt": wire_json_or_null(handoff.runtime_receipt),
    "created_at_ms": handoff.created_at_ms,
  }
}

///|
fn bookkeeper_review_request_wire_json(
  request : BookkeeperExactReviewRequest,
) -> Json {
  {
    "schema": request.schema,
    "request_id": request.request_id,
    "owner_user_id": request.owner_user_id,
    "run_id": request.run_id,
    "state": request.state,
    "product_outcome_submission": request.product_outcome_submission,
    "source_outcome_digest": request.source_outcome_digest,
    "review_intent": request.review_intent,
    "revision": request.revision,
    "claimed_by": wire_string_or_null(request.claimed_by),
    "resume_state": wire_string_or_null(request.resume_state),
    "bookkeeper_receipt": wire_json_or_null(request.bookkeeper_receipt),
    "created_at_ms": request.created_at_ms,
  }
}
