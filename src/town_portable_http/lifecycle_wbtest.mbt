///|
async test "listing archive denies new transfers and restore never revives withdrawal" {
  let f = fixture()
  defer @fs.rmdir(f.root, recursive=true)
  let bytes = b"archive-test-package"
  let binding = f.listing(synthetic_source(bytes))
  assert_eq(call(f.service, upload_request(binding), bytes~).code, 200)
  assert_eq(
    post(
      f.service,
      @town_contract.portable_package_grants_path(),
      draft(binding).to_json(),
    ).code,
    200,
  )
  for target in ["submitted", "published", "archived"] {
    ignore(
      f.service.marketplace.execute(
        if target == "published" {
          token("bootstrap-a")
        } else {
          token("publisher-a")
        },
        "transition-listing",
        (
          {
            "listing_id": binding.listing_id,
            "listing_kind": "agent",
            "target_state": target,
            "review_summary": "Synthetic fixture review",
          } : Json).stringify(),
        "",
        now_ms=f.now.val,
      ),
    )
  }
  assert_eq(call(f.service, download_request(binding)).code, 403)
  assert_eq(call(f.service, upload_request(binding), bytes~).code, 403)
  assert_eq(
    post(
      f.service,
      @town_contract.portable_package_grants_path(),
      draft(binding, id="archive-grant").to_json(),
    ).code,
    403,
  )
  ignore(
    f.service.marketplace.execute(
      token("publisher-a"),
      "transition-listing",
      (
        {
          "listing_id": binding.listing_id,
          "listing_kind": "agent",
          "target_state": "draft",
          "review_summary": "",
        } : Json).stringify(),
      "",
      now_ms=f.now.val,
    ),
  )
  assert_eq(call(f.service, download_request(binding)).bytes(), bytes)
  assert_eq(
    post(f.service, @town_contract.portable_package_withdraw_path(), {
      "package_id": @town_portable_transfer.package_id(binding.binding_digest),
      "binding_digest": binding.binding_digest,
    }).code,
    200,
  )
  assert_eq(call(f.service, download_request(binding)).code, 403)
  assert_eq(call(f.service, upload_request(binding), bytes~).code, 409)
}

///|
async test "package identity binding and recipient mismatches are denied without fallback" {
  let f = fixture()
  defer @fs.rmdir(f.root, recursive=true)
  let first = b"first-version"
  let second = b"second-version"
  let binding = f.listing(synthetic_source(first))
  let binding2 = f.listing(synthetic_source(second), id="agent.second")
  assert_eq(call(f.service, upload_request(binding), bytes=first).code, 200)
  assert_eq(call(f.service, upload_request(binding2), bytes=second).code, 200)
  assert_eq(
    post(
      f.service,
      @town_contract.portable_package_grants_path(),
      draft(binding).to_json(),
    ).code,
    200,
  )
  let wrong = download_request(binding)
  wrong.headers["x-town-binding-digest"] = binding2.binding_digest
  assert_true(call(f.service, wrong).code >= 400)
  assert_eq(call(f.service, download_request(binding2)).code, 403)
  assert_eq(
    post(
      f.service,
      @town_contract.portable_package_grants_path(),
      draft(binding2).to_json(),
    ).code,
    409,
  )
  assert_eq(
    post(
      f.service,
      @town_contract.portable_package_grants_path(),
      draft(binding, recipient="unrelated-a").to_json(),
    ).code,
    409,
  )
  let wrong_query = {
    ..download_request(binding),
    path: download_request(binding).path + "&package_id=another",
  }
  assert_eq(call(f.service, wrong_query).code, 400)
  assert_eq(call(f.service, download_request(binding)).bytes(), first)
}

///|
async test "download preflight reauthorizes expiry and refuses corrupt or missing indexed bytes" {
  let f = fixture()
  defer @fs.rmdir(f.root, recursive=true)
  let bytes = b"storage-exact-package"
  let binding = f.listing(synthetic_source(bytes))
  assert_eq(call(f.service, upload_request(binding), bytes~).code, 200)
  assert_eq(
    post(
      f.service,
      @town_contract.portable_package_grants_path(),
      draft(binding).to_json(),
    ).code,
    200,
  )
  let path = f.root +
    "/packages/objects/" +
    @town_portable_transfer.package_id(binding.binding_digest) +
    ".moonbook-agent"
  @fs.write_file(path, b"corrupt", create_mode=TruncateExisting)
  assert_eq(call(f.service, download_request(binding)).code, 503)
  assert_eq(call(f.service, upload_request(binding), bytes~).code, 200)
  assert_eq(call(f.service, download_request(binding)).bytes(), bytes)
  @fs.remove(path)
  assert_eq(call(f.service, download_request(binding)).code, 503)
  assert_eq(call(f.service, upload_request(binding), bytes~).code, 200)
  assert_eq(call(f.service, download_request(binding)).bytes(), bytes)
  let resolves = Ref(0)
  let expiring = {
    ..f.service,
    now: () => {
      resolves.val = resolves.val + 1
      if resolves.val >= 4 {
        100001UL
      } else {
        500UL
      }
    },
  }
  let denied = call(expiring, download_request(binding))
  assert_eq(denied.code, 401)
  assert_true(denied.closed)
  assert_false(
    denied.headers.get("content-type") == Some("application/octet-stream"),
  )
}
