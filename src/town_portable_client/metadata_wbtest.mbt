///|
async test "actual owner list exceeding 128KiB remains usable under feature-local 8MiB bound" {
  let view = fixture_view()
  let grants : Array[@transfer.PortablePackageGrant] = []
  for i in 0..<400 {
    grants.push({
      grant_id: "grant-\{i}",
      package_id: view.package_id,
      binding_digest: view.binding.binding_digest,
      package_sha256: view.binding.source.package_sha256,
      grantor_principal_id: "sender",
      grantee_principal_id: "recipient-\{i}",
      tenant_id: "tenant",
      permission: "download_package",
      created_at_ms: 100UL,
      expires_at_ms: 1000UL,
      revoked_at_ms: None,
      version: 1,
    })
  }
  let large_view = { ..view, grants, }
  let payload : Json = {
    "ok": true,
    "payload": { "packages": [large_view.to_json()] },
  }
  let bytes = @utf8.encode(payload.stringify())
  assert_true(bytes.length() > 128 * 1024)
  assert_true(bytes.length() < response_metadata_limit)
  let client = PortableClient::new(
    () => "synthetic",
    (_, _, receive) => {
      let reader = { ..observed_reader(bytes), max_chunk: 8192, }
      receive(
        {
          code: 200,
          reason: "OK",
          headers: {
            "content-type": "application/json",
            "content-length": bytes.length().to_string(),
          },
          cookies: [],
        },
        reader,
      )
    },
    limits=fixture_limits(),
  )
  let listed = client.list()
  assert_eq(listed.length(), 1)
  assert_eq(listed[0].grants.length(), 400)
  assert_eq(listed[0].binding, view.binding)
}

///|
async test "metadata response rejects declared and actual 8MiB plus one without unbounded buffering" {
  let response : @http.Response = {
    code: 200,
    reason: "OK",
    headers: {
      "content-type": "application/json",
      "content-length": (response_metadata_limit + 1).to_string(),
    },
    cookies: [],
  }
  let untouched = observed_reader(b"")
  try read_payload(response, untouched, 30000) catch {
    ClientError("invalid_content_length") => ()
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected declared response cap")
  }
  assert_eq(untouched.reads.val, 0)
  let reader = {
    ..observed_reader(Bytes::make(response_metadata_limit + 1, b'x')),
    max_chunk: 8192,
  }
  let small_header = {
    ..response,
    headers: { "content-type": "application/json", "content-length": "2" },
  }
  try read_payload(small_header, reader, 30000) catch {
    ClientError("metadata_too_large") => ()
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected counted response cap")
  }
  assert_eq(reader.offset, response_metadata_limit + 1)
}
