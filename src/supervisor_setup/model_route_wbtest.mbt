///|
fn supervisor_route_fixture(
  default_model : String,
  ready? : Bool = true,
) -> Json {
  {
    "contract": "moonclaw.moongate-route.v1",
    "ready": ready,
    "catalog_ready": true,
    "default_ready": ready,
    "default_model": default_model,
    "models": [
      { "name": "moongate/first" },
      { "name": "moongate/configured" },
      { "name": "moongate/explicit" },
    ],
  }
}

///|
fn supervisor_route_payload(
  requested : String,
) -> SupervisorProfileActivationPayload {
  {
    contract_id: "moonsuite.supervisor-profile-activation.v1",
    supervisor_id: "supervisor-user-a",
    profile_id: "supervisor-user-a",
    profile_version: 1,
    profile_digest: "sha256:" + "a".repeat(64),
    source_product: "moontown",
    runtime_profile: { "exact": "profile" },
    runtime_binding: {
      "workspace_id": "workspace-a",
      "building_id": "building-a",
      "book_ids": ["book-a"],
      "model": "",
      "requested_model": requested,
      "model_resolution": "pending_route",
      "max_active_workers": 3,
      "source_request_digest": "sha256:" + "b".repeat(64),
    },
    activated_at: "2000",
  }
}

///|
test "activation uses configured identity and preserves explicit choice without a default" {
  let pending = supervisor_route_payload("")
  let resolved = resolve_supervisor_activation_model(
    pending,
    supervisor_route_fixture("moongate/configured"),
  )
  assert_eq(supervisor_activation_model(resolved), "moongate/configured")
  assert_eq(supervisor_activation_model(pending), "")
  assert_eq(resolved.runtime_profile, pending.runtime_profile)
  assert_eq(resolved.profile_digest, pending.profile_digest)
  let explicit = resolve_supervisor_activation_model(
    supervisor_route_payload("moongate/explicit"),
    supervisor_route_fixture("", ready=false),
  )
  assert_eq(supervisor_activation_model(explicit), "moongate/explicit")
  let persisted_explicit : SupervisorProfileActivationPayload = @json.from_json(
    @json.parse(explicit.to_json().stringify()),
  )
  assert_eq(
    resolve_supervisor_activation_model(
      persisted_explicit,
      supervisor_route_fixture("moongate/first"),
    ),
    explicit,
  )
  assert_eq(
    resolve_supervisor_activation_model(resolved, Json::null()),
    resolved,
  )
  assert_eq(
    resolve_supervisor_activation_model(
      resolved,
      supervisor_route_fixture("moongate/first"),
    ),
    resolved,
  )
  for
    (request, route) in [
      ("", Json::null()),
      ("", supervisor_route_fixture("", ready=false)),
      ("", supervisor_route_fixture("moongate/absent")),
      ("moongate/absent", supervisor_route_fixture("moongate/configured")),
      ("codex/gpt-5.6-sol", supervisor_route_fixture("moongate/configured")),
    ] {
    try
      resolve_supervisor_activation_model(
        supervisor_route_payload(request),
        route,
      )
    catch {
      error => assert_true("\{error}".contains("model_route_required"))
    } noraise {
      _ => fail("unavailable route must not choose another model")
    }
  }
}

///|
fn supervisor_route_delegate(model : String, cursor : Int) -> Json {
  {
    "commandId": "delegate-route",
    "parentRunId": "run-route",
    "expectedVersion": 1,
    "expectedCursor": cursor,
    "runtimeExpectedCursor": 10,
    "instruction": "Prepare a bounded review.",
    "task": {
      "taskId": "task-route",
      "conversationId": "run-route",
      "title": "Review",
      "cwd": "",
      "model": model,
      "webSearch": false,
      "metadata": { "workspace_id": "workspace-a", "book_id": "book-a" },
    },
    "scope": {
      "claimCeiling": "reviewable",
      "budget": {
        "maxCostMicroUsd": "2000000",
        "maxRuntimeMs": "300000",
        "maxTokens": "12000",
        "maxArtifacts": 3,
      },
      "artifactPrefixes": ["books/book-a/artifacts"],
      "expiresAt": "2026-08-01T00:05:00Z",
    },
  }
}

///|
async test "route resolution is atomic authorized persisted and exact through delegate and retry" {
  let root = @fs.tmpdir(prefix="moontown-supervisor-route-")
  let application = supervisor_setup_application(root)
  ignore(
    application.save_profile_draft(
      "user-a",
      supervisor_test_draft("profile-route", 0),
      now_ms=1000UL,
    ),
  )
  let original_profile = application.load_store().profiles[0]
  let draft = parse_supervisor_activation_draft(
    supervisor_test_json_string({
      "commandId": "activate-route",
      "expectedVersion": 1,
      "expectedCursor": 1,
      "runtimeExpectedCursor": 9,
    }),
  )
  assert_eq(draft.requested_model, None)
  let accepted = application.activate_profile("user-a", draft, now_ms=2000UL)
  assert_true(accepted.stringify().contains("model_route_required"))
  assert_true(
    application
    .query_profile("user-a")
    .stringify()
    .contains("model_route_required"),
  )
  let before = application.load_store()
  let pending = latest_activation_handoff(
    before, "supervisor-activation-activate-route",
  ).unwrap()
  assert_eq(supervisor_activation_model(pending.payload), "")
  let route = supervisor_route_fixture("moongate/configured")
  let resolved = resolve_supervisor_activation_model(pending.payload, route)
  let digest = sha256_json(supervisor_activation_payload_wire_json(resolved))
  for
    (probe, authority_digest) in [
      (Json::null(), digest),
      (route, pending.request_digest),
    ] {
    try
      application.claim_activation_handoff(
        "desk",
        supervisor_test_json_string({
          "handoffId": pending.handoff_id,
          "expectedCursor": 2,
          "evaluatedAt": "2026-08-01T00:00:01Z",
          "modelRoute": probe,
          "authority": supervisor_test_authority(authority_digest),
        }),
      )
    catch {
      _ => ()
    } noraise {
      _ => fail("missing route or mismatched grant must fail")
    }
    assert_eq(application.load_store(), before)
  }
  ignore(
    application.claim_activation_handoff(
      "desk",
      supervisor_test_json_string({
        "handoffId": pending.handoff_id,
        "expectedCursor": 2,
        "evaluatedAt": "2026-08-01T00:00:01Z",
        "modelRoute": route,
        "authority": supervisor_test_authority(digest),
      }),
    ),
  )
  let claimed = latest_activation_handoff(
    supervisor_setup_application(root).load_store(),
    pending.handoff_id,
  ).unwrap()
  assert_eq(claimed.payload, resolved)
  assert_eq(claimed.request_digest, digest)
  assert_eq(application.load_store().profiles[0], original_profile)
  ignore(
    application.release_runtime_handoff(
      "desk",
      supervisor_test_json_string({
        "kind": "activation",
        "handoffId": pending.handoff_id,
        "expectedCursor": 3,
      }),
    ),
  )
  ignore(
    application.claim_activation_handoff(
      "desk",
      supervisor_test_json_string({
        "handoffId": pending.handoff_id,
        "expectedCursor": 4,
        "evaluatedAt": "2026-08-01T00:00:02Z",
        "modelRoute": supervisor_route_fixture("moongate/first"),
        "authority": supervisor_test_authority(digest),
      }),
    ),
  )
  let reclaimed = latest_activation_handoff(
    application.load_store(),
    pending.handoff_id,
  ).unwrap()
  assert_eq(reclaimed.payload, resolved)
  assert_eq(reclaimed.request_digest, digest)
  ignore(
    application.reconcile_activation_handoff(
      "desk",
      supervisor_test_json_string({
        "handoffId": pending.handoff_id,
        "expectedCursor": 5,
        "receipt": {
          "contract_id": "moonclaw.supervisor-command-receipt.v1",
          "command_id": pending.command_id,
          "request_digest": digest,
          "supervisor_id": resolved.supervisor_id,
          "status": "accepted",
          "cursor": 10,
          "response": {
            "contract_id": "moonclaw.supervisor-state.v1",
            "supervisor_id": resolved.supervisor_id,
            "active_run_id": "run-route",
            "cursor": 10,
            "profile": supervisor_activation_payload_wire_json(resolved),
          },
        },
      }),
    ),
  )
  guard application.query_profile("user-a") is Object(snapshot) else {
    fail("snapshot")
  }
  assert_eq(
    json_string(json_object(snapshot, "profile"), "runtimeModel"),
    "moongate/configured",
  )
  for wrong in ["", "gpt-5.6-sol", "moongate/explicit"] {
    try
      application.request_run_delegate(
        "user-a",
        supervisor_route_delegate(wrong, 6).stringify(),
        now_ms=3000UL,
      )
    catch {
      _ => ()
    } noraise {
      _ => fail("assignment must retain active selector")
    }
    assert_eq(application.load_store().cursor, 6)
  }
  ignore(
    application.request_run_delegate(
      "user-a",
      supervisor_route_delegate("moongate/configured", 6).stringify(),
      now_ms=3000UL,
    ),
  )
  let execution = latest_execution_handoff(
    supervisor_setup_application(root).load_store(),
    "supervisor-execution-delegate-route",
  ).unwrap()
  assert_eq(execution.worker_task.unwrap().model, "moongate/configured")
  let exact_transport = supervisor_test_delegate_transport_request(execution)
  guard exact_transport is Object(transport_fields) else { fail("transport") }
  validate_delegate_transport_request(transport_fields, execution)
  assert_eq(
    json_string(json_object(transport_fields, "task"), "model"),
    "moongate/configured",
  )
  assert_eq(
    application.activate_profile("user-a", draft, now_ms=5000UL),
    accepted,
  )
  assert_eq(
    latest_activation_handoff(application.load_store(), pending.handoff_id).unwrap().payload,
    resolved,
  )
}

///|
async test "a newer activation supersedes an older handoff regardless of transport revision" {
  let root = @fs.tmpdir(prefix="moontown-supervisor-reroute-")
  let application = supervisor_setup_application(root)
  ignore(
    application.save_profile_draft(
      "user-a",
      supervisor_test_draft("profile-new-route", 0),
      now_ms=1000UL,
    ),
  )
  for
    (command, cursor, time) in [
      ("old-route", 1, 2000UL),
      ("new-route", 2, 3000UL),
    ] {
    ignore(
      application.activate_profile(
        "user-a",
        {
          command_id: command,
          expected_version: 1,
          expected_cursor: cursor,
          runtime_expected_cursor: None,
          requested_model: Some("moongate/explicit"),
        },
        now_ms=time,
      ),
    )
  }
  let store = application.load_store()
  let old = { ..store.activation_handoffs[0], revision: 99, }
  let fixture = {
    ..store,
    activation_handoffs: store.activation_handoffs + [old],
  }
  let latest = latest_activation_for_profile(fixture, "supervisor-user-a").unwrap()
  assert_eq(latest.command_id, "new-route")
  assert_eq(supervisor_activation_model(latest.payload), "")
  let same_time = { ..store.activation_handoffs[1], created_at_ms: 2000UL, }
  let tied = {
    ..store,
    activation_handoffs: [store.activation_handoffs[0], same_time, old],
  }
  assert_eq(
    latest_activation_for_profile(tied, "supervisor-user-a").unwrap().command_id,
    "new-route",
  )
}
