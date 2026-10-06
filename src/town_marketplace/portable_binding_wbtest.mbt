///|
fn portable_fixture_source() -> PortableSource {
  {
    contract: "moonbook.portable_source.v1",
    bundle_contract: "moonbook.agent_bundle.v1",
    agent_id: "agent.portable-fixture",
    agent_version: "1.0.0",
    book_revision: sha256_text("fixture-revision-1"),
    bundle_digest: sha256_text("fixture-bundle-1"),
    package_filename: "portable-fixture.moonbook-agent",
    package_size_bytes: 1024,
    package_sha256: sha256_text("fixture-package-1"),
    file_count: 3,
    total_decoded_bytes: 100,
    outputs_manifest_path: Some("portable/outputs.manifest.v1.json"),
    outputs_manifest_digest: Some(sha256_text("fixture-outputs-1")),
    included_output_count: 1,
    reference_only_count: 1,
    transport: "local_file",
  }
}

///|
fn portable_fixture_payload(source : PortableSource) -> Json raise {
  let fields = api_object(test_agent_draft().to_json())
  fields["portable_source"] = source.to_json()
  // Deliberate actor forgery: the application must derive the actual owner.
  fields["publisher_principal_id"] = "forged-publisher".to_json()
  fields["tenant_id"] = "forged-tenant".to_json()
  Json::object(fields)
}

///|
fn portable_response_binding(value : Json) -> Json raise {
  let payload = api_object(api_object(value)["payload"])
  payload["portable_binding"]
}

///|
fn portable_response_listings(value : Json) -> Array[Json] raise {
  guard api_object(api_object(value)["payload"])["listings"] is Array(listings) else {
    fail("expected shared listing array")
  }
  listings
}

///|
test "portable persisted bindings reject corruption and duplicates" {
  let (state, owner, _, _) = test_state_with_sessions()
  let bound = marketplace_upsert_agent_draft(
    state,
    owner,
    test_agent_draft(),
    portable_source=portable_fixture_source(),
    now_ms=100UL,
  )
  let binding = bound.portable_bindings[0]
  validate_persisted_portable_bindings(bound)
  for
    bindings in [
      [binding, binding],
      [{ ..binding, binding_digest: sha256_text("corrupted"), }],
      [{ ..binding, source: { ..binding.source, agent_version: "2.0.0", }, }],
      [{ ..binding, publisher_principal_id: "forged-publisher", }],
      [{ ..binding, tenant_id: "forged-tenant", }],
      [{ ..binding, listing_id: "missing-listing", }],
    ] {
    try
      validate_persisted_portable_bindings({
        ..bound,
        portable_bindings: bindings,
      })
    catch {
      _ => ()
    } noraise {
      _ => fail("corrupt persisted binding must fail closed")
    }
  }
}

///|
async test "portable concurrent first attachments serialize and preserve the winning immutable binding" {
  let path = "/tmp/moontown-portable-concurrency-fixture/state.json"
  if @fs.exists(path) {
    @fs.remove(path)
  }
  let owner = test_principal("publisher-a", ["publisher"])
  let app = marketplace_application(
    path, owner, "bootstrap-concurrency", "opaque-concurrency-token",
  )
  let source = portable_fixture_source()
  let payload_a = portable_fixture_payload(source).stringify()
  let payload_b = portable_fixture_payload({
    ..source,
    package_sha256: sha256_text("concurrent-other-package"),
  }).stringify()
  let results = @async.with_task_group(group => {
    let first = group.spawn(() => {
      try {
        ignore(
          app.execute(
            "opaque-concurrency-token",
            "upsert-agent",
            payload_a,
            "",
            now_ms=100UL,
          ),
        )
        true
      } catch {
        _ => false
      }
    })
    let second = group.spawn(() => {
      try {
        ignore(
          app.execute(
            "opaque-concurrency-token",
            "upsert-agent",
            payload_b,
            "",
            now_ms=100UL,
          ),
        )
        true
      } catch {
        _ => false
      }
    })
    (first.wait(), second.wait())
  })
  assert_true(results.0 != results.1)
  let loaded = app.load_state()
  assert_eq(loaded.portable_bindings.length(), 1)
  assert_eq(loaded.agent_listings.length(), 1)
  assert_eq(loaded.action_requests.length(), 0)
  let expected = if results.0 {
    source.package_sha256
  } else {
    sha256_text("concurrent-other-package")
  }
  assert_eq(loaded.portable_bindings[0].source.package_sha256, expected)
}

///|
test "portable source strict wire requires exact keys integers null or string and canonical digests" {
  let source = portable_fixture_source()
  assert_eq(parse_portable_source(source.to_json()), source)
  assert_true(
    api_object(source.to_json())["outputs_manifest_path"] is String(_),
  )
  let no_outputs = {
    ..source,
    outputs_manifest_path: None,
    outputs_manifest_digest: None,
    included_output_count: 0,
    reference_only_count: 0,
  }
  assert_eq(parse_portable_source(no_outputs.to_json()), no_outputs)
  assert_true(api_object(no_outputs.to_json())["outputs_manifest_path"] is Null)
  for
    (key, value) in [
      ("contract", "unknown.v1".to_json()),
      ("bundle_contract", "unknown.v1".to_json()),
      ("transport", "remote_download".to_json()),
      ("package_sha256", "sha256:ABC".to_json()),
      ("bundle_digest", "not-a-digest".to_json()),
      ("book_revision", "not-a-digest".to_json()),
      ("package_size_bytes", 1.5.to_json()),
      ("file_count", (0).to_json()),
      ("total_decoded_bytes", (-1).to_json()),
      ("included_output_count", (4).to_json()),
      ("reference_only_count", (-1).to_json()),
      ("package_filename", "/home/sender/secret.moonbook-agent".to_json()),
      ("outputs_manifest_path", "../private.json".to_json()),
      ("outputs_manifest_path", "portable/other.json".to_json()),
      (
        "outputs_manifest_path",
        Json::array(["portable/outputs.manifest.v1.json".to_json()]),
      ),
      ("outputs_manifest_digest", Json::null()),
    ] {
    let fields = api_object(source.to_json())
    fields[key] = value
    try parse_portable_source(Json::object(fields)) catch {
      _ => ()
    } noraise {
      _ => fail("invalid portable field accepted: \{key}")
    }
  }
  for key in api_object(source.to_json()).keys().to_array() {
    let fields = api_object(source.to_json())
    fields.remove(key)
    try parse_portable_source(Json::object(fields)) catch {
      _ => ()
    } noraise {
      _ => fail("missing portable field accepted: \{key}")
    }
  }
  let extra = api_object(source.to_json())
  extra["raw_memory"] = "must not be persisted".to_json()
  try parse_portable_source(Json::object(extra)) catch {
    _ => ()
  } noraise {
    _ => fail("unknown descriptor fields must be rejected")
  }
}

///|
test "portable source freezes first attachment while legacy card hashes stay identical" {
  let (state, owner, _, _) = test_state_with_sessions()
  let draft = test_agent_draft()
  let source = portable_fixture_source()
  let legacy = marketplace_upsert_agent_draft(state, owner, draft, now_ms=100UL)
  let bound = marketplace_upsert_agent_draft(
    state,
    owner,
    draft,
    portable_source=source,
    now_ms=100UL,
  )
  assert_eq(bound.agent_listings, legacy.agent_listings)
  assert_eq(bound.portable_bindings.length(), 1)
  let binding = bound.portable_bindings[0]
  assert_eq(
    binding.binding_digest,
    sha256_text(portable_binding_identity(binding).stringify()),
  )
  assert_eq(binding.publisher_principal_id, owner.principal_id)
  assert_eq(binding.tenant_id, owner.tenant_id)
  let repeated = marketplace_upsert_agent_draft(
    bound,
    owner,
    draft,
    portable_source=source,
    now_ms=110UL,
  )
  assert_eq(repeated.portable_bindings, bound.portable_bindings)
  assert_eq(
    repeated.agent_listings[0].content_digest,
    bound.agent_listings[0].content_digest,
  )
  for
    changed in [
      None,
      Some({ ..source, agent_version: "2.0.0", }),
      Some({ ..source, package_sha256: sha256_text("different"), }),
    ] {
    try
      marketplace_upsert_agent_draft(
        bound,
        owner,
        draft,
        portable_source?=changed,
        now_ms=120UL,
      )
    catch {
      _ => ()
    } noraise {
      _ => fail("bound source change or removal must fail")
    }
  }
  let version_two = marketplace_upsert_agent_draft(
    bound,
    owner,
    { ..draft, listing_id: "agent.robot-guide-v2", },
    portable_source={ ..source, agent_version: "2.0.0", },
    now_ms=130UL,
  )
  assert_eq(version_two.portable_bindings.length(), 2)
  assert_eq(version_two.portable_bindings[0], binding)
  let forged = test_principal("another-publisher", ["publisher"])
  try
    marketplace_upsert_agent_draft(
      bound,
      forged,
      draft,
      portable_source=source,
      now_ms=140UL,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("source attachment must preserve owner authorization")
  }
}

///|
test "legacy v1 and v2 persisted states migrate without portable metadata or card digest changes" {
  let (state, _, _, _) = test_published_state()
  for
    schema in ["moontown.marketplace-store.v1", "moontown.marketplace-store.v2"] {
    let fields = api_object(state.to_json())
    fields["schema"] = schema.to_json()
    fields.remove("portable_bindings")
    if schema == "moontown.marketplace-store.v1" {
      fields.remove("action_requests")
    }
    let migrated : MarketplaceState = @json.from_json(
      migrate_marketplace_state_json(Json::object(fields)),
    )
    assert_eq(migrated.portable_bindings.length(), 0)
    assert_eq(migrated.agent_listings, state.agent_listings)
    assert_eq(
      public_listing_index_export(migrated),
      public_listing_index_export(state),
    )
  }
}

///|
test "bound metadata does not alter public projection or hosted Try publisher actor" {
  let (state, owner, reviewer, reader) = test_state_with_sessions()
  let bound = marketplace_upsert_agent_draft(
    state,
    owner,
    test_agent_draft(),
    portable_source=portable_fixture_source(),
    now_ms=100UL,
  )
  assert_eq(bound.action_requests.length(), 0)
  let submitted = marketplace_transition_listing(
    bound,
    owner,
    AgentListing,
    "agent.robot-guide",
    PublicationSubmitted,
    review_summary="fixture only",
    now_ms=110UL,
  )
  let published = marketplace_transition_listing(
    submitted,
    reviewer,
    AgentListing,
    "agent.robot-guide",
    PublicationPublished,
    review_summary="synthetic independent review",
    now_ms=120UL,
  )
  let (legacy, _, _, _) = test_published_state()
  assert_eq(
    public_listing_index_export(published),
    public_listing_index_export(legacy),
  )
  guard api_object(public_listing_index_export(published))["listings"]
    is Array([Object(card)]) else {
    fail("expected one public card")
  }
  assert_eq(card.length(), 15)
  assert_false(
    public_listing_index_export(published).stringify().contains("portable"),
  )
  let requested = marketplace_request_listing_action(
    published,
    reader,
    AgentListing,
    "agent.robot-guide",
    "try",
    "Hosted work remains separate",
    now_ms=130UL,
  )
  let legacy_requested = marketplace_request_listing_action(
    legacy,
    reader,
    AgentListing,
    "agent.robot-guide",
    "try",
    "Hosted work remains separate",
    now_ms=130UL,
  )
  assert_eq(requested.action_requests, legacy_requested.action_requests)
  assert_eq(
    requested.action_requests[0].publisher_principal_id,
    owner.principal_id,
  )
  assert_eq(
    requested.action_requests[0].requester_principal_id,
    reader.principal_id,
  )
  assert_true(requested.action_requests[0].execution_handoff_id is None)
  assert_eq(requested.portable_bindings, bound.portable_bindings)
}

///| With MOONTOWN_PORTABLE_FIXTURE_DIR, source.json is produced by the real

///|
/// Book exporter. Only metadata passes through Town; package bytes never do.
async test "portable application owner grant recipient restart and negative authorization fixture" {
  let external_dir = @env.get_env_var("MOONTOWN_PORTABLE_FIXTURE_DIR")
  let root = external_dir.unwrap_or("/tmp/moontown-portable-binding-fixture")
  let path = root + "/town-state.json"
  if @fs.exists(path) {
    @fs.remove(path)
  }
  let source = match external_dir {
    Some(_) =>
      parse_portable_source(
        @json.parse(@fs.read_file(root + "/source.json").text()),
      )
    None => portable_fixture_source()
  }
  let owner = test_principal("publisher-a", ["publisher"])
  let reader = test_principal("recipient-b", [])
  let outsider = test_principal("unrelated-c", [])
  let cross_tenant = {
    ..test_principal("cross-tenant-d", []),
    tenant_id: "town-other",
  }
  let app = marketplace_application(
    path, owner, "session-bootstrap", "opaque-bootstrap-token",
  )
  app.synchronize_account_session(
    reader,
    "fixture-recipient-token",
    now_ms=1UL,
    expires_at_ms=1000UL,
  )
  app.synchronize_account_session(
    outsider,
    "fixture-unrelated-token",
    now_ms=1UL,
    expires_at_ms=1000UL,
  )
  app.synchronize_account_session(
    cross_tenant,
    "fixture-cross-tenant-token",
    now_ms=1UL,
    expires_at_ms=1000UL,
  )
  let payload = portable_fixture_payload(source).stringify()
  let saved = app.execute(
    "opaque-bootstrap-token",
    "upsert-agent",
    payload,
    "",
    now_ms=100UL,
  )
  let binding = portable_response_binding(saved)
  let binding_fields = api_object(binding)
  assert_eq(
    binding_fields["publisher_principal_id"],
    owner.principal_id.to_json(),
  )
  assert_eq(binding_fields["tenant_id"], owner.tenant_id.to_json())
  assert_eq(binding_fields["source"], source.to_json())
  let repeated = app.execute(
    "opaque-bootstrap-token",
    "upsert-agent",
    payload,
    "",
    now_ms=101UL,
  )
  assert_eq(portable_response_binding(repeated), binding)
  let preview_request : Json = {
    "resource_kind": "agent",
    "resource_id": "agent.robot-guide",
    "grantee_principal_id": reader.principal_id,
  }
  let preview = app.execute(
    "opaque-bootstrap-token",
    "share-preview",
    preview_request.stringify(),
    "",
    now_ms=102UL,
  )
  assert_eq(
    api_object(api_object(api_object(preview)["payload"])["projection"])["portable_binding"],
    binding,
  )
  let before = app.execute(
    "fixture-recipient-token",
    "shared-listings",
    "",
    "",
    now_ms=103UL,
  )
  assert_eq(portable_response_listings(before).length(), 0)
  for
    token in [
      "fixture-recipient-token", "fixture-unrelated-token", "fixture-cross-tenant-token",
      "", "publisher-a",
    ] {
    try app.execute(token, "upsert-agent", payload, "", now_ms=104UL) catch {
      _ => ()
    } noraise {
      _ => fail("non-owner or unauthenticated source mutation must fail")
    }
  }
  for token in ["fixture-recipient-token", "fixture-unrelated-token"] {
    try
      app.execute(
        token,
        "share-preview",
        preview_request.stringify(),
        "",
        now_ms=104UL,
      )
    catch {
      _ => ()
    } noraise {
      _ => fail("share preview must remain owner-only")
    }
  }
  let grant : Json = {
    "grant_id": "portable-grant-1",
    "resource_kind": "agent",
    "resource_id": "agent.robot-guide",
    "grantee_principal_id": reader.principal_id,
    "permission": "view",
    "expires_at_ms": 400,
  }
  ignore(
    app.execute(
      "opaque-bootstrap-token",
      "share-grant",
      grant.stringify(),
      "",
      now_ms=110UL,
    ),
  )
  let cross_grant = api_object(grant)
  cross_grant["grant_id"] = "cross-grant".to_json()
  cross_grant["grantee_principal_id"] = cross_tenant.principal_id.to_json()
  try
    app.execute(
      "opaque-bootstrap-token",
      "share-grant",
      Json::object(cross_grant).stringify(),
      "",
      now_ms=111UL,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("portable source grants must not cross tenant boundaries")
  }
  let shared = app.execute(
    "fixture-recipient-token",
    "shared-listings",
    "",
    "",
    now_ms=120UL,
  )
  let cards = portable_response_listings(shared)
  assert_eq(cards.length(), 1)
  assert_eq(api_object(cards[0])["portable_binding"], binding)
  assert_eq(
    api_object(cards[0])["contract_id"],
    "moontown.private-listing-share-preview.v2".to_json(),
  )
  for token in ["fixture-unrelated-token", "fixture-cross-tenant-token"] {
    assert_eq(
      portable_response_listings(
        app.execute(token, "shared-listings", "", "", now_ms=120UL),
      ).length(),
      0,
    )
  }
  let restarted = marketplace_application(
    path, owner, "session-bootstrap", "opaque-bootstrap-token",
  )
  let restored = restarted.execute(
    "fixture-recipient-token",
    "shared-listings",
    "",
    "",
    now_ms=130UL,
  )
  assert_eq(restored, shared)
  let persisted = restarted.load_state()
  assert_eq(persisted.portable_bindings.length(), 1)
  assert_eq(persisted.action_requests.length(), 0)
  assert_eq(public_listing_cards(persisted).length(), 0)
  assert_eq(persisted.agent_listings[0].lifecycle.state, PublicationShared)
  assert_false(shared.stringify().contains("bundle_verified_by_town"))
  assert_false(shared.stringify().contains("raw_memory"))
  if external_dir is Some(_) && @fs.exists(root + "/source-v2.json") {
    let source_v2 = parse_portable_source(
      @json.parse(@fs.read_file(root + "/source-v2.json").text()),
    )
    let draft_v2 = api_object(portable_fixture_payload(source_v2))
    draft_v2["listing_id"] = "agent.robot-guide-v2".to_json()
    let saved_v2 = restarted.execute(
      "opaque-bootstrap-token",
      "upsert-agent",
      Json::object(draft_v2).stringify(),
      "",
      now_ms=131UL,
    )
    let binding_v2 = portable_response_binding(saved_v2)
    assert_eq(api_object(binding_v2)["source"], source_v2.to_json())
    assert_true(binding_v2 != binding)
    let retained = restarted.execute(
      "fixture-recipient-token",
      "shared-listings",
      "",
      "",
      now_ms=132UL,
    )
    assert_eq(retained, shared)
    @fs.write_file(
      root + "/town-binding-v2.json",
      binding_v2.stringify(indent=2) + "\n",
      create_mode=CreateOrTruncate,
    )
    @fs.write_file(
      root + "/town-retained-v1-response.json",
      retained.stringify(indent=2) + "\n",
      create_mode=CreateOrTruncate,
    )
  }
  assert_eq(
    portable_response_listings(
      restarted.execute(
        "fixture-recipient-token",
        "shared-listings",
        "",
        "",
        now_ms=400UL,
      ),
    ).length(),
    0,
  )
  let revoke : Json = { "grant_id": "portable-grant-1" }
  ignore(
    restarted.execute(
      "opaque-bootstrap-token",
      "revoke-share-grant",
      revoke.stringify(),
      "",
      now_ms=150UL,
    ),
  )
  assert_eq(
    portable_response_listings(
      restarted.execute(
        "fixture-recipient-token",
        "shared-listings",
        "",
        "",
        now_ms=151UL,
      ),
    ).length(),
    0,
  )
  try
    restarted.execute(
      "fixture-recipient-token",
      "shared-listings",
      "",
      "",
      now_ms=1000UL,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("expired fixture session must not authorize access")
  }
  // Saved recipient binding remains a meaningful expectation after revocation.
  // Revocation controls future reads; it cannot erase a recipient's saved file.
  if external_dir is Some(_) {
    @fs.write_file(
      root + "/town-binding.json",
      binding.stringify(indent=2) + "\n",
      create_mode=CreateOrTruncate,
    )
    @fs.write_file(
      root + "/town-owner-response.json",
      saved.stringify(indent=2) + "\n",
      create_mode=CreateOrTruncate,
    )
    @fs.write_file(
      root + "/town-recipient-response.json",
      shared.stringify(indent=2) + "\n",
      create_mode=CreateOrTruncate,
    )
    @fs.write_file(
      root + "/town-restart-response.json",
      restored.stringify(indent=2) + "\n",
      create_mode=CreateOrTruncate,
    )
    @fs.write_file(
      root + "/town-fixture-report.json",
      (
        {
          "contract": "moontown.portable-fixture-proof.v1",
          "owner_session_identity": true,
          "same_tenant_grant": true,
          "restart_preserved_binding": true,
          "unrelated_denied": true,
          "cross_tenant_denied": true,
          "expired_grant_denied": true,
          "revoked_grant_denied": true,
          "expired_session_denied": true,
          "publications": 0,
          "runtime_action_requests": 0,
          "transport": "metadata_only_file_carried_separately",
        } : Json).stringify(indent=2) +
      "\n",
      create_mode=CreateOrTruncate,
    )
  }
}
