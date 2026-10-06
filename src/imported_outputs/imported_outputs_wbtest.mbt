///|
async fn fixture(
  bytes : Bytes,
  name? : String = "recipient",
) -> (String, String, @contract.Selection) {
  let home = @fs.realpath(@fs.tmpdir(prefix="town-imported-output-"))
  let root = home + "/" + name
  @fs.mkdir(root + "/state", recursive=true)
  @fs.mkdir(root + "/portable/outputs/result", recursive=true)
  @fs.write_file(
    root + "/book.toml",
    "[book]\ntitle = \"Recipient title\"\n",
    create=0o600,
    truncate=true,
  )
  @fs.write_file(
    root + "/portable/outputs/result/content.txt",
    bytes,
    create=0o600,
    truncate=true,
  )
  let output : @contract.Output = {
    artifact_id: "result",
    label: "Inert result",
    mime_type: "text/html",
    included: true,
    reference: None,
    declared_digest: None,
    files: [
      {
        path: "portable/outputs/result/content.txt",
        size_bytes: bytes.length(),
        digest: hash(bytes),
      },
    ],
    preview_path: Some("portable/outputs/result/content.txt"),
    app_entrypoint: Some("portable/outputs/result/content.txt"),
  }
  let manifest : Json = {
    "contract": "moonbook.portable_outputs.v1",
    "outputs": [output],
  }
  let manifest_bytes = @utf8.encode(manifest.stringify())
  @fs.write_file(
    root + "/portable/outputs.manifest.v1.json",
    manifest_bytes,
    create=0o600,
    truncate=true,
  )
  let source : Json = {
    "contract": "moonbook.portable_source.v1",
    "bundle_contract": "moonbook.agent_bundle.v1",
    "agent_id": "sender-agent",
    "agent_version": "v1",
    "book_revision": hash(b"revision"),
    "bundle_digest": hash(b"bundle"),
    "package_filename": "sender.moonbook-agent",
    "package_size_bytes": 100,
    "package_sha256": hash(b"original-package"),
    "file_count": 2,
    "total_decoded_bytes": bytes.length(),
    "outputs_manifest_path": "portable/outputs.manifest.v1.json",
    "outputs_manifest_digest": hash(manifest_bytes),
    "included_output_count": 1,
    "reference_only_count": 0,
    "transport": "local_file",
  }
  let receipt : Json = {
    "contract": "moonbook.portable_import_receipt.v1",
    "source": source,
    "listing_id": "fixture",
    "publisher_principal_id": "publisher",
    "tenant_id": "tenant",
    "binding_digest": hash(b"binding"),
    "installation_receipt_id": "install",
    "local_target_root": root,
    "local_book_id": name,
    "imported_at": "1",
    "member_bytes_verified": true,
    "status": "complete",
  }
  @fs.write_file(
    root + "/state/portable-source-binding.json",
    receipt.stringify(),
    create=0o600,
    truncate=true,
  )
  (
    home,
    root,
    {
      book_handle: handle(root),
      package_sha256: hash(b"original-package"),
      manifest_sha256: hash(manifest_bytes),
      artifact_id: "result",
      path: "portable/outputs/result/content.txt",
      digest: hash(bytes),
      size_bytes: bytes.length(),
    },
  )
}

///|
async test "exact source text download and HEAD are inert and read only" {
  let bytes = @utf8.encode(
    "<script>never_execute()</script>\n学习结果 😀",
  )
  let (home, root, selected) = fixture(bytes, name="recipient 学习")
  defer @fs.rmdir(home, recursive=true)
  let receipt_before = @fs.read_file(
    root + "/state/portable-source-binding.json",
  ).binary()
  let manifest_before = @fs.read_file(
    root + "/portable/outputs.manifest.v1.json",
  ).binary()
  let catalog = discover(home + "/missing-catalog.json", home)
  assert_eq(catalog.state, "ready")
  assert_eq(catalog.books.length(), 1)
  assert_eq(catalog.books[0].book_id, "recipient 学习")
  assert_eq(catalog.books[0].name, "Recipient title")
  assert_eq(catalog.books[0].source.unwrap().agent_id, "sender-agent")
  assert_true(@contract.parse_catalog(catalog.to_json().stringify()) is Some(_))
  let text = respond(
    "GET",
    @contract.content_path(selected, mode="text"),
    home + "/missing-catalog.json",
    home,
  )
  assert_eq(text.status, 200)
  assert_eq(
    @contract.parse_text_reply(@utf8.decode(text.body)).unwrap().content,
    Some(@utf8.decode(bytes)),
  )
  let download = respond(
    "GET",
    @contract.content_path(selected, mode="download"),
    home + "/missing-catalog.json",
    home,
  )
  assert_eq(download.body, bytes)
  assert_eq(
    download.headers.get("Content-Type"),
    Some("application/octet-stream"),
  )
  assert_eq(download.headers.get("X-Content-Type-Options"), Some("nosniff"))
  assert_eq(download.headers.get("Cache-Control"), Some("no-store"))
  assert_true(
    download.headers
    .get("Content-Disposition")
    .unwrap()
    .has_prefix("attachment;"),
  )
  let head = respond(
    "HEAD",
    @contract.content_path(selected, mode="download"),
    home + "/missing-catalog.json",
    home,
  )
  assert_eq(head.body, b"")
  assert_eq(head.headers.get("Content-Length"), None)
  for key, value in download.headers {
    if key != "Content-Length" {
      assert_eq(head.headers.get(key), Some(value))
    }
  }
  assert_false(@fs.exists(home + "/missing-catalog.json"))
  assert_eq(
    @fs.read_file(root + "/state/portable-source-binding.json").binary(),
    receipt_before,
  )
  assert_eq(
    @fs.read_file(root + "/portable/outputs.manifest.v1.json").binary(),
    manifest_before,
  )
  assert_eq(@fs.read_file(root + "/" + selected.path).binary(), bytes)
}

///|
async test "empty and binary strict text semantics" {
  for
    (bytes, expected) in [
      (b"", "ready"),
      (b"\xff\xfe", "opaque"),
      (b"a\x00b", "opaque"),
      (b"a\x7fb", "opaque"),
    ] {
    let (home, _, selected) = fixture(bytes)
    defer @fs.rmdir(home, recursive=true)
    let text = respond(
      "GET",
      @contract.content_path(selected, mode="text"),
      home + "/missing.json",
      home,
    )
    let parsed = @contract.parse_text_reply(@utf8.decode(text.body)).unwrap()
    assert_eq(parsed.state, expected)
    if expected == "ready" {
      assert_eq(parsed.content, Some(""))
    }
    assert_eq(
      respond(
        "GET",
        @contract.content_path(selected, mode="download"),
        home + "/missing.json",
        home,
      ).body,
      bytes,
    )
  }
}

///|
async test "changed member source manifest and traversal fail closed" {
  let (home, root, selected) = fixture(b"original")
  defer @fs.rmdir(home, recursive=true)
  let target = @contract.content_path(selected, mode="text")
  @fs.write_file(
    root + "/" + selected.path,
    b"modified",
    create=0o600,
    truncate=true,
  )
  assert_eq(respond("GET", target, home + "/missing.json", home).status, 409)
  @fs.write_file(
    root + "/" + selected.path,
    b"original",
    create=0o600,
    truncate=true,
  )
  for
    changed in [
      { ..selected, package_sha256: hash(b"different"), },
      { ..selected, manifest_sha256: hash(b"different"), },
      { ..selected, digest: hash(b"different"), },
      { ..selected, size_bytes: 7, },
    ] {
    assert_eq(
      respond(
        "GET",
        @contract.content_path(changed, mode="download"),
        home + "/missing.json",
        home,
      ).status,
      409,
    )
  }
  for
    path in [
      "../book.toml", "/etc/passwd", "portable/outputs/result/../../book.toml", "portable/outputs/result/./content.txt",
      "portable/outputs/result//content.txt", "portable/outputs/result/x\\y",
    ] {
    assert_eq(
      respond(
        "GET",
        @contract.content_path({ ..selected, path, }, mode="text"),
        home + "/missing.json",
        home,
      ).status,
      400,
    )
  }
  assert_eq(
    respond("GET", target + "&path=duplicate", home + "/missing.json", home).status,
    400,
  )
  assert_eq(
    respond("POST", "/api/imported-outputs", home + "/missing.json", home).status,
    405,
  )
  @fs.write_file(
    root + "/portable/outputs.manifest.v1.json",
    "{}",
    create=0o600,
    truncate=true,
  )
  assert_eq(respond("GET", target, home + "/missing.json", home).status, 409)
  assert_eq(
    discover(home + "/missing.json", home).books[0].state,
    "unavailable",
  )
}

///|
async test "symlink leaf and parent are rejected before read" {
  let (home, root, selected) = fixture(b"original")
  defer @fs.rmdir(home, recursive=true)
  @fs.write_file(home + "/outside", b"original", create=0o600, truncate=true)
  @fs.remove(root + "/" + selected.path)
  @fs.symlink(target=home + "/outside", root + "/" + selected.path)
  assert_eq(
    respond(
      "GET",
      @contract.content_path(selected, mode="download"),
      home + "/missing.json",
      home,
    ).status,
    409,
  )
  @fs.remove(root + "/" + selected.path)
  @fs.rmdir(root + "/portable/outputs/result")
  @fs.mkdir(home + "/outside-dir")
  @fs.write_file(
    home + "/outside-dir/content.txt",
    b"original",
    create=0o600,
    truncate=true,
  )
  @fs.symlink(target=home + "/outside-dir", root + "/portable/outputs/result")
  assert_eq(
    respond(
      "GET",
      @contract.content_path(selected, mode="text"),
      home + "/missing.json",
      home,
    ).status,
    409,
  )
}

///|
async test "ordinary installations are unsupported and catalog roots discovered read only" {
  let (home, root, _) = fixture(b"original")
  defer @fs.rmdir(home, recursive=true)
  @fs.remove(root + "/state/portable-source-binding.json")
  @fs.write_file(
    root + "/state/agent-installation.json",
    "{}",
    create=0o600,
    truncate=true,
  )
  let catalog_path = home + "/catalog.json"
  @fs.write_file(
    catalog_path,
    (
      [
        {
          "id": "stale-catalog-id",
          "name": "Stale catalog name",
          "workspace_root": root,
        },
      ] : Json).stringify(),
    create=0o600,
    truncate=true,
  )
  let before = @fs.read_file(catalog_path).binary()
  let result = discover(catalog_path, home + "/unrelated")
  assert_eq(result.books[0].state, "unsupported")
  assert_eq(result.books[0].book_id, "recipient")
  assert_eq(result.books[0].name, "Recipient title")
  assert_eq(@fs.read_file(catalog_path).binary(), before)
}
