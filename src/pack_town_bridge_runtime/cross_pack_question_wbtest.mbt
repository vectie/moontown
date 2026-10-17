///|
async test "cross-pack question retains distinct observations through reviewed mailbox reload and replay" {
  let first = @fs.tmpdir(prefix="moontown-question-first")
  let second = @fs.tmpdir(prefix="moontown-question-second")
  let workspace = @fs.tmpdir(prefix="moontown-question-workspace")
  let state_path = workspace + "/bridge/state.json"
  write_bridge_fixture(first)
  write_bridge_fixture(second)
  let base = @pack.decode_manifest(@fs.read_file(second + "/pack.json").text())
  let second_manifest : @pack.MoonPackManifest = {
    ..base,
    id: "second-fixture",
    product_id: "second-fixture",
    tools: base.tools.map(tool => { ..tool, owner_product: "second-fixture", }),
  }
  @fs.write_file(
    second + "/pack.json",
    @encoding/utf8.encode(@pack.encode_manifest(second_manifest)),
    create_mode=CreateOrTruncate,
    permission=0o644,
  )
  let profile : @installer.HostProfile = {
    contract: "moonsuite.pack-host-profile.v1",
    runtime_extensions: [],
    granted_authorities: [Observe, WorkspaceMutation],
  }
  @installer.install_authorized(first, workspace, profile) |> ignore
  @installer.install_authorized(second, workspace, profile) |> ignore
  let sources : Array[Json] = []
  for pack_id in ["bridge-fixture", "second-fixture"] {
    let subject : Json = {
      "subject_ref": "observations/signal.json",
      "schema_id": "fixture-draft",
      "title": pack_id + " signal",
      "summary": pack_id + " exact historical observation",
      "lifecycle_state": "draft",
      "attention": "review",
      "place_refs": [],
      "related_refs": [],
      "workflow_refs": [],
      "run_refs": [],
      "evidence_refs": ["evidence/shared.json"],
      "operation_ids": ["fixture.inspect"],
      "domain_payload": {},
    }
    let projection : Json = {
      "contract_id": "moontown.pack-projection.v1",
      "pack_id": pack_id,
      "product_id": pack_id,
      "version": "1.0.0",
      "generated_at": "t2",
      "subjects": [subject],
    }
    assert_true(
      ingest_projection(workspace, state_path, projection, "t2").accepted,
    )
    sources.push({
      "pack_id": pack_id,
      "product_id": pack_id,
      "pack_version": "1.0.0",
      "captured_generated_at": "t2",
      "subject_ref": "observations/signal.json",
      "schema_id": "fixture-draft",
      "title": pack_id + " signal",
      "summary": pack_id + " exact historical observation",
      "lifecycle_state": "draft",
      "evidence_refs": ["evidence/shared.json"],
      "connection": "Operator-labelled contextual observation",
    })
  }
  let before = load_runtime_state(state_path)
  assert_eq(before.projections.projections.length(), 2)
  let candidate : Json = {
    "contract_id": "moontown.pack-candidate-intake.v1",
    "candidate_ref": "town/candidates/cross-pack-question",
    "origin_ref": "town/ideas/cross-pack-question",
    "target_pack_id": "bridge-fixture",
    "intake_operation_id": "fixture.candidate.intake",
    "submitted_by": "moontown-operator",
    "submitted_at": "t3",
    "title": "Do different conditions explain these observations?",
    "rationale": "A bounded cross-pack question for review.",
    "claim_ceiling": "research-evidence",
    "evidence_refs": ["evidence/shared.json"],
    "domain_payload": {
      "experiment_kind": "interview",
      "moontown_source_context": {
        "contract_id": "moontown.source-linked-candidate.v1",
        "authorship": "Operator-authored proposal; selected packs have not endorsed it.",
        "accepted_knowledge": false,
        "genuine_emergence_verified": false,
        "uncertainty": "Reject if a matched comparison removes the difference.",
        "sources": sources,
        "cross_pack_question": {
          "contract_id": "moontown.cross-pack-question.v1",
          "accepted_knowledge": false,
          "question": "Do different conditions explain these observations?",
          "scope": "A bounded cross-pack question for review.",
          "rejection_test": "Reject if a matched comparison removes the difference.",
          "interpretation": "Operator-labelled relationships; no inferred consensus, contradiction or pack endorsement.",
          "observations": [
            {
              "pack_id": "bridge-fixture",
              "subject_ref": "observations/signal.json",
              "role": "supports",
              "connection": "First perspective",
              "conditions": "October; population A",
            },
            {
              "pack_id": "second-fixture",
              "subject_ref": "observations/signal.json",
              "role": "challenges",
              "connection": "Second perspective",
              "conditions": "Unknown date; population B",
            },
          ],
        },
      },
    },
  }
  let submitted = submit_candidate(workspace, state_path, candidate, "t3")
  assert_true(submitted.accepted)
  assert_true(submitted.route.review_required)
  assert_eq(submitted.receipt.status, "review-pending")
  let inbox = workspace +
    "/" +
    candidate_inbox_ref("bridge-fixture", "town/candidates/cross-pack-question")
  assert_eq(@json.parse(@fs.read_file(inbox).text()), candidate)
  let reloaded = load_runtime_state(state_path)
  assert_eq(reloaded.candidate_envelopes.length(), 1)
  assert_eq(reloaded.candidate_envelopes[0].to_json(), candidate)
  assert_eq(reloaded.projections, before.projections)
  let replay = submit_candidate(workspace, state_path, candidate, "t4")
  assert_eq(replay.receipt, submitted.receipt)
  assert_eq(load_runtime_state(state_path).candidate_envelopes.length(), 1)
  @fs.rmdir(first, recursive=true)
  @fs.rmdir(second, recursive=true)
  @fs.rmdir(workspace, recursive=true)
}
