///|
async test "authoritative sessions deny unread raw bodies despite live marketplace mirrors and forged identity" {
  let f = fixture()
  defer @fs.rmdir(f.root, recursive=true)
  let binding = f.listing(synthetic_source(b"original-package"))
  let mirror : @town_marketplace.MarketplaceState = @json.from_json(
    @json.parse(@fs.read_file(f.root + "/marketplace.json").text()),
  )
  assert_true(
    @town_marketplace.marketplace_principal_for_session(
      mirror,
      token("expired-a"),
      now_ms=500UL,
    )
    is Some(_),
  )
  for
    supplied in [
      "",
      "reader-a",
      "forged-account",
      token("expired-a"),
      token("revoked-a"),
    ] {
    let consumed = Ref(0)
    let body = observed_reader(b"original-package", consumed)
    let record = recording()
    let request = upload_request(binding, session=supplied)
    request.headers["x-miniapp-user-id"] = "publisher-a"
    request.headers["x-miniapp-tenant"] = "town-a"
    assert_true(f.service.handle(request, body, record.sink()))
    assert_eq(record.code, 401)
    assert_true(record.closed)
    assert_eq(consumed.val, 0)
  }
  for id in ["reader-a", "wrong-tenant", "no-publish", "visitor-a"] {
    let consumed = Ref(0)
    let body = observed_reader(b"original-package", consumed)
    let record = recording()
    assert_true(
      f.service.handle(
        upload_request(binding, session=token(id)),
        body,
        record.sink(),
      ),
    )
    assert_eq(record.code, 403)
    assert_true(record.closed)
    assert_eq(consumed.val, 0)
  }
}

///|
async test "metadata and byte grants revoke independently without recipient upgrade" {
  let f = fixture()
  defer @fs.rmdir(f.root, recursive=true)
  let bytes = b"separate-byte-authority"
  let binding = f.listing(synthetic_source(bytes))
  ignore(
    f.service.marketplace.execute(
      token("publisher-a"),
      "share-grant",
      (
        {
          "grant_id": "card-only",
          "resource_kind": "agent",
          "resource_id": binding.listing_id,
          "grantee_principal_id": "reader-a",
          "permission": "collaborate",
          "expires_at_ms": 10000,
        } : Json).stringify(),
      "",
      now_ms=f.now.val,
    ),
  )
  assert_eq(call(f.service, upload_request(binding), bytes~).code, 200)
  assert_eq(call(f.service, download_request(binding)).code, 403)
  assert_eq(
    post(
      f.service,
      @town_contract.portable_package_grants_path(),
      draft(binding).to_json(),
    ).code,
    200,
  )
  ignore(
    f.service.marketplace.execute(
      token("publisher-a"),
      "revoke-share-grant",
      ({ "grant_id": "card-only" } : Json).stringify(),
      "",
      now_ms=f.now.val,
    ),
  )
  assert_eq(call(f.service, download_request(binding)).bytes(), bytes)
  assert_eq(
    post(f.service, @town_contract.portable_package_revoke_path(), {
      "grant_id": "grant-v1",
    }).code,
    200,
  )
  assert_eq(call(f.service, download_request(binding)).code, 403)
}

///|
async test "legacy view message collaborate artifact and public access never authorize bytes" {
  let f = fixture()
  defer @fs.rmdir(f.root, recursive=true)
  let bytes = b"original-private-raw-package"
  let binding = f.listing(synthetic_source(bytes))
  for permission in ["view", "message", "collaborate"] {
    let payload : Json = {
      "grant_id": "legacy-" + permission,
      "resource_kind": "agent",
      "resource_id": binding.listing_id,
      "grantee_principal_id": "reader-a",
      "permission": permission,
      "expires_at_ms": 10000,
    }
    ignore(
      f.service.marketplace.execute(
        token("publisher-a"),
        "share-grant",
        payload.stringify(),
        "",
        now_ms=f.now.val,
      ),
    )
    assert_eq(call(f.service, download_request(binding)).code, 403)
  }
  ignore(
    f.service.marketplace.execute(
      token("publisher-a"),
      "share-grant",
      (
        {
          "grant_id": "legacy-artifact",
          "resource_kind": "artifact",
          "resource_id": "artifact:publisher-a:raw-package",
          "grantee_principal_id": "reader-a",
          "permission": "collaborate",
          "expires_at_ms": 10000,
        } : Json).stringify(),
      "",
      now_ms=f.now.val,
    ),
  )
  let private_state : @town_marketplace.MarketplaceState = @json.from_json(
    @json.parse(@fs.read_file(f.root + "/marketplace.json").text()),
  )
  // Synthetic state models an independently published card. Visibility is
  // deliberately present; it must still convey no byte authority.
  let before = {
    ..private_state,
    agent_listings: private_state.agent_listings.map(listing => {
      ..listing,
      lifecycle: {
        ..listing.lifecycle,
        state: @town_marketplace.PublicationPublished,
        published_at_ms: Some(400UL),
      },
    }),
  }
  @fs.write_file(
    f.root + "/marketplace.json",
    before.to_json().stringify(),
    create_mode=TruncateExisting,
  )
  let public_before = @town_marketplace.public_listing_index_export(before)
  assert_true(public_before.stringify().contains(binding.listing_id))
  assert_eq(call(f.service, download_request(binding)).code, 403)
  assert_eq(call(f.service, upload_request(binding), bytes~).code, 200)
  assert_eq(call(f.service, download_request(binding)).code, 403)
  assert_eq(
    call(f.service, download_request(binding, session=token("unrelated-a"))).code,
    403,
  )
  let listing = call(f.service, {
    meth: @http.Get,
    path: @town_contract.portable_packages_path(),
    headers: { "x-miniapp-session": token("reader-a") },
  })
  assert_eq(listing.payload(), { "packages": [] })
  let after : @town_marketplace.MarketplaceState = @json.from_json(
    @json.parse(@fs.read_file(f.root + "/marketplace.json").text()),
  )
  assert_eq(before, after)
  assert_eq(public_before, @town_marketplace.public_listing_index_export(after))
  assert_true(
    call(f.service, download_request(binding, session=token("publisher-a"))).bytes() ==
    bytes,
  )
  // A metadata preview still contains only its old declaration, with no new
  // byte-grant recipients or mutations from upload.
  let preview = f.service.marketplace.execute(
    token("publisher-a"),
    "share-preview",
    (
      {
        "resource_kind": "agent",
        "resource_id": binding.listing_id,
        "grantee_principal_id": "reader-a",
      } : Json).stringify(),
    "",
    now_ms=f.now.val,
  )
  assert_false(preview.stringify().contains("download_package"))
}

///|
async test "explicit byte grants preview expiry immutable retry revoke and withdrawal are separate decisions" {
  let f = fixture()
  defer @fs.rmdir(f.root, recursive=true)
  let bytes = b"entire-private-package"
  let binding = f.listing(synthetic_source(bytes))
  assert_eq(call(f.service, upload_request(binding), bytes~).code, 200)
  for recipient in ["unknown-a", "wrong-tenant"] {
    assert_eq(
      post(
        f.service,
        @town_contract.portable_package_grants_path(),
        draft(binding, recipient~).to_json(),
      ).code,
      403,
    )
  }
  let decision = draft(binding)
  let preview = post(
    f.service,
    @town_contract.portable_package_preview_path(),
    decision.to_json(),
  )
  assert_eq(preview.code, 200)
  assert_true(preview.payload().stringify().contains("entire exact package"))
  assert_eq(call(f.service, download_request(binding)).code, 403)
  let grant = post(
    f.service,
    @town_contract.portable_package_grants_path(),
    decision.to_json(),
  )
  assert_eq(grant.code, 200)
  assert_eq(
    post(
      f.service,
      @town_contract.portable_package_grants_path(),
      decision.to_json(),
    ).payload(),
    grant.payload(),
  )
  assert_eq(
    post(
      f.service,
      @town_contract.portable_package_grants_path(),
      draft(binding, expiry=11000UL).to_json(),
    ).code,
    409,
  )
  assert_eq(call(f.service, download_request(binding)).bytes(), bytes)
  // A recipient list never discloses another recipient's byte grants.
  let listed = call(f.service, {
    meth: @http.Get,
    path: @town_contract.portable_packages_path(),
    headers: { "x-miniapp-session": token("reader-a") },
  })
  assert_true(listed.payload().stringify().contains("\"grants\":[]"))
  assert_eq(
    post(f.service, @town_contract.portable_package_revoke_path(), {
      "grant_id": decision.grant_id,
    }).code,
    200,
  )
  assert_eq(call(f.service, download_request(binding)).code, 403)
  assert_eq(
    post(
      f.service,
      @town_contract.portable_package_grants_path(),
      decision.to_json(),
    ).code,
    409,
  )
  let short = draft(binding, id="grant-short", expiry=600UL)
  assert_eq(
    post(
      f.service,
      @town_contract.portable_package_grants_path(),
      short.to_json(),
    ).code,
    200,
  )
  f.now.val = 600UL
  assert_eq(call(f.service, download_request(binding)).code, 403)
  let again = draft(binding, id="grant-again")
  assert_eq(
    post(
      f.service,
      @town_contract.portable_package_grants_path(),
      again.to_json(),
    ).code,
    200,
  )
  let withdrawn = post(
    f.service,
    @town_contract.portable_package_withdraw_path(),
    {
      "package_id": decision.package_id,
      "binding_digest": binding.binding_digest,
    },
  )
  assert_eq(withdrawn.code, 200)
  assert_eq(call(f.service, download_request(binding)).code, 403)
  assert_eq(call(f.service, upload_request(binding), bytes~).code, 409)
  let restarted = {
    ..f.service,
    store: @town_portable_transfer.portable_store(
      f.root + "/packages",
      limits=f.service.limits,
    ),
  }
  assert_eq(call(restarted, download_request(binding)).code, 403)
}

///|
async test "long uploads re-resolve actual account expiry revoke and active tenant before commit" {
  for mutation in ["expiry", "revoke", "tenant"] {
    let f = fixture()
    let bytes = b"delayed-exact-package"
    let binding = f.listing(synthetic_source(bytes))
    let record = recording()
    let reader = @io.MemoryReader(writer => {
      writer.write(bytes)
      if mutation == "expiry" {
        f.now.val = 100001UL
      }
      if mutation == "revoke" {
        f.service.accounts.logout(token("publisher-a"), now_ms=f.now.val)
      }
      if mutation == "tenant" {
        ignore(
          f.service.accounts.switch_tenant(
            token("publisher-a"),
            None,
            now_ms=f.now.val,
          ),
        )
      }
    })
    assert_true(
      f.service.handle(upload_request(binding), reader, record.sink()),
    )
    reader.close()
    assert_true(record.code >= 400)
    assert_true(record.closed)
    let listed = f.service.store.list(
      @town_portable_transfer.actor_for_account(
        @account_system.account_context_for(
          test_account("publisher-a"),
          Some("town-a"),
        ),
      ),
      500UL,
    )
    assert_false(listed.any(view => view.status == "available"))
    @fs.rmdir(f.root, recursive=true)
  }
}

///|
async test "malformed authoritative files fail closed without replacing them" {
  let f = fixture()
  defer @fs.rmdir(f.root, recursive=true)
  let bytes = b"exact-package"
  let binding = f.listing(synthetic_source(bytes))
  let path = f.root + "/marketplace.json"
  @fs.write_file(path, "not JSON", create_mode=TruncateExisting)
  assert_eq(call(f.service, upload_request(binding), bytes~).code, 503)
  assert_eq(@fs.read_file(path).text(), "not JSON")
  @fs.write_file(
    f.root + "/accounts.json",
    "not JSON either",
    create_mode=TruncateExisting,
  )
  assert_eq(call(f.service, upload_request(binding), bytes~).code, 503)
  assert_eq(@fs.read_file(f.root + "/accounts.json").text(), "not JSON either")
}
