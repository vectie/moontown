///|
fn profile_content_json(profile : SupervisorProfile) -> Json {
  {
    "schema": profile.schema,
    "profileId": profile.profile_id,
    "ownerUserId": profile.owner_user_id,
    "identity": {
      "displayName": profile.identity.display_name,
      "avatarUrl": wire_string_or_null(profile.identity.avatar_url),
    },
    "role": profile.role,
    "mission": profile.mission,
    "tone": profile.tone,
    "capabilities": profile.capabilities.to_json(),
    "bindings": {
      "workspaceId": profile.bindings.workspace_id,
      "buildingId": profile.bindings.building_id,
      "bookIds": profile.bindings.book_ids.to_json(),
      "maxActiveWorkers": profile.bindings.max_active_workers,
    },
    "authorityCeiling": profile.authority_ceiling.id(),
    "revision": profile.revision,
    "lifecycle": profile.lifecycle.id(),
    "consent": {
      "termsVersion": profile.consent.terms_version,
      "profileActivation": profile.consent.profile_activation,
      "runtimeDelegation": profile.consent.runtime_delegation,
      "bookkeeperReview": profile.consent.bookkeeper_review,
      "confirmedAtMs": wire_uint64_or_null(profile.consent.confirmed_at_ms),
    },
    "createdAtMs": profile.created_at_ms,
    "updatedAtMs": profile.updated_at_ms,
  }
}

///|
pub fn supervisor_profile_projection(profile : SupervisorProfile) -> Json {
  let content = profile_content_json(profile)
  guard content is Object(fields) else { return content }
  fields["contentDigest"] = profile.content_digest.to_json()
  // Runtime identity is evidence-backed and remains unknown until a reconciled
  // MoonClaw activation receipt is available.
  fields["activeRunId"] = Json::null()
  fields["runtimeCursor"] = Json::null()
  fields["runtimeEvidenceSource"] = Json::null()
  fields["readiness"] = {
    "ready": profile.ready(),
    "state": profile.lifecycle.id(),
    "consentComplete": profile.ready(),
  }
  Json::object(fields)
}

///|
fn apply_activation_runtime_projection(
  fields : Map[String, Json],
  activation : SupervisorActivationHandoff?,
) -> Unit {
  fields["activeRunId"] = Json::null()
  fields["runtimeCursor"] = Json::null()
  fields["runtimeEvidenceSource"] = Json::null()
  guard activation is Some(item) && activation_acknowledged_status(item.status) else {
    return
  }
  guard item.runtime_receipt is Some(Object(receipt)) &&
    json_string(receipt, "contract_id") ==
    "moonclaw.supervisor-command-receipt.v1" &&
    json_string(receipt, "status") == "accepted" else {
    return
  }
  let response = json_object(receipt, "response")
  let active_run_id = json_string_alias(
    response, "activeRunId", "active_run_id",
  )
  let receipt_cursor = json_int_alias(receipt, "cursor", "cursor")
  let response_cursor = json_int_alias(response, "cursor", "cursor")
  guard !active_run_id.is_empty() &&
    receipt_cursor >= 0 &&
    response_cursor == receipt_cursor else {
    return
  }
  fields["activeRunId"] = active_run_id.to_json()
  fields["runtimeCursor"] = receipt_cursor.to_json()
  fields["runtimeEvidenceSource"] = "moonclaw.supervisor-command-receipt.v1".to_json()
}

///|
fn activation_acknowledged_status(status : String) -> Bool {
  status == "runtime_acknowledged" ||
  status == "runtime_acknowledged_legacy_timestamp"
}

///|
fn supervisor_profile_runtime_projection(
  profile : SupervisorProfile,
  activation : SupervisorActivationHandoff?,
  observation : SupervisorRuntimeObservation?,
) -> Json {
  let projected = supervisor_profile_projection(profile)
  guard projected is Object(fields) else { return projected }
  apply_activation_runtime_projection(fields, activation)
  match observation {
    Some(item) => {
      fields["runtimeCursor"] = item.runtime_cursor.to_json()
      fields["runtimeEvidenceSource"] = item.schema.to_json()
    }
    None => ()
  }
  Json::object(fields)
}

///|
fn supervisor_profile_digest(profile : SupervisorProfile) -> String {
  sha256_json(profile_content_json(profile))
}

///|
fn latest_activation_for_profile(
  store : SupervisorSetupStore,
  profile_id : String,
) -> SupervisorActivationHandoff? {
  let mut latest : SupervisorActivationHandoff? = None
  for handoff in store.activation_handoffs {
    if handoff.payload.profile_id == profile_id &&
      latest.map(item => item.revision < handoff.revision).unwrap_or(true) {
      latest = Some(handoff)
    }
  }
  latest
}

///|
fn activation_runtime_run_id(
  activation : SupervisorActivationHandoff?,
) -> String? {
  guard activation is Some(item) &&
    activation_acknowledged_status(item.status) &&
    item.runtime_receipt is Some(Object(receipt)) &&
    json_string(receipt, "contract_id") ==
    "moonclaw.supervisor-command-receipt.v1" &&
    json_string(receipt, "status") == "accepted" else {
    return None
  }
  let response = json_object(receipt, "response")
  let run_id = json_string_alias(response, "activeRunId", "active_run_id")
  if run_id.is_empty() {
    None
  } else {
    Some(run_id)
  }
}

///|
fn activation_runtime_cursor(activation : SupervisorActivationHandoff?) -> Int? {
  guard activation is Some(item) &&
    activation_acknowledged_status(item.status) &&
    item.runtime_receipt is Some(Object(receipt)) else {
    return None
  }
  let cursor = json_int_alias(receipt, "cursor", "cursor")
  if cursor < 0 {
    None
  } else {
    Some(cursor)
  }
}

///|
fn profile_response(
  store : SupervisorSetupStore,
  profile : SupervisorProfile?,
) -> Json {
  match profile {
    None =>
      {
        "ok": true,
        "schema": "moontown.supervisor-profile-response.v1",
        "cursor": store.cursor,
        "profile": Json::null(),
        "readiness": { "ready": false, "state": "not_created" },
        "activation": Json::null(),
      }
    Some(value) => {
      let activation = latest_activation_for_profile(store, value.profile_id)
      let observation = latest_runtime_observation(store, value.profile_id)
      let conversation_history = runtime_conversation_history(
        store,
        value.profile_id,
      )
      let projected_state = match activation {
        Some(item) if activation_acknowledged_status(item.status) => "active"
        Some(item) if item.status == "runtime_failed" => "activation_failed"
        Some(_) => "pending_runtime"
        None => value.lifecycle.id()
      }
      {
        "ok": true,
        "schema": "moontown.supervisor-profile-response.v1",
        "cursor": store.cursor,
        "profile": supervisor_profile_runtime_projection(
          value, activation, observation,
        ),
        "readiness": { "ready": value.ready(), "state": projected_state },
        "activation": match activation {
          Some(item) =>
            {
              "handoffId": item.handoff_id,
              "status": item.status,
              "revision": item.revision,
            }
          None => Json::null()
        },
        "executionLineage": execution_lineage_projection_from_store(
          store,
          supervisor_profile_id=Some(value.profile_id),
        ).to_json(),
        "runtimeActivity": runtime_activity_projection(observation),
        "conversationHistory": conversation_history.to_json(),
        "assistantResponse": latest_runtime_assistant_response(
          conversation_history, observation,
        ),
      }
    }
  }
}

///|
fn runtime_activity_projection(
  observation : SupervisorRuntimeObservation?,
) -> Json {
  guard observation is Some(item) &&
    item.status_projection is Object(status_fields) &&
    status_fields.get("latest_event") is Some(event) &&
    event != Json::null() else {
    return Json::null()
  }
  {
    "event": event,
    "evidenceSource": item.schema,
    "runtimeCursor": item.runtime_cursor,
    "observationDigest": item.request_digest,
  }
}

///|
fn decimal_wire_string(value : String) -> Bool {
  if value.is_empty() {
    return false
  }
  for char in value {
    if char < '0' || char > '9' {
      return false
    }
  }
  true
}

///|
fn runtime_conversation_event(
  event : Json,
  supervisor_id : String,
  parent_run_id : String,
  evidence_source : String,
  observation_digest : String,
  runtime_cursor : Int,
) -> Json? {
  guard event is Object(event_fields) else { return None }
  let cursor = json_int_alias(event_fields, "cursor", "cursor")
  let event_id = json_string(event_fields, "event_id")
  let event_type = json_string(event_fields, "event_type")
  if cursor < 0 || event_id != "\{supervisor_id}:\{cursor}" {
    return None
  }
  let payload = json_object(event_fields, "payload")
  if event_type == "message.sent" || event_type == "supervisor.steered" {
    let message = json_object(payload, "message")
    let conversation_id = json_string(message, "conversation_id")
    let created_at = json_string(message, "created_at")
    if json_string(message, "message_id").is_empty() ||
      conversation_id != parent_run_id ||
      message.get("sender_ref") is None ||
      json_string(message, "content").is_empty() ||
      json_string(message, "content_type") != "text/plain" ||
      message.get("task_id") is None ||
      message.get("reply_to_message_id") is None ||
      message.get("metadata") is None ||
      !decimal_wire_string(created_at) {
      return None
    }
    return Some({
      "id": event_id,
      "eventId": event_id,
      "cursor": cursor,
      "role": "user",
      "eventType": event_type,
      "content": json_string(message, "content"),
      "contentType": "text/plain",
      "conversationId": conversation_id,
      "taskId": message.get("task_id").unwrap_or(Json::null()),
      "createdAt": created_at,
      "message": Json::object(message),
      "evidenceSource": evidence_source,
      "observationDigest": observation_digest,
      "runtimeCursor": runtime_cursor,
    })
  }
  if event_type == "supervisor.assistant.responded" {
    let response = json_object(payload, "assistant_response")
    let conversation_id = json_string(response, "conversation_id")
    let responded_at = json_string(response, "responded_at")
    if json_string(response, "contract_id") !=
      "moonclaw.supervisor-assistant-response.v1" ||
      json_string(response, "response_id").is_empty() ||
      json_string(response, "content").is_empty() ||
      json_string(response, "content_type") != "text/plain" ||
      conversation_id != parent_run_id ||
      response.get("task_id") is None ||
      json_string(response, "source_event_id").is_empty() ||
      json_string(response, "delivery_event_id").is_empty() ||
      json_string(response, "executor_run_id").is_empty() ||
      response.get("provider_evidence") is None ||
      !decimal_wire_string(responded_at) {
      return None
    }
    return Some({
      "id": event_id,
      "eventId": event_id,
      "cursor": cursor,
      "role": "assistant",
      "eventType": event_type,
      "content": json_string(response, "content"),
      "contentType": "text/plain",
      "conversationId": conversation_id,
      "taskId": response.get("task_id").unwrap_or(Json::null()),
      "createdAt": responded_at,
      "sourceEventId": json_string(response, "source_event_id"),
      "deliveryEventId": json_string(response, "delivery_event_id"),
      "message": Json::object(response),
      "evidenceSource": evidence_source,
      "observationDigest": observation_digest,
      "runtimeCursor": runtime_cursor,
    })
  }
  None
}

///| Conversation history is rebuilt only from reconciled MoonClaw replay

///| evidence. Events are append-ordered by the monotonic observations and

///|
/// de-duplicated by their canonical supervisor-id/cursor identity.
fn runtime_conversation_history(
  store : SupervisorSetupStore,
  supervisor_id : String,
) -> Array[Json] {
  let result : Array[Json] = []
  let seen : Array[String] = []
  for observation in store.runtime_observations {
    if observation.supervisor_profile_id != supervisor_id {
      continue
    }
    guard observation.event_replay is Object(replay_fields) else { continue }
    for event in json_array(replay_fields, "events") {
      match
        runtime_conversation_event(
          event,
          supervisor_id,
          observation.parent_run_id,
          observation.schema,
          observation.request_digest,
          observation.runtime_cursor,
        ) {
        Some(item) => {
          guard item is Object(fields) else { continue }
          let event_id = json_string(fields, "eventId")
          if !seen.contains(event_id) {
            seen.push(event_id)
            result.push(item)
          }
        }
        None => ()
      }
    }
  }
  result
}

///|
fn latest_runtime_assistant_response(
  history : Array[Json],
  observation : SupervisorRuntimeObservation?,
) -> Json {
  for item in history.rev() {
    guard item is Object(fields) && json_string(fields, "role") == "assistant" else {
      continue
    }
    return {
      "response": fields.get("message").unwrap_or(Json::null()),
      "evidenceSource": fields.get("evidenceSource").unwrap_or(Json::null()),
      "runtimeCursor": fields.get("runtimeCursor").unwrap_or(Json::null()),
      "observationDigest": fields
      .get("observationDigest")
      .unwrap_or(Json::null()),
    }
  }
  guard observation is Some(item) &&
    item.status_projection is Object(status_fields) &&
    status_fields.get("latest_event") is Some(event) &&
    runtime_conversation_event(
      event,
      item.supervisor_profile_id,
      item.parent_run_id,
      item.schema,
      item.request_digest,
      item.runtime_cursor,
    )
    is Some(Object(fields)) &&
    json_string(fields, "role") == "assistant" else {
    return Json::null()
  }
  return {
    "response": fields.get("message").unwrap_or(Json::null()),
    "evidenceSource": fields.get("evidenceSource").unwrap_or(Json::null()),
    "runtimeCursor": fields.get("runtimeCursor").unwrap_or(Json::null()),
    "observationDigest": fields.get("observationDigest").unwrap_or(Json::null()),
  }
}

///|
fn observed_supervisor_agent_status(
  observation : SupervisorRuntimeObservation?,
  fallback : String,
) -> String {
  guard observation is Some(item) &&
    item.status_projection is Object(status_fields) else {
    return fallback
  }
  let lifecycle = json_string(json_object(status_fields, "state"), "lifecycle").to_lower()
  if lifecycle == "running" || lifecycle == "active" {
    "running"
  } else if lifecycle == "waiting" || lifecycle == "waiting_for_input" {
    "waiting"
  } else if lifecycle == "failed" ||
    lifecycle == "error" ||
    lifecycle == "blocked" {
    "blocked"
  } else if lifecycle == "dormant" ||
    lifecycle == "stopped" ||
    lifecycle == "completed" ||
    lifecycle == "idle" {
    "idle"
  } else {
    "offline"
  }
}

///|
pub async fn SupervisorSetupApplication::query_profile(
  self : SupervisorSetupApplication,
  actor_user_id : String,
) -> Json {
  let store = self.load_store()
  profile_response(store, latest_profile_for_owner(store, actor_user_id))
}

///|
pub async fn SupervisorSetupApplication::supervisor_agents_projection(
  self : SupervisorSetupApplication,
) -> Array[Json] {
  let store = self.load_store()
  let agents : Array[Json] = []
  let seen : Array[String] = []
  for profile in store.profiles.rev() {
    if seen.contains(profile.owner_user_id) {
      continue
    }
    seen.push(profile.owner_user_id)
    let activation = latest_activation_for_profile(store, profile.profile_id)
    let observation = latest_runtime_observation(store, profile.profile_id)
    let activation_status = match activation {
      Some(item) if activation_acknowledged_status(item.status) => "running"
      Some(item) if item.status == "runtime_failed" => "blocked"
      Some(_) => "assigned"
      None => if profile.ready() { "idle" } else { "offline" }
    }
    let projected_status = observed_supervisor_agent_status(
      observation, activation_status,
    )
    let book_id = if profile.bindings.book_ids.is_empty() {
      None
    } else {
      Some(profile.bindings.book_ids[0])
    }
    let agent : Json = {
      "id": profile.profile_id,
      "name": profile.identity.display_name,
      "role": "keeper",
      "personaRole": profile.role,
      "avatarRef": if supervisor_avatar_allowed(profile.identity.avatar_url) {
        wire_string_or_null(profile.identity.avatar_url)
      } else {
        Json::null()
      },
      "avatarUrl": if supervisor_avatar_allowed(profile.identity.avatar_url) {
        wire_string_or_null(profile.identity.avatar_url)
      } else {
        Json::null()
      },
      "kind": "durable-supervisor",
      "durability": "user-owned-profile",
      "status": projected_status,
      "runtimeStatus": activation
      .map(item => item.status)
      .unwrap_or("not_requested"),
      "buildingId": profile.bindings.building_id,
      "buildingModuleKey": profile.bindings.building_id,
      "workspaceId": profile.bindings.workspace_id,
      "bookId": wire_string_or_null(book_id),
      "bookIds": profile.bindings.book_ids.to_json(),
      "capabilities": profile.capabilities.to_json(),
      "authorityCeiling": profile.authority_ceiling.id(),
      "profileRevision": profile.revision,
      "profileDigest": profile.content_digest,
      "activeRunId": Json::null(),
      "runId": Json::null(),
      "runtimeCursor": Json::null(),
      "runtimeEvidenceSource": Json::null(),
      "movement": Json::null(),
      "movementSource": "not_observed",
    }
    guard agent is Object(agent_fields) else { continue }
    apply_activation_runtime_projection(agent_fields, activation)
    match activation_runtime_run_id(activation) {
      Some(run_id) => agent_fields["runId"] = run_id.to_json()
      None => ()
    }
    match observation {
      Some(item) => {
        agent_fields["runtimeCursor"] = item.runtime_cursor.to_json()
        agent_fields["runtimeEvidenceSource"] = item.schema.to_json()
        guard item.status_projection is Object(status_fields) else {
          agents.push(Json::object(agent_fields))
          continue
        }
        match status_fields.get("latest_event") {
          Some(Null) | None => ()
          Some(event) => {
            agent_fields["activity"] = event
            agent_fields["activitySource"] = item.schema.to_json()
          }
        }
        agent_fields["runtimeStatus"] = json_string(
          json_object(status_fields, "state"),
          "lifecycle",
        ).to_json()
      }
      None => ()
    }
    agents.push(Json::object(agent_fields))
  }
  agents
}

///|
pub async fn SupervisorSetupApplication::execution_lineage_projection(
  self : SupervisorSetupApplication,
) -> Array[Json] {
  execution_lineage_projection_from_store(
    self.load_store(),
    supervisor_profile_id=None,
  )
}

///|
fn worker_agent_status(execution_status : String) -> String {
  match execution_status {
    "pending_provider" => "assigned"
    "running" => "running"
    "waiting_for_input" => "waiting"
    "failed" => "blocked"
    "cancelled" | "succeeded" => "idle"
    _ => "offline"
  }
}

///| Project only child identities proven by an exact delegate receipt. A

///| reconciled observation may advance status/evidence, but never invents

///|
/// lineage or movement.
pub async fn SupervisorSetupApplication::supervisor_worker_agents_projection(
  self : SupervisorSetupApplication,
) -> Array[Json] {
  let store = self.load_store()
  let agents : Array[Json] = []
  let seen : Array[String] = []
  for handoff in store.execution_handoffs.rev() {
    if handoff.action != "delegate" || seen.contains(handoff.handoff_id) {
      continue
    }
    seen.push(handoff.handoff_id)
    guard worker_from_delegate_receipt(handoff) is Some(receipt_worker) &&
      receipt_worker is Object(receipt_fields) else {
      continue
    }
    let receipt_run_id = json_string(receipt_fields, "worker_run_id")
    let worker = match
      latest_observed_worker(
        store,
        handoff.supervisor_profile_id,
        receipt_run_id,
      ) {
      Some((observed, _)) => observed
      None => receipt_worker
    }
    guard worker is Object(worker_fields) else { continue }
    let worker_run_id = json_string(worker_fields, "worker_run_id")
    let worker_job_id = json_string(worker_fields, "worker_job_id")
    let execution_status = json_string(worker_fields, "execution_status")
    if worker_run_id.is_empty() ||
      worker_run_id != receipt_run_id ||
      worker_job_id.is_empty() ||
      !worker_execution_status_allowed(execution_status) {
      continue
    }
    let task = handoff.worker_task
    let metadata = task.map(item => item.metadata).unwrap_or(Json::null())
    let metadata_fields = match metadata {
      Object(fields) => fields
      _ => Map([])
    }
    agents.push({
      "id": worker_run_id,
      "workerRunId": worker_run_id,
      "workerJobId": worker_job_id,
      "runId": worker_run_id,
      "parentRunId": handoff.parent_run_id,
      "supervisorProfileId": handoff.supervisor_profile_id,
      "parentSupervisorId": handoff.supervisor_profile_id,
      "name": task.map(item => item.title).unwrap_or("Bounded worker"),
      "role": "worker",
      "kind": "bounded-worker",
      "durability": "run-scoped",
      "status": worker_agent_status(execution_status),
      "runtimeExecutionStatus": execution_status,
      "buildingId": json_string_alias(
        metadata_fields, "buildingId", "building_id",
      ),
      "buildingModuleKey": json_string_alias(
        metadata_fields, "buildingId", "building_id",
      ),
      "workspaceId": json_string_alias(
        metadata_fields, "workspaceId", "workspace_id",
      ),
      "bookId": json_string_alias(metadata_fields, "bookId", "book_id"),
      "lineageSource": "moontown.supervisor-execution-handoff.v2",
      "workStatusSource": if latest_observed_worker(
          store,
          handoff.supervisor_profile_id,
          receipt_run_id,
        )
        is Some(_) {
        "moonsuite.supervisor-runtime-observation.v1"
      } else {
        "moonclaw.supervisor-delegate-intent-result.v1"
      },
      "movement": Json::null(),
      "movementSource": "not-observed",
    })
  }
  agents
}

///|
fn worker_from_delegate_receipt(handoff : SupervisorExecutionHandoff) -> Json? {
  guard handoff.action == "delegate" &&
    handoff.runtime_receipt is Some(Object(result_fields)) &&
    json_string(result_fields, "contract_id") ==
    "moonclaw.supervisor-delegate-intent-result.v1" else {
    return None
  }
  result_fields.get("worker")
}

///|
fn latest_observed_worker(
  store : SupervisorSetupStore,
  supervisor_profile_id : String,
  worker_run_id : String,
) -> (Json, Int)? {
  let observation = latest_runtime_observation(store, supervisor_profile_id)
  guard observation is Some(item) &&
    item.status_projection is Object(status_fields) else {
    return None
  }
  for worker in json_array(status_fields, "workers") {
    if worker is Object(worker_fields) &&
      json_string(worker_fields, "worker_run_id") == worker_run_id {
      return Some((worker, item.runtime_cursor))
    }
  }
  None
}

///|
fn child_lineage_projection(
  handoff : SupervisorExecutionHandoff,
  worker : Json?,
  runtime_cursor : Int?,
) -> Json {
  let task = handoff.worker_task
  let metadata = task.map(item => item.metadata).unwrap_or(Json::null())
  let metadata_fields = match metadata {
    Object(fields) => fields
    _ => Map([])
  }
  let worker_fields = match worker {
    Some(Object(fields)) => fields
    _ => Map([])
  }
  let worker_run_id = json_string(worker_fields, "worker_run_id")
  let execution_status = json_string(worker_fields, "execution_status")
  let projection_status = if execution_status == "pending_provider" {
    "queued"
  } else if execution_status.is_empty() {
    if handoff.status == "runtime_failed" {
      "failed"
    } else {
      "queued"
    }
  } else {
    execution_status
  }
  {
    "handoffId": handoff.handoff_id,
    "parentRunId": handoff.parent_run_id,
    "targetRunId": wire_string_or_null(handoff.target_run_id),
    "runId": if worker_run_id.is_empty() {
      Json::null()
    } else {
      worker_run_id.to_json()
    },
    "workerRunId": if worker_run_id.is_empty() {
      Json::null()
    } else {
      worker_run_id.to_json()
    },
    "workerJobId": {
      let value = json_string(worker_fields, "worker_job_id")
      if value.is_empty() {
        Json::null()
      } else {
        value.to_json()
      }
    },
    "providerTaskId": {
      let value = json_string(worker_fields, "provider_task_id")
      if value.is_empty() {
        Json::null()
      } else {
        value.to_json()
      }
    },
    "supervisorProfileId": handoff.supervisor_profile_id,
    "action": handoff.action,
    "commandKind": handoff.command_kind,
    "handoffStatus": handoff.status,
    "status": projection_status,
    "runtimeExecutionStatus": if execution_status.is_empty() {
      Json::null()
    } else {
      execution_status.to_json()
    },
    "runtimeCursor": wire_int_or_null(runtime_cursor),
    "title": task.map(item => item.title).unwrap_or(""),
    "buildingModuleKey": json_string_alias(
      metadata_fields, "buildingId", "building_id",
    ),
    "workspaceId": json_string_alias(
      metadata_fields, "workspaceId", "workspace_id",
    ),
    "bookId": json_string_alias(metadata_fields, "bookId", "book_id"),
    "summary": worker_fields.get("summary").unwrap_or(Json::null()),
    "error": worker_fields.get("error").unwrap_or(Json::null()),
    "resultEvidence": worker_fields
    .get("result_evidence")
    .unwrap_or(Json::null()),
    "artifactEvidence": worker_fields
    .get("artifact_evidence")
    .unwrap_or(Json::null()),
    "artifactRefs": worker_fields.get("artifact_refs").unwrap_or(Json::null()),
    "authorization": worker_fields.get("authorization").unwrap_or(Json::null()),
    "outcomeEvidenceStatus": worker_fields
    .get("outcome_evidence_status")
    .unwrap_or(Json::null()),
    "outcomeSourceEventId": worker_fields
    .get("outcome_source_event_id")
    .unwrap_or(Json::null()),
    "outcomeSubmission": worker_fields
    .get("outcome_evidence_candidate")
    .unwrap_or(Json::null()),
    "source": if runtime_cursor is Some(_) {
      "moonsuite.supervisor-runtime-observation.v1"
    } else {
      "moontown.supervisor-execution-handoff.v2"
    },
  }
}

///|
fn execution_lineage_projection_from_store(
  store : SupervisorSetupStore,
  supervisor_profile_id~ : String?,
) -> Array[Json] {
  let result : Array[Json] = []
  let seen : Array[String] = []
  for handoff in store.execution_handoffs.rev() {
    if seen.contains(handoff.handoff_id) {
      continue
    }
    if handoff.action != "delegate" {
      continue
    }
    if supervisor_profile_id is Some(expected) &&
      handoff.supervisor_profile_id != expected {
      continue
    }
    seen.push(handoff.handoff_id)
    let receipt_worker = worker_from_delegate_receipt(handoff)
    let observed = match receipt_worker {
      Some(Object(worker_fields)) => {
        let worker_run_id = json_string(worker_fields, "worker_run_id")
        if worker_run_id.is_empty() {
          None
        } else {
          latest_observed_worker(
            store,
            handoff.supervisor_profile_id,
            worker_run_id,
          )
        }
      }
      _ => None
    }
    match observed {
      Some((worker, runtime_cursor)) =>
        result.push(
          child_lineage_projection(handoff, Some(worker), Some(runtime_cursor)),
        )
      None =>
        result.push(child_lineage_projection(handoff, receipt_worker, None))
    }
  }
  result
}
