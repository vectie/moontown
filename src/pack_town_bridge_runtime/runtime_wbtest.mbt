///|
async fn write_bridge_fixture(root : String) -> Unit {
  @fs.mkdir(root + "/schemas", permission=0o755, recursive=true)
  @fs.mkdir(root + "/providers", permission=0o755, recursive=true)
  let manifest : @pack.MoonPackManifest = {
    id: "bridge-fixture",
    version: "1.0.0",
    display_name: "Bridge fixture",
    product_id: "bridge-fixture",
    kind: DomainPack,
    required_runtime_extensions: [],
    book_templates: [],
    schemas: [
      @pack.contract_ref(
        "pack-town-projection", "1.0.0", "schemas/pack-town-projection.schema.json",
      ),
      @pack.contract_ref(
        "town-pack-candidate", "1.0.0", "schemas/town-pack-candidate.schema.json",
      ),
      @pack.contract_ref(
        "fixture-draft", "1.0.0", "schemas/fixture-draft.schema.json",
      ),
    ],
    tools: [
      @pack.tool_declaration(
        "fixture.candidate.intake",
        "bridge-fixture",
        "town-pack-candidate",
        "fixture-draft",
        WorkspaceMutation,
        review_required=true,
      ),
      @pack.tool_declaration(
        "fixture.inspect",
        "bridge-fixture",
        "fixture-draft",
        "fixture-draft",
        Observe,
      ),
    ],
    workflows: [],
    skills: [],
    policies: [],
    provider_ports: [
      @pack.contract_ref(
        "moontown-pack-projection", "1.0.0", "providers/moontown-pack-projection.port.md",
      ),
    ],
    schedules: [],
    app_entrypoints: [],
    migrations: [],
    evaluations: [],
    uninstall_contract: Some(
      @pack.contract_ref("uninstall", "1.0.0", "UNINSTALL.md"),
    ),
  }
  @fs.write_file(
    root + "/pack.json",
    @encoding/utf8.encode(@pack.encode_manifest(manifest)),
    create_mode=CreateOrTruncate,
    permission=0o644,
  )
  for
    path in [
      root + "/schemas/pack-town-projection.schema.json",
      root + "/schemas/town-pack-candidate.schema.json",
      root + "/schemas/fixture-draft.schema.json",
    ] {
    @fs.write_file(
      path,
      @encoding/utf8.encode("{\"type\":\"object\"}\n"),
      create_mode=CreateOrTruncate,
      permission=0o644,
    )
  }
  @fs.write_file(
    root + "/providers/moontown-pack-projection.port.md",
    @encoding/utf8.encode("# Projection provider\n"),
    create_mode=CreateOrTruncate,
    permission=0o644,
  )
  @fs.write_file(
    root + "/UNINSTALL.md",
    @encoding/utf8.encode("Preserve durable evidence.\n"),
    create_mode=CreateOrTruncate,
    permission=0o644,
  )
}

///|
async test "runtime discovers projects and routes a reviewed bottom-up candidate" {
  let source = @fs.tmpdir(prefix="moontown-pack-bridge-source")
  let workspace = @fs.tmpdir(prefix="moontown-pack-bridge-workspace")
  let state_path = workspace + "/bridge/state.json"
  write_bridge_fixture(source)
  let profile : @installer.HostProfile = {
    contract: "moonsuite.pack-host-profile.v1",
    runtime_extensions: [],
    granted_authorities: [Observe, WorkspaceMutation],
  }
  @installer.install_authorized(source, workspace, profile) |> ignore
  let discovered = discover_active_packs(workspace, state_path, "t1")
  assert_eq(discovered.lifecycles.length(), 1)
  assert_eq(discovered.lifecycles[0].stage, "active")
  assert_eq(discovered.capabilities.length(), 1)
  assert_eq(discovered.capabilities[0].intake_operation_ids, [
    "fixture.candidate.intake",
  ])
  let projection : Json = {
    "contract_id": "moontown.pack-projection.v1",
    "pack_id": "bridge-fixture",
    "product_id": "bridge-fixture",
    "version": "1.0.0",
    "generated_at": "t2",
    "subjects": [
      {
        "subject_ref": "fixture/items/one",
        "schema_id": "fixture-draft",
        "title": "One",
        "summary": "A projected fixture subject.",
        "lifecycle_state": "draft",
        "attention": "review",
        "place_refs": [],
        "related_refs": [],
        "workflow_refs": [],
        "run_refs": [],
        "evidence_refs": [],
        "operation_ids": ["fixture.inspect"],
        "domain_payload": {},
      },
    ],
  }
  let ingested = ingest_projection(workspace, state_path, projection, "t2")
  assert_true(ingested.accepted)
  assert_eq(ingested.lifecycle.stage, "projecting")
  let candidate : Json = {
    "contract_id": "moontown.pack-candidate-intake.v1",
    "candidate_ref": "town/candidates/fixture-one",
    "origin_ref": "town/ideas/fixture-one",
    "target_pack_id": "bridge-fixture",
    "intake_operation_id": "fixture.candidate.intake",
    "submitted_by": "fixture-book",
    "submitted_at": "t3",
    "title": "Fixture candidate",
    "rationale": "A bottom-up fixture proposal.",
    "claim_ceiling": "observation",
    "evidence_refs": [],
    "domain_payload": {},
  }
  let submitted = submit_candidate(workspace, state_path, candidate, "t3")
  assert_true(submitted.accepted)
  assert_eq(submitted.receipt.status, "review-pending")
  let inbox_ref = candidate_inbox_ref(
    "bridge-fixture", "town/candidates/fixture-one",
  )
  assert_true(@fs.exists(workspace + "/" + inbox_ref))
  assert_eq(
    @json.parse(@fs.read_file(workspace + "/" + inbox_ref).text()),
    candidate,
  )
  let acknowledgement_ref = candidate_acknowledgement_ref(
    "bridge-fixture", "town/candidates/fixture-one",
  )
  ensure_parent_directory(workspace + "/" + acknowledgement_ref)
  let acknowledgement : Json = {
    "contract_id": "moontown.pack-candidate-acknowledgement.v1",
    "candidate_ref": "town/candidates/fixture-one",
    "pack_id": "bridge-fixture",
    "operation_id": "fixture.candidate.intake",
    "decision": "received",
    "occurred_at": "t4",
    "evidence_refs": ["records/fixture-one.json"],
  }
  @fs.write_file(
    workspace + "/" + acknowledgement_ref,
    @encoding/utf8.encode(acknowledgement.stringify()),
    create_mode=CreateOrTruncate,
    permission=0o644,
  )
  let reconciled = discover_active_packs(workspace, state_path, "t4")
  assert_eq(reconciled.candidates[0].status, "review-pending")
  assert_true(
    reconciled.candidates[0].evidence_refs.contains(acknowledgement_ref),
  )
  let replayed = discover_active_packs(workspace, state_path, "t5")
  assert_eq(replayed.candidates[0].sequence, reconciled.candidates[0].sequence)
  let reloaded = load_runtime_state(state_path)
  assert_eq(reloaded.projections.projections.length(), 1)
  assert_eq(reloaded.candidates.length(), 1)
  assert_eq(reloaded.candidate_envelopes.length(), 1)
  @fs.rmdir(source, recursive=true)
  @fs.rmdir(workspace, recursive=true)
}

///|
async test "runtime automatically reconciles a pack-published projection" {
  let source = @fs.tmpdir(prefix="moontown-pack-bridge-outbox-source")
  let workspace = @fs.tmpdir(prefix="moontown-pack-bridge-outbox-workspace")
  let state_path = workspace + "/bridge/state.json"
  write_bridge_fixture(source)
  let profile : @installer.HostProfile = {
    contract: "moonsuite.pack-host-profile.v1",
    runtime_extensions: [],
    granted_authorities: [Observe, WorkspaceMutation],
  }
  @installer.install_authorized(source, workspace, profile) |> ignore
  let projection : Json = {
    "contract_id": "moontown.pack-projection.v1",
    "pack_id": "bridge-fixture",
    "product_id": "bridge-fixture",
    "version": "1.0.0",
    "generated_at": "t2",
    "subjects": [],
  }
  let outbox_ref = projection_outbox_ref("bridge-fixture")
  ensure_parent_directory(workspace + "/" + outbox_ref)
  @fs.write_file(
    workspace + "/" + outbox_ref,
    @encoding/utf8.encode(projection.stringify()),
    create_mode=CreateOrTruncate,
    permission=0o644,
  )
  let discovered = discover_active_packs(workspace, state_path, "t2")
  assert_eq(discovered.projections.projections.length(), 1)
  assert_eq(discovered.lifecycles[0].stage, "projecting")
  let sequence = discovered.lifecycles[0].sequence
  let replayed = discover_active_packs(workspace, state_path, "t3")
  assert_eq(replayed.lifecycles[0].sequence, sequence)
  @fs.rmdir(source, recursive=true)
  @fs.rmdir(workspace, recursive=true)
}

///|
async test "invalid pack outbox degrades lifecycle without breaking discovery" {
  let source = @fs.tmpdir(prefix="moontown-pack-bridge-bad-outbox-source")
  let workspace = @fs.tmpdir(prefix="moontown-pack-bridge-bad-outbox-workspace")
  let state_path = workspace + "/bridge/state.json"
  write_bridge_fixture(source)
  let profile : @installer.HostProfile = {
    contract: "moonsuite.pack-host-profile.v1",
    runtime_extensions: [],
    granted_authorities: [Observe, WorkspaceMutation],
  }
  @installer.install_authorized(source, workspace, profile) |> ignore
  let outbox_ref = projection_outbox_ref("bridge-fixture")
  ensure_parent_directory(workspace + "/" + outbox_ref)
  @fs.write_file(
    workspace + "/" + outbox_ref,
    @encoding/utf8.encode("not-json"),
    create_mode=CreateOrTruncate,
    permission=0o644,
  )
  let discovered = discover_active_packs(workspace, state_path, "t2")
  assert_eq(discovered.capabilities.length(), 1)
  assert_eq(discovered.lifecycles[0].stage, "degraded")
  assert_true(
    discovered.lifecycles[0].issue
    .unwrap_or("")
    .contains("mailbox verification failed"),
  )
  let sequence = discovered.lifecycles[0].sequence
  let replayed = discover_active_packs(workspace, state_path, "t3")
  assert_eq(replayed.lifecycles[0].sequence, sequence)
  @fs.rmdir(source, recursive=true)
  @fs.rmdir(workspace, recursive=true)
}

///|
async test "rejected projection version preserves active lifecycle identity and last good projection" {
  let source = @fs.tmpdir(prefix="moontown-pack-bridge-version-source")
  let workspace = @fs.tmpdir(prefix="moontown-pack-bridge-version-workspace")
  let state_path = workspace + "/bridge/state.json"
  write_bridge_fixture(source)
  let profile : @installer.HostProfile = {
    contract: "moonsuite.pack-host-profile.v1",
    runtime_extensions: [],
    granted_authorities: [Observe, WorkspaceMutation],
  }
  @installer.install_authorized(source, workspace, profile) |> ignore
  let valid : Json = {
    "contract_id": "moontown.pack-projection.v1",
    "pack_id": "bridge-fixture",
    "product_id": "bridge-fixture",
    "version": "1.0.0",
    "generated_at": "t2",
    "subjects": [],
  }
  let accepted = ingest_projection(workspace, state_path, valid, "t2")
  assert_true(accepted.accepted)
  let mismatched : Json = {
    "contract_id": "moontown.pack-projection.v1",
    "pack_id": "bridge-fixture",
    "product_id": "bridge-fixture",
    "version": "99.0.0",
    "generated_at": "t3",
    "subjects": [],
  }
  let rejected = ingest_projection(workspace, state_path, mismatched, "t3")
  assert_false(rejected.accepted)
  assert_eq(rejected.lifecycle.version, "1.0.0")
  assert_eq(rejected.lifecycle.stage, "degraded")
  let discovered = discover_active_packs(workspace, state_path, "t4")
  assert_eq(discovered.lifecycles[0].version, "1.0.0")
  assert_eq(discovered.lifecycles[0].stage, "degraded")
  assert_eq(discovered.projections.projections, [@json.from_json(valid)])
  @fs.rmdir(source, recursive=true)
  @fs.rmdir(workspace, recursive=true)
}

///|
async test "runtime state migrates additive lifecycle fields" {
  let workspace = @fs.tmpdir(prefix="moontown-pack-bridge-migration")
  let state_path = workspace + "/state.json"
  @fs.write_file(
    state_path,
    @encoding/utf8.encode(
      "{\"contract_id\":\"moontown.pack-bridge-runtime.v1\",\"projections\":{\"contract_id\":\"moontown.pack-projection-registry.v1\",\"projections\":[]},\"lifecycles\":[],\"candidates\":[]}",
    ),
    create_mode=CreateOrTruncate,
    permission=0o644,
  )
  let state = load_runtime_state(state_path)
  assert_eq(state.contract_id, "moontown.pack-bridge-runtime.v1")
  assert_eq(state.capabilities, [])
  assert_eq(state.candidate_envelopes, [])
  @fs.rmdir(workspace, recursive=true)
}

///|
async test "runtime state fails closed on corruption" {
  let workspace = @fs.tmpdir(prefix="moontown-pack-bridge-corruption")
  let state_path = workspace + "/state.json"
  @fs.write_file(
    state_path,
    @encoding/utf8.encode("not-json"),
    create_mode=CreateOrTruncate,
    permission=0o644,
  )
  let rejected = try {
    load_runtime_state(state_path) |> ignore
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
  @fs.rmdir(workspace, recursive=true)
}

///|
test "activation reducer reaches active in one discovery pass" {
  let lifecycle = activated_lifecycle(
    None,
    "bridge-fixture",
    "1.0.0",
    "t1",
    "packs/bridge-fixture/pack.json",
  )
  assert_eq(lifecycle.stage, "active")
  assert_eq(lifecycle.sequence, 3)
}
