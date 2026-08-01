///|
fn supervisor_test_draft(
  command_id : String,
  expected_cursor : Int,
) -> SupervisorProfileDraft {
  {
    command_id,
    expected_version: 0,
    expected_cursor,
    profile_id: "supervisor-user-a",
    display_name: "Aster",
    avatar_url: None,
    role: "neutral",
    mission: "Supervise bounded work for book-a.",
    tone: "calm",
    capabilities: ["summarize", "delegate-bounded-work"],
    workspace_id: "workspace-a",
    building_id: "building-a",
    book_ids: ["book-a"],
    max_active_workers: 3,
    authority_ceiling: RequestBookkeeperReview,
    consent: {
      terms_version: "supervisor-onboarding.v1",
      profile_activation: true,
      runtime_delegation: true,
      bookkeeper_review: true,
      confirmed_at_ms: None,
    },
  }
}

///|
fn supervisor_test_authority(digest : String) -> Json {
  {
    "contract_id": "moonsuite.authority-decision-ref.v1",
    "decision_id": "authority-supervisor-activate-1",
    "principal": {
      "contract_id": "moonsuite.principal-ref.v1",
      "principal_id": "moonclaw-daemon",
      "kind": "service",
      "issuer": "moonclaw",
      "subject": "local-daemon",
    },
    "digest": digest,
    "decided_at": "2026-08-01T00:00:00Z",
    "expires_at": "2026-08-01T00:05:00Z",
  }
}

///|
fn supervisor_test_delegate_transport_request(
  handoff : SupervisorExecutionHandoff,
) -> Json raise {
  let task = handoff.worker_task.unwrap()
  let bounds = handoff.worker_bounds.unwrap()
  let metadata = match task.metadata {
    Object(fields) => fields
    _ => fail("delegate fixture metadata must be an object")
  }
  {
    "supervisor_id": handoff.supervisor_profile_id,
    "instruction": handoff.instruction,
    "task": {
      "task_id": task.task_id,
      "conversation_id": task.conversation_id,
      "title": task.title,
      "cwd": "/trusted/books/book-a",
      "model": task.model,
      "web_search": task.web_search,
      "metadata": {
        "workspace_id": json_string_alias(
          metadata, "workspaceId", "workspace_id",
        ),
        "book_id": json_string_alias(metadata, "bookId", "book_id"),
      },
    },
    "scope": {
      "claim_ceiling": bounds.claim_ceiling,
      "budget": {
        "max_cost_micro_usd": bounds.budget.max_cost_micro_usd.to_string(),
        "max_runtime_ms": bounds.budget.max_runtime_ms.to_string(),
        "max_tokens": bounds.budget.max_tokens.to_string(),
        "max_artifacts": bounds.budget.max_artifacts,
      },
      "artifact_prefixes": bounds.artifact_prefixes.to_json(),
      "expires_at": bounds.expires_at,
    },
  }
}

///|
fn supervisor_test_runtime_command(
  handoff : SupervisorExecutionHandoff,
  transport_request : Json,
  transport_digest : String,
) -> Json raise {
  guard transport_request is Object(request_fields) else {
    fail("transport fixture must be an object")
  }
  let command_fields : Map[String, Json] = Map([])
  for key, value in request_fields {
    command_fields[key] = value
  }
  command_fields["envelope"] = {
    "contract_id": "moonclaw.supervisor-command.v1",
    "command_id": handoff.command_id,
    "request_digest": transport_digest,
    "issued_at": handoff.created_at_ms.to_string(),
    "evaluated_at": "2026-08-01T00:00:00Z",
    "expected_cursor": wire_int_or_null(handoff.expected_cursor),
    "authority": supervisor_test_authority(transport_digest),
  }
  Json::object(command_fields)
}

///|
fn supervisor_test_json_string(value : Json) -> String {
  value.stringify()
}

///|
async test "neutral first profile accepts Bunnia wire without losing consent" {
  let root = @fs.tmpdir(prefix="moontown-supervisor-neutral-")
  let application = supervisor_setup_application(root)
  let draft = parse_supervisor_profile_draft(
    supervisor_test_json_string({
      "commandId": "profile-neutral-1",
      "expectedVersion": 0,
      "expectedCursor": 0,
      "name": "Aster",
      "archetypeId": "neutral",
      "toneId": "calm",
      "capabilityIds": ["summarize", "delegate-bounded-work"],
      "workspaceId": "workspace-a",
      "buildingId": "building-a",
      "bookId": "book-a",
      "consentAgentControl": true,
      "consentBookkeeperReview": true,
    }),
  )
  ignore(application.save_profile_draft("user-a", draft, now_ms=1000UL))
  let store = application.load_store()
  assert_eq(store.cursor, 1)
  assert_eq(store.profiles.length(), 1)
  let profile = store.profiles[0]
  assert_eq(profile.role, "neutral")
  assert_eq(profile.mission, "Supervise bounded work for book-a.")
  assert_true(profile.consent.profile_activation)
  assert_true(profile.consent.runtime_delegation)
  assert_true(profile.consent.bookkeeper_review)
  assert_true(profile.ready())
}

///|
async test "profile save is idempotent and stale cursor fails closed" {
  let root = @fs.tmpdir(prefix="moontown-supervisor-save-")
  let application = supervisor_setup_application(root)
  let draft = supervisor_test_draft("profile-save-1", 0)
  let first = application.save_profile_draft("user-a", draft, now_ms=1000UL)
  let replay = application.save_profile_draft("user-a", draft, now_ms=2000UL)
  assert_eq(first, replay)
  let replayed_store = application.load_store()
  assert_eq(replayed_store.cursor, 1)
  assert_eq(replayed_store.profiles.length(), 1)
  try
    application.save_profile_draft(
      "user-a",
      supervisor_test_draft("profile-save-stale", 0),
      now_ms=3000UL,
    )
  catch {
    error => assert_true("\{error}".contains("cursor conflict"))
  } noraise {
    _ => fail("stale Town cursor must be rejected")
  }
}

///|
async test "activation keeps profile identity stable and reconciles exact authority receipt" {
  let root = @fs.tmpdir(prefix="moontown-supervisor-activate-")
  let application = supervisor_setup_application(root)
  ignore(
    application.save_profile_draft(
      "user-a",
      supervisor_test_draft("profile-activate-seed", 0),
      now_ms=1000UL,
    ),
  )
  let saved = application.load_store().profiles[0]
  ignore(
    application.activate_profile(
      "user-a",
      {
        command_id: "activate-1",
        expected_version: saved.revision,
        expected_cursor: 1,
        runtime_expected_cursor: Some(9),
      },
      now_ms=2000UL,
    ),
  )
  let queued_store = application.load_store()
  assert_eq(queued_store.profiles.length(), 1)
  assert_eq(queued_store.profiles[0].revision, saved.revision)
  assert_eq(queued_store.profiles[0].content_digest, saved.content_digest)
  let queued = latest_activation_handoff(
    queued_store, "supervisor-activation-activate-1",
  ).unwrap()
  assert_eq(
    queued.payload.contract_id,
    "moonsuite.supervisor-profile-activation.v1",
  )
  assert_eq(queued.payload.profile_version, saved.revision)
  assert_eq(queued.payload.profile_digest, saved.content_digest)
  assert_eq(sha256_json(queued.payload.runtime_profile), saved.content_digest)
  let pending_projection = application.query_profile("user-a")
  guard pending_projection is Object(pending_fields) &&
    pending_fields.get("profile") is Some(Object(pending_profile)) else {
    fail("pending activation must expose a profile projection")
  }
  assert_eq(pending_profile.get("activeRunId"), Some(Json::null()))
  assert_eq(pending_profile.get("runtimeCursor"), Some(Json::null()))
  assert_eq(pending_profile.get("runtimeEvidenceSource"), Some(Json::null()))
  let pending_supervisors = application.supervisor_agents_projection()
  guard pending_supervisors[0] is Object(pending_supervisor) else {
    fail("pending supervisor projection must be an object")
  }
  assert_eq(pending_supervisor.get("activeRunId"), Some(Json::null()))
  assert_eq(pending_supervisor.get("runtimeCursor"), Some(Json::null()))
  assert_eq(pending_supervisor.get("runtimeEvidenceSource"), Some(Json::null()))
  let authority = supervisor_test_authority(queued.request_digest)
  let claim = application.claim_activation_handoff(
    "moondesk-1",
    supervisor_test_json_string({
      "handoffId": queued.handoff_id,
      "expectedCursor": 2,
      "evaluatedAt": "2026-08-01T00:00:01Z",
      "authority": authority,
    }),
  )
  assert_true(claim.stringify().contains("claimed_for_transport"))
  let claimed_store = application.load_store()
  let claimed = latest_activation_handoff(claimed_store, queued.handoff_id).unwrap()
  guard claimed.runtime_command is Some(Object(command)) else {
    fail("claimed activation must persist the exact runtime command")
  }
  assert_eq(json_string(command, "request_digest"), queued.request_digest)
  assert_eq(
    json_object(command, "authority").get("digest"),
    Some(queued.request_digest.to_json()),
  )
  let receipt : Json = {
    "contract_id": "moonclaw.supervisor-command-receipt.v1",
    "command_id": queued.command_id,
    "request_digest": queued.request_digest,
    "supervisor_id": queued.payload.supervisor_id,
    "cursor": 10,
    "event_id": "event-activate-1",
    "status": "accepted",
    "duplicate": false,
    "response": {
      "contract_id": "moonclaw.supervisor-state.v1",
      "supervisor_id": queued.payload.supervisor_id,
      "profile": queued.payload.to_json(),
      "lifecycle": "Dormant",
      "active_run_id": "runtime-run-activate-1",
      "cursor": 10,
      "updated_at": 2000,
      "last_error": Json::null(),
    },
  }
  ignore(
    application.reconcile_activation_handoff(
      "moondesk-1",
      supervisor_test_json_string({
        "handoffId": queued.handoff_id,
        "expectedCursor": 3,
        "receipt": receipt,
      }),
    ),
  )
  let reconciled_store = application.load_store()
  let reconciled = latest_activation_handoff(
    reconciled_store,
    queued.handoff_id,
  ).unwrap()
  assert_eq(reconciled.status, "runtime_acknowledged")
  assert_eq(reconciled.runtime_receipt, Some(receipt))
  assert_eq(reconciled_store.profiles.length(), 1)
  assert_eq(reconciled_store.profiles[0].revision, saved.revision)
  assert_eq(reconciled_store.profiles[0].content_digest, saved.content_digest)
  let acknowledged_projection = application.query_profile("user-a")
  guard acknowledged_projection is Object(acknowledged_fields) &&
    acknowledged_fields.get("profile") is Some(Object(acknowledged_profile)) else {
    fail("acknowledged activation must expose a profile projection")
  }
  assert_eq(
    acknowledged_profile.get("activeRunId"),
    Some("runtime-run-activate-1".to_json()),
  )
  assert_eq(
    acknowledged_profile.get("runtimeCursor"),
    Some((10 : Int).to_json()),
  )
  assert_eq(
    acknowledged_profile.get("runtimeEvidenceSource"),
    Some("moonclaw.supervisor-command-receipt.v1".to_json()),
  )
  let supervisors = application.supervisor_agents_projection()
  guard supervisors[0] is Object(supervisor) else {
    fail("supervisor projection must be an object")
  }
  assert_eq(
    supervisor.get("activeRunId"),
    Some("runtime-run-activate-1".to_json()),
  )
  assert_eq(supervisor.get("runtimeCursor"), Some((10 : Int).to_json()))
  assert_eq(
    supervisor.get("runtimeEvidenceSource"),
    Some("moonclaw.supervisor-command-receipt.v1".to_json()),
  )
}

///|
async test "execution handoff preserves bounded pending-provider status evidence" {
  let root = @fs.tmpdir(prefix="moontown-supervisor-execution-")
  let application = supervisor_setup_application(root)
  ignore(
    application.save_profile_draft(
      "user-a",
      supervisor_test_draft("profile-execution-seed", 0),
      now_ms=1000UL,
    ),
  )
  ignore(
    application.activate_profile(
      "user-a",
      {
        command_id: "activate-execution-1",
        expected_version: 1,
        expected_cursor: 1,
        runtime_expected_cursor: Some(9),
      },
      now_ms=2000UL,
    ),
  )
  let activation = latest_activation_handoff(
    application.load_store(),
    "supervisor-activation-activate-execution-1",
  ).unwrap()
  ignore(
    application.claim_activation_handoff(
      "moondesk-1",
      supervisor_test_json_string({
        "handoffId": activation.handoff_id,
        "expectedCursor": 2,
        "evaluatedAt": "2026-08-01T00:00:01Z",
        "authority": supervisor_test_authority(activation.request_digest),
      }),
    ),
  )
  ignore(
    application.reconcile_activation_handoff(
      "moondesk-1",
      supervisor_test_json_string({
        "handoffId": activation.handoff_id,
        "expectedCursor": 3,
        "receipt": {
          "contract_id": "moonclaw.supervisor-command-receipt.v1",
          "command_id": activation.command_id,
          "request_digest": activation.request_digest,
          "supervisor_id": activation.payload.supervisor_id,
          "cursor": 10,
          "event_id": "event-activate-execution-1",
          "status": "accepted",
          "duplicate": false,
          "response": {
            "contract_id": "moonclaw.supervisor-state.v1",
            "supervisor_id": activation.payload.supervisor_id,
            "profile": activation.payload.to_json(),
            "lifecycle": "Running",
            "active_run_id": "supervisor-run-1",
            "cursor": 10,
            "updated_at": "2000",
            "last_error": Json::null(),
          },
        },
      }),
    ),
  )
  ignore(
    application.request_run_delegate(
      "user-a",
      supervisor_test_json_string({
        "commandId": "delegate-1",
        "parentRunId": "supervisor-run-1",
        "expectedVersion": 1,
        "expectedCursor": 4,
        "runtimeExpectedCursor": 10,
        "instruction": "Prepare a bounded source summary.",
        "task": {
          "taskId": "task-source-summary-1",
          "conversationId": "supervisor-run-1",
          "title": "Prepare a bounded source summary.",
          "cwd": "",
          "model": "gpt-5.6-sol",
          "webSearch": false,
          "metadata": {
            "workspace_id": "workspace-a",
            "building_id": "building-a",
            "book_id": "book-a",
          },
        },
        "scope": {
          "claimCeiling": "reviewable",
          "budget": {
            "maxCostMicroUsd": 2000000,
            "maxRuntimeMs": 300000,
            "maxTokens": 12000,
            "maxArtifacts": 3,
          },
          "artifactPrefixes": ["books/book-a/artifacts"],
          "expiresAt": "2026-08-01T00:05:00Z",
        },
      }),
      now_ms=3000UL,
    ),
  )
  let queued_store = application.load_store()
  let queued = latest_execution_handoff(
    queued_store, "supervisor-execution-delegate-1",
  ).unwrap()
  assert_eq(queued.action, "delegate")
  assert_eq(queued.parent_run_id, "supervisor-run-1")
  assert_eq(queued.target_run_id, None)
  assert_eq(queued.command_kind, "bounded_worker_assignment")
  assert_eq(queued.status, "pending_transport")
  assert_eq(queued.expected_cursor, Some(10))
  assert_eq(
    queued.worker_task.unwrap().cwd,
    "workspace://workspace-a/books/book-a",
  )
  assert_eq(queued.worker_bounds.unwrap().budget.max_artifacts, 3)
  let transport_request = supervisor_test_delegate_transport_request(queued)
  let transport_digest = sha256_json(transport_request)
  ignore(
    application.claim_execution_handoff(
      "moondesk-1",
      supervisor_test_json_string({
        "handoffId": queued.handoff_id,
        "expectedCursor": 5,
        "sourceRequestDigest": queued.request_digest,
        "transportRequestDigest": transport_digest,
        "transportEndpoint": "delegate",
        "transportRequest": transport_request,
        "runtimeCommand": supervisor_test_runtime_command(
          queued, transport_request, transport_digest,
        ),
      }),
    ),
  )
  assert_eq(
    latest_execution_handoff(application.load_store(), queued.handoff_id).unwrap().status,
    "claimed_for_transport",
  )
  let command_receipt : Json = {
    "contract_id": "moonclaw.supervisor-command-receipt.v1",
    "command_id": queued.command_id,
    "request_digest": transport_digest,
    "supervisor_id": queued.supervisor_profile_id,
    "cursor": 11,
    "event_id": "event-delegate-1",
    "status": "accepted",
    "duplicate": false,
    "response": {
      "worker_run_id": "worker-run-1",
      "worker_job_id": "worker-job-1",
      "provider_task_id": "provider-task-1",
      "execution_status": "pending_provider",
    },
  }
  let receipt : Json = {
    "contract_id": "moonclaw.supervisor-delegate-intent-result.v1",
    "receipt": command_receipt,
    "provider_receipt": command_receipt,
    "worker": {
      "contract_id": "moonclaw.supervisor-worker-status.v1",
      "supervisor_id": queued.supervisor_profile_id,
      "parent_run_id": queued.parent_run_id,
      "parent_step_id": "delegate-1",
      "worker_run_id": "worker-run-1",
      "worker_job_id": "worker-job-1",
      "provider_task_id": "provider-task-1",
      "run_status": "queued",
      "execution_status": "pending_provider",
      "attempt": 1,
      "delegation": Json::empty_object(),
      "authorization": Json::empty_object(),
      "summary": Json::null(),
      "error": Json::null(),
      "result_evidence": Json::null(),
      "artifact_evidence": Json::null(),
      "artifact_refs": [],
      "outcome_evidence_status": "outcome_evidence_required",
      "outcome_source_event_id": Json::null(),
      "outcome_evidence_candidate": Json::null(),
      "started_at": Json::null(),
      "finished_at": Json::null(),
    },
  }
  ignore(
    application.reconcile_execution_handoff(
      "moondesk-1",
      supervisor_test_json_string({
        "handoffId": queued.handoff_id,
        "expectedCursor": 6,
        "receipt": receipt,
      }),
    ),
  )
  let reconciled = latest_execution_handoff(
    application.load_store(),
    queued.handoff_id,
  ).unwrap()
  assert_eq(reconciled.status, "runtime_acknowledged")
  guard reconciled.runtime_receipt is Some(Object(receipt_fields)) &&
    receipt_fields.get("worker") is Some(Object(worker_fields)) else {
    fail("execution receipt must remain durable")
  }
  assert_eq(json_string(worker_fields, "execution_status"), "pending_provider")
  let lineage = application.execution_lineage_projection()
  guard lineage[0] is Object(lineage_fields) else {
    fail("delegate lineage must be projected")
  }
  assert_eq(json_string(lineage_fields, "workerRunId"), "worker-run-1")
  assert_eq(json_string(lineage_fields, "status"), "queued")
  ignore(
    application.request_supervisor_wake(
      "user-a",
      supervisor_test_json_string({
        "commandId": "wake-supervisor-1",
        "parentRunId": "supervisor-run-1",
        "targetRunId": "supervisor-run-1",
        "expectedVersion": 1,
        "expectedCursor": 7,
        "runtimeExpectedCursor": 10,
      }),
      now_ms=4000UL,
    ),
  )
  ignore(
    application.request_supervisor_stop(
      "user-a",
      supervisor_test_json_string({
        "commandId": "stop-supervisor-1",
        "parentRunId": "supervisor-run-1",
        "targetRunId": "supervisor-run-1",
        "expectedVersion": 1,
        "expectedCursor": 8,
        "runtimeExpectedCursor": 10,
      }),
      now_ms=5000UL,
    ),
  )
  ignore(
    application.request_supervisor_resume(
      "user-a",
      supervisor_test_json_string({
        "commandId": "resume-supervisor-1",
        "parentRunId": "supervisor-run-1",
        "targetRunId": "supervisor-run-1",
        "expectedVersion": 1,
        "expectedCursor": 9,
        "runtimeExpectedCursor": 10,
      }),
      now_ms=6000UL,
    ),
  )
  let lifecycle_store = application.load_store()
  assert_eq(
    latest_execution_handoff(
      lifecycle_store, "supervisor-execution-wake-supervisor-1",
    ).unwrap().action,
    "wake",
  )
  assert_eq(
    latest_execution_handoff(
      lifecycle_store, "supervisor-execution-stop-supervisor-1",
    ).unwrap().action,
    "supervisor_stop",
  )
  assert_eq(
    latest_execution_handoff(
      lifecycle_store, "supervisor-execution-resume-supervisor-1",
    ).unwrap().action,
    "supervisor_resume",
  )
}

///|
async test "fabricated Bookkeeper submissions are rejected without queue mutation" {
  let root = @fs.tmpdir(prefix="moontown-supervisor-bookkeeper-")
  let application = supervisor_setup_application(root)
  ignore(
    application.save_profile_draft(
      "user-a",
      supervisor_test_draft("profile-bookkeeper-seed", 0),
      now_ms=1000UL,
    ),
  )
  let fabricated : Json = {
    "contract_version": "moonbook.bookkeeper.product_outcome_submission.v1",
    "submission": {
      "record_id": "fabricated-result",
      "record_version": "1",
      "record_digest": "sha256:" + "a".repeat(64),
    },
    "source_product": "moontown",
    "evidence_refs": [
      {
        "reference_id": "invented-event",
        "reference_version": "1",
        "digest": "sha256:" + "b".repeat(64),
        "provenance_ref": "moontown://invented",
      },
    ],
  }
  try
    application.request_bookkeeper_review(
      "user-a",
      supervisor_test_json_string({
        "commandId": "review-fabricated-1",
        "runId": "worker-run-1",
        "decision": "accept",
        "summary": "Pretend this local summary is accepted evidence.",
        "expectedCursor": 1,
        "outcomeSubmission": fabricated,
      }),
      now_ms=2000UL,
    )
  catch {
    error => assert_true("\{error}".contains("MoonClaw"))
  } noraise {
    _ => fail("fabricated non-MoonClaw submission must be rejected")
  }
  let store = application.load_store()
  assert_eq(store.cursor, 1)
  assert_true(store.review_requests.is_empty())
}
