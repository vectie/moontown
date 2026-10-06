///| Socket-free coverage of the actual AccountApplication::resolve seam used

///| by require_account_context. Applications, clocks, requests, accounts and

///|
/// state paths are injected explicitly. No configured environment is read.
fn portable_boundary_account(
  user_id : String,
) -> @account_system.AccountPrincipal {
  {
    user_id,
    display_name: user_id,
    personal_plan: @account_system.PaidPlan,
    platform_roles: [],
    tenant_access: [
      {
        tenant_id: "portable-boundary-tenant",
        tenant_name: "Synthetic boundary fixture",
        plan: @account_system.EnterprisePlan,
        roles: [@account_system.AccountMember, @account_system.AccountPublisher],
        active: true,
        version: 1,
      },
    ],
    active: true,
    version: 1,
  }
}

///|
fn portable_boundary_request(token : String) -> @http.Request {
  {
    meth: @http.Post,
    path: @town_contract.miniapp_marketplace_agent_listing_path(),
    headers: {
      "x-miniapp-session": token,
      "x-miniapp-user-id": "forged-user",
      "x-miniapp-principal": "forged-principal",
      "x-miniapp-tenant": "forged-tenant",
    },
  }
}

///|
async test "portable direct account resolver denies missing expired revoked and symbolic identity tokens without sockets" {
  let root = "/tmp/moontown-portable-account-boundary"
  if !@fs.exists(root) {
    @fs.mkdir(root, recursive=true)
  }
  let account_path = root + "/accounts.json"
  let marketplace_path = root + "/marketplace.json"
  if @fs.exists(marketplace_path) {
    @fs.remove(marketplace_path)
  }
  let mut state = @account_system.empty_account_state()
  for
    (id, token, expires_at_ms) in [
      ("boundary-owner", "synthetic-boundary-owner-token", 1000UL),
      ("boundary-reader", "synthetic-boundary-reader-token", 1000UL),
      ("boundary-expired", "synthetic-boundary-expired-token", 499UL),
      ("boundary-revoked", "synthetic-boundary-revoked-token", 1000UL),
    ] {
    state = @account_system.account_register_session(
      state,
      portable_boundary_account(id),
      "session:" + id,
      token,
      active_tenant_id="portable-boundary-tenant",
      expires_at_ms~,
    )
  }
  state = @account_system.account_revoke_session(
    state,
    "synthetic-boundary-revoked-token",
    now_ms=100UL,
  )
  @fs.write_file(
    account_path,
    state.to_json().stringify(),
    create_mode=CreateOrTruncate,
  )
  let accounts = @account_system.account_application(
    account_path,
    portable_boundary_account("boundary-bootstrap"),
    "session:boundary-bootstrap",
    "synthetic-boundary-bootstrap-token",
  )
  let bootstrap = marketplace_principal_for_account(
    @account_system.account_context_for(
      portable_boundary_account("boundary-bootstrap"),
      Some("portable-boundary-tenant"),
    ),
  )
  let marketplace = @town_marketplace.marketplace_application(
    marketplace_path, bootstrap, "session:boundary-bootstrap", "synthetic-boundary-bootstrap-token",
  )
  // A persisted marketplace mirror may still be live when the account expires.
  // AccountApplication::resolve must remain the authoritative precondition.
  marketplace.synchronize_account_session(
    marketplace_principal_for_account(
      @account_system.account_context_for(
        portable_boundary_account("boundary-expired"),
        Some("portable-boundary-tenant"),
      ),
    ),
    "synthetic-boundary-expired-token",
    now_ms=400UL,
    expires_at_ms=1000UL,
  )
  let marketplace_before = @fs.read_file(marketplace_path).text()
  let mirrored : @town_marketplace.MarketplaceState = @json.from_json(
    @json.parse(marketplace_before),
  )
  assert_true(
    @town_marketplace.marketplace_principal_for_session(
      mirrored,
      "synthetic-boundary-expired-token",
      now_ms=500UL,
    )
    is Some(_),
  )
  for
    token in [
      "", "boundary-owner", "forged-principal", "local-owner-registration-id", "synthetic-boundary-expired-token",
      "synthetic-boundary-revoked-token",
    ] {
    let request = portable_boundary_request(token)
    // These are the same request extraction and real async resolver called
    // by require_account_context, without constructing a network connection.
    let supplied = request_header(request, "x-miniapp-session")
    assert_eq(
      select_marketplace_opaque_session(
        supplied, "synthetic-boundary-bootstrap-token",
      ),
      token,
    )
    assert_true(accounts.resolve(supplied, now_ms=500UL) is None)
  }
  assert_eq(@fs.read_file(marketplace_path).text(), marketplace_before)

  let owner_request = portable_boundary_request(
    "synthetic-boundary-owner-token",
  )
  let owner_token = request_header(owner_request, "x-miniapp-session")
  let owner_context = accounts.resolve(owner_token, now_ms=500UL).unwrap()
  assert_eq(owner_context.user_id, "boundary-owner")
  assert_true(
    owner_context.has_entitlement(@account_system.UseMarketplaceActions),
  )
  let owner = marketplace_principal_for_account(owner_context)
  assert_eq(owner.principal_id, "boundary-owner")
  assert_eq(owner.tenant_id, "portable-boundary-tenant")
  marketplace.synchronize_account_session(
    owner,
    owner_token,
    now_ms=500UL,
    expires_at_ms=800UL,
  )
  let digest = @town_marketplace.marketplace_token_digest(
    "synthetic-portable-source",
  )
  let source : @town_marketplace.PortableSource = {
    contract: "moonbook.portable_source.v1",
    bundle_contract: "moonbook.agent_bundle.v1",
    agent_id: "boundary-agent",
    agent_version: "1.0.0",
    book_revision: digest,
    bundle_digest: digest,
    package_filename: "boundary.moonbook-agent",
    package_size_bytes: 100,
    package_sha256: digest,
    file_count: 1,
    total_decoded_bytes: 1,
    outputs_manifest_path: None,
    outputs_manifest_digest: None,
    included_output_count: 0,
    reference_only_count: 0,
    transport: "local_file",
  }
  let draft : Json = {
    "listing_id": "agent.portable-boundary",
    "title": "Synthetic portable fixture",
    "summary": "Synthetic private portable file metadata",
    "image_ref": "asset:fixture",
    "capabilities": ["research"],
    "tags": ["fixture"],
    "action_ids": ["follow", "message"],
    "required_permissions": [],
    "pricing_summary": "Synthetic fixture only",
    "authority_ceiling": "advice-only",
    "license_class": "fixture-only",
    "rights_summary": "Synthetic data",
    "version_label": "1.0.0",
    "portable_source": source.to_json(),
    "publisher_principal_id": "forged-publisher",
    "tenant_id": "forged-tenant",
    "requester_principal_id": "forged-requester",
  }
  let operation = marketplace_operation(
    owner_request.path,
    http_method_is_get(owner_request.meth),
    http_method_is_post(owner_request.meth),
  ).unwrap()
  assert_eq(operation, "upsert-agent")
  let saved = marketplace.execute(
    owner_token,
    operation,
    draft.stringify(),
    "",
    now_ms=500UL,
  )
  let binding = bridge_object(
    bridge_object(bridge_object(saved)["payload"])["portable_binding"],
  )
  assert_eq(binding["publisher_principal_id"], "boundary-owner".to_json())
  assert_eq(binding["tenant_id"], "portable-boundary-tenant".to_json())
  let reader_request = portable_boundary_request(
    "synthetic-boundary-reader-token",
  )
  let reader_token = request_header(reader_request, "x-miniapp-session")
  let reader_context = accounts.resolve(reader_token, now_ms=500UL).unwrap()
  assert_eq(reader_context.user_id, "boundary-reader")
  marketplace.synchronize_account_session(
    marketplace_principal_for_account(reader_context),
    reader_token,
    now_ms=500UL,
    expires_at_ms=800UL,
  )
  try
    marketplace.execute(
      reader_token,
      operation,
      draft.stringify(),
      "",
      now_ms=500UL,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("valid reader account cannot overwrite the publisher's binding")
  }
  let persisted : @town_marketplace.MarketplaceState = @json.from_json(
    @json.parse(@fs.read_file(marketplace_path).text()),
  )
  assert_eq(persisted.portable_bindings.length(), 1)
  assert_eq(
    persisted.portable_bindings[0].publisher_principal_id,
    "boundary-owner",
  )
  assert_eq(persisted.action_requests.length(), 0)
  assert_eq(persisted.share_grants.length(), 0)
  assert_eq(@town_marketplace.public_listing_cards(persisted).length(), 0)
}
