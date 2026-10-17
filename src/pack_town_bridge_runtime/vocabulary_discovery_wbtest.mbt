///|
async test "actual vocabulary discovery UI candidate survives native mailbox reload and replay" {
  let samples = @env.get_env_var("MOONTOWN_VOCABULARY_SAMPLES")
  let candidate_path = match samples {
    Some(root) => root + "/candidate.json"
    None => "src/pack_town_bridge_runtime/fixtures/vocabulary-candidate.json"
  }
  let snapshot_path = match samples {
    Some(root) => root + "/current-snapshot.json"
    None => "src/pack_town_bridge_runtime/fixtures/vocabulary-snapshot.json"
  }
  let candidate = @json.parse(@fs.read_file(candidate_path).text())
  let snapshot = @json.parse(@fs.read_file(snapshot_path).text())
  let registry : @pack_town_bridge.PackProjectionRegistry = @json.from_json(
    observation_fixture_field(snapshot, "projections"),
  )
  let workspace = @fs.tmpdir(prefix="moontown-vocabulary-workspace")
  let state_path = workspace + "/bridge/state.json"
  let profile : @installer.HostProfile = {
    contract: "moonsuite.pack-host-profile.v1",
    runtime_extensions: [],
    granted_authorities: [Observe, WorkspaceMutation],
  }
  for projection in registry.projections {
    let source = @fs.tmpdir(prefix="moontown-vocabulary-pack")
    write_bridge_fixture(source)
    let original = @pack.decode_manifest(
      @fs.read_file(source + "/pack.json").text(),
    )
    let manifest : @pack.MoonPackManifest = {
      ..original,
      id: projection.pack_id,
      product_id: projection.product_id,
      tools: original.tools.map(tool => {
        ..tool,
        owner_product: projection.product_id,
      }),
    }
    @fs.write_file(
      source + "/pack.json",
      @pack.encode_manifest(manifest),
      create_mode=CreateOrTruncate,
    )
    @installer.install_authorized(source, workspace, profile) |> ignore
    assert_true(
      ingest_projection(workspace, state_path, projection.to_json(), "t2").accepted,
    )
  }
  let before = load_runtime_state(state_path)
  assert_eq(before.projections.projections.length(), 2)
  let decoded : @pack_town_bridge.TownPackCandidate = @json.from_json(candidate)
  let context = observation_fixture_field(
    decoded.domain_payload,
    "moontown_source_context",
  )
  let discovery = observation_fixture_field(context, "vocabulary_discovery")
  assert_eq(
    observation_fixture_field(discovery, "contract_id"),
    "moontown.vocabulary-review.v1".to_json(),
  )
  assert_eq(
    observation_fixture_field(discovery, "accepted_knowledge"),
    false.to_json(),
  )
  assert_eq(
    observation_fixture_field(discovery, "omitted_match_count"),
    (1).to_json(),
  )
  let lens = observation_fixture_field(discovery, "lens")
  assert_eq(observation_fixture_field(lens, "terms"), ["export"].to_json())
  let selected : Array[Json] = @json.from_json(
    observation_fixture_field(discovery, "selected_matches"),
  )
  assert_eq(selected.length(), 2)
  assert_true(
    observation_fixture_field(selected[0], "pack_id") !=
    observation_fixture_field(selected[1], "pack_id"),
  )
  let sources : Array[Json] = @json.from_json(
    observation_fixture_field(context, "sources"),
  )
  assert_true(
    observation_fixture_field(sources[0], "evidence_refs") !=
    observation_fixture_field(sources[1], "evidence_refs"),
  )
  let submitted = submit_candidate(workspace, state_path, candidate, "t3")
  assert_true(submitted.accepted)
  assert_true(submitted.route.review_required)
  assert_eq(submitted.receipt.status, "review-pending")
  let inbox = workspace +
    "/" +
    candidate_inbox_ref(decoded.target_pack_id, decoded.candidate_ref)
  assert_eq(@json.parse(@fs.read_file(inbox).text()), candidate)
  let reloaded = load_runtime_state(state_path)
  assert_eq(reloaded.candidate_envelopes.length(), 1)
  assert_eq(reloaded.candidate_envelopes[0].to_json(), candidate)
  assert_eq(reloaded.projections, before.projections)
  let replay = submit_candidate(workspace, state_path, candidate, "t4")
  assert_eq(replay.receipt, submitted.receipt)
  assert_eq(load_runtime_state(state_path).candidate_envelopes.length(), 1)
  if samples is Some(root) {
    let evidence : Json = {
      "candidate_ref": decoded.candidate_ref,
      "receipt": submitted.receipt,
      "mailbox_matches_ui_envelope": true,
      "reload_matches_ui_envelope": true,
      "projection_unchanged": true,
      "replay_receipt_unchanged": true,
      "candidate_count_after_replay": 1,
      "accepted_knowledge": false,
    }
    @fs.write_file(
      root + "/native-receipt.json",
      evidence.stringify(indent=2) + "\n",
      create_mode=CreateOrTruncate,
    )
  }
}
