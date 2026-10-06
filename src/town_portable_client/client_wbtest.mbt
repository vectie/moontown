///|
async test "production upload callback streams original bytes with exact per request headers" {
  with_temp(root => {
    let file = root + "/original.moonbook-agent"
    @fs.write_file(file, fixture_bytes, create_mode=CreateNew)
    let view = fixture_view()
    let calls = Ref(0)
    let supplied = Ref(0)
    let exchange : Exchange = (request, send, receive) => {
      calls.val += 1
      assert_eq(request.meth, Put)
      assert_eq(request.path, route_root + "/content?listing_id=listing-v1")
      assert_eq(
        request.headers.get("x-miniapp-session"),
        Some("synthetic-session"),
      )
      assert_eq(request.headers.get("accept-encoding"), Some("identity"))
      assert_eq(request.headers.get("content-length"), Some("12"))
      assert_eq(
        request.headers.get("content-type"),
        Some("application/octet-stream"),
      )
      assert_eq(
        request.headers.get("x-town-binding-digest"),
        Some(view.binding.binding_digest),
      )
      assert_false(request.headers.contains("transfer-encoding"))
      let writer : RecordingWriter = { buffer: Buffer(), writes: [], }
      send(writer)
      assert_eq(writer.buffer.contents(), fixture_bytes)
      assert_true(writer.writes.all(size => size <= 3))
      assert_eq(writer.writes.length(), 4)
      respond_json(view.to_json(), receive)
    }
    let client = PortableClient::new(
      () => {
        supplied.val += 1
        "synthetic-session"
      },
      exchange,
      limits=fixture_limits(),
    )
    assert_eq(client.upload(file, "listing-v1", view.binding), view)
    assert_eq(calls.val, 1)
    assert_eq(supplied.val, 1)
    assert_eq(@fs.read_file(file).binary(), fixture_bytes)
  })
}

///|
async test "upload preflight rejects size digest symlink or wrong binding before transport or session" {
  with_temp(root => {
    let calls = Ref(0)
    let client = PortableClient::new(
      () => {
        calls.val += 1
        "synthetic"
      },
      (_, _, _) => calls.val += 1,
      limits=fixture_limits(),
    )
    let binding = fixture_binding()
    for bytes in [b"short", b"abcdefghijkl"] {
      let file = root + "/bad"
      @fs.write_file(file, bytes, create_mode=CreateOrTruncate)
      try client.upload(file, "listing-v1", binding) catch {
        ClientError(_) => ()
      } noraise {
        _ => fail("expected local rejection")
      }
      assert_eq(calls.val, 0)
    }
    @fs.symlink(target=root + "/bad", root + "/link")
    try client.upload(root + "/link", "listing-v1", binding) catch {
      ClientError("local_package_not_regular") => ()
    } noraise {
      _ => fail("expected symlink rejection")
    }
    try client.upload(root + "/bad", "wrong", binding) catch {
      ClientError("listing_identity_mismatch") => ()
    } noraise {
      _ => fail("expected listing rejection")
    }
    assert_eq(calls.val, 0)
  })
}

///|
async test "upload detects source mutation after preflight using same descriptor" {
  with_temp(root => {
    let file = root + "/original"
    @fs.write_file(file, fixture_bytes, create_mode=CreateNew)
    let client = PortableClient::new(
      () => {
        @fs.write_file(file, b"abcdefghijkl", create_mode=TruncateExisting)
        "synthetic"
      },
      (_, send, _) => {
        let writer : RecordingWriter = { buffer: Buffer(), writes: [], }
        send(writer)
      },
      limits=fixture_limits(),
    )
    try client.upload(file, "listing-v1", fixture_binding()) catch {
      ClientError("local_package_digest_mismatch") => ()
    } noraise {
      _ => fail("expected changed original rejection")
    }
  })
}

///|
async test "download fetches exact authorized list then streams selected bytes with fresh session" {
  with_temp(root => {
    let view = fixture_view()
    let calls = Ref(0)
    let session_calls = Ref(0)
    let output = root + "/downloaded"
    let client = PortableClient::new(
      () => {
        session_calls.val += 1
        "synthetic-\{session_calls.val}"
      },
      (request, send, receive) => {
        calls.val += 1
        assert_eq(request.meth, Get)
        assert_eq(request.headers.get("accept-encoding"), Some("identity"))
        assert_eq(request.headers.get("content-length"), Some("0"))
        assert_eq(
          request.headers.get("x-miniapp-session"),
          Some("synthetic-\{calls.val}"),
        )
        let writer : RecordingWriter = { buffer: Buffer(), writes: [], }
        send(writer)
        assert_eq(writer.buffer.length(), 0)
        if calls.val == 1 {
          assert_eq(request.path, route_root)
          respond_json({ "packages": [view.to_json()] }, receive)
        } else {
          assert_eq(
            request.path,
            route_root + "/content?package_id=" + view.package_id,
          )
          assert_eq(
            request.headers.get("x-town-binding-digest"),
            Some(view.binding.binding_digest),
          )
          receive(
            fixture_response(view),
            observed_reader(fixture_bytes, hidden_path=output),
          )
        }
      },
      limits=fixture_limits(),
    )
    let result = client.download(view.package_id, view.binding, output)
    assert_eq(@fs.read_file(result.package_path).binary(), fixture_bytes)
    assert_eq(calls.val, 2)
    assert_eq(session_calls.val, 2)
  })
}

///|
async test "download denies absent duplicate mismatched and unreceipted list without requesting content" {
  with_temp(root => {
    let view = fixture_view()
    for
      packages in [
        [],
        [view.to_json(), view.to_json()],
        [
          { ..view, binding: { ..view.binding, listing_id: "other", }, }.to_json(),
        ],
        [{ ..view, receipt: None, }.to_json()],
      ] {
      let calls = Ref(0)
      let client = PortableClient::new(
        () => "synthetic",
        (request, _, receive) => {
          calls.val += 1
          assert_eq(request.path, route_root)
          respond_json({ "packages": packages.to_json() }, receive)
        },
        limits=fixture_limits(),
      )
      try client.download(view.package_id, view.binding, root + "/file") catch {
        ClientError(_) => ()
      } noraise {
        _ => fail("expected exact selection denial")
      }
      assert_eq(calls.val, 1)
      assert_eq(@fs.readdir(root).length(), 0)
    }
  })
}

///|
async test "preview share revoke withdraw use bounded exact control wire without token in JSON" {
  let view = fixture_view()
  let draft : @transfer.GrantDraft = {
    package_id: view.package_id,
    binding_digest: view.binding.binding_digest,
    grantee_principal_id: "recipient",
    grant_id: "new-grant",
    expires_at_ms: 1000UL,
  }
  let grant : @transfer.PortablePackageGrant = {
    grant_id: draft.grant_id,
    package_id: draft.package_id,
    binding_digest: draft.binding_digest,
    package_sha256: view.binding.source.package_sha256,
    grantor_principal_id: "sender",
    grantee_principal_id: "recipient",
    tenant_id: "tenant",
    permission: "download_package",
    created_at_ms: 100UL,
    expires_at_ms: 1000UL,
    revoked_at_ms: None,
    version: 1,
  }
  let calls = Ref(0)
  let client = PortableClient::new(
    () => "synthetic-session",
    (request, send, receive) => {
      calls.val += 1
      assert_eq(request.meth, Post)
      let writer : RecordingWriter = { buffer: Buffer(), writes: [], }
      send(writer)
      let bytes = writer.buffer.contents()
      assert_eq(
        request.headers.get("content-length"),
        Some(bytes.length().to_string()),
      )
      assert_eq(request.headers.get("content-type"), Some("application/json"))
      assert_false(@utf8.decode(bytes).contains("synthetic-session"))
      let json = @json.parse(@utf8.decode(bytes))
      match calls.val {
        1 => {
          assert_eq(request.path, route_root + "/shares/preview")
          assert_eq(json, draft.to_json())
          respond_json({ "disclosure": "entire package" }, receive)
        }
        2 => {
          assert_eq(request.path, route_root + "/share-grants")
          assert_eq(json, draft.to_json())
          respond_json(grant.to_json(), receive)
        }
        3 => {
          assert_eq(request.path, route_root + "/share-grants/revoke")
          assert_eq(json, { "grant_id": draft.grant_id })
          respond_json(
            { ..grant, revoked_at_ms: Some(200UL), }.to_json(),
            receive,
          )
        }
        _ => {
          assert_eq(request.path, route_root + "/withdraw")
          assert_eq(json, {
            "package_id": view.package_id,
            "binding_digest": view.binding.binding_digest,
          })
          respond_json({ ..view, status: "withdrawn", }.to_json(), receive)
        }
      }
    },
    limits=fixture_limits(),
  )
  let _ = client.preview_share(draft)
  assert_eq(calls.val, 1)
  assert_eq(client.share(draft), grant)
  assert_true(client.revoke(draft.grant_id).revoked_at_ms is Some(_))
  assert_eq(client.withdraw(view.package_id, view.binding).status, "withdrawn")
  assert_eq(calls.val, 4)
}

///|
test "native origin seam accepts origins without connecting and rejects credential redirect ambiguity" {
  for
    base in [
      "https://town.example", "https://town.example/", "http://127.0.0.1:8080",
    ] {
    let _ = native_exchange(base)
  }
  for
    base in [
      "https://user:secret@town.example", "file:///tmp/town", "https://town.example/path",
      "https://town.example?token=secret", "https://town.example/#x", "https://town.example\r\nX: value",
    ] {
    try native_exchange(base) catch {
      ClientError("invalid_base_url") => ()
    } noraise {
      _ => fail("expected invalid origin")
    }
  }
  for
    raw in [
      "-1", "1,1", "1 1", "1.0", "+1", "", "999999999999999999999999999999",
    ] {
    try decimal_length(raw, 1024) catch {
      ClientError(_) => ()
    } noraise {
      _ => fail("expected invalid length")
    }
  }
  assert_eq(decimal_length("1024", 1024), 1024)
  try decimal_length("1025", 1024) catch {
    ClientError(_) => ()
  } noraise {
    _ => fail("expected limit rejection")
  }
}

///|
async test "explicit stdin session is bounded and errors cannot reflect secrets" {
  assert_eq(
    read_session(observed_reader(b"synthetic-session\n")),
    "synthetic-session",
  )
  for bytes in [b"", b"two tokens", b"line1\nline2", b"bad\x00token"] {
    try read_session(observed_reader(bytes)) catch {
      ClientError("invalid_session") => ()
    } noraise {
      _ => fail("expected invalid session")
    }
  }
  let calls = Ref(0)
  let client = PortableClient::new(() => "bad\nsecret", (_, _, _) => {
    calls.val += 1
  })
  try client.list() catch {
    ClientError("invalid_session") => ()
  } noraise {
    _ => fail("expected invalid header token")
  }
  assert_eq(calls.val, 0)
}
