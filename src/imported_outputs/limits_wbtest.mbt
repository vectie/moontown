///|
async test "preview size boundary and portable member hard limit" {
  let (home, root, selected) = fixture(@utf8.encode("x".repeat(TextLimit + 1)))
  defer @fs.rmdir(home, recursive=true)
  let text = respond(
    "GET",
    @contract.content_path(selected, mode="text"),
    home + "/missing.json",
    home,
  )
  assert_eq(
    @contract.parse_text_reply(@utf8.decode(text.body)).unwrap().state,
    "too_large",
  )
  let download = respond(
    "GET",
    @contract.content_path(selected, mode="download"),
    home + "/missing.json",
    home,
  )
  assert_eq(download.status, 200)
  assert_eq(download.body.length(), TextLimit + 1)
  // Actual filesystem size is bounded independently from the selected size.
  let file = @fs.open(root + "/" + selected.path, mode=WriteOnly)
  file.write_at(b"x", position=MemberLimit.to_int64())
  file.close()
  assert_eq(
    respond(
      "GET",
      @contract.content_path(selected, mode="download"),
      home + "/missing.json",
      home,
    ).status,
    409,
  )
  let (home, _, selected) = fixture(@utf8.encode("x".repeat(TextLimit)))
  defer @fs.rmdir(home, recursive=true)
  let text = respond(
    "GET",
    @contract.content_path(selected, mode="text"),
    home + "/missing.json",
    home,
  )
  assert_eq(
    @contract.parse_text_reply(@utf8.decode(text.body)).unwrap().content
    .unwrap()
    .length(),
    TextLimit,
  )
}

///|
async test "FIFO is rejected before open and missing members never synthesize content" {
  let (home, root, selected) = fixture(b"original")
  defer @fs.rmdir(home, recursive=true)
  @fs.remove(root + "/" + selected.path)
  assert_eq(
    respond(
      "GET",
      @contract.content_path(selected, mode="text"),
      home + "/missing.json",
      home,
    ).status,
    409,
  )
  assert_eq(@process.run("mkfifo", [root + "/" + selected.path]), 0)
  assert_eq(@fs.kind(root + "/" + selected.path, follow_symlink=false), Pipe)
  let rejected = try {
    check_path(root + "/" + selected.path, directory=false)
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
  let result = respond(
    "GET",
    @contract.content_path(selected, mode="download"),
    home + "/missing.json",
    home,
  )
  assert_eq(result.status, 409)
}

///|
async test "receipt current-root and local identity are distinct from sender identity" {
  let (home, root, selected) = fixture(b"original")
  defer @fs.rmdir(home, recursive=true)
  let receipt_path = root + "/state/portable-source-binding.json"
  let receipt = @json.parse(@fs.read_file(receipt_path).text())
  guard receipt is Object(fields) else { fail("fixture") }
  fields["local_book_id"] = "sender-agent".to_json()
  @fs.write_file(receipt_path, receipt.stringify(), create=0o600, truncate=true)
  assert_eq(
    discover(home + "/missing.json", home).books[0].state,
    "unavailable",
  )
  assert_eq(
    respond(
      "GET",
      @contract.content_path(selected, mode="text"),
      home + "/missing.json",
      home,
    ).status,
    409,
  )
  fields["local_book_id"] = "recipient".to_json()
  fields["local_target_root"] = (home + "/another-recipient").to_json()
  @fs.write_file(receipt_path, receipt.stringify(), create=0o600, truncate=true)
  assert_eq(
    discover(home + "/missing.json", home).books[0].state,
    "unavailable",
  )
}

///|
async test "reference-only manifest entries are never fetched or opened" {
  let (home, root, selected) = fixture(b"original")
  defer @fs.rmdir(home, recursive=true)
  let output : @contract.Output = {
    artifact_id: "reference",
    label: "External declaration",
    mime_type: "text/html",
    included: false,
    reference: Some("http://127.0.0.1:1/must-never-fetch"),
    declared_digest: Some(hash(b"reference")),
    files: [],
    preview_path: None,
    app_entrypoint: None,
  }
  let manifest : Json = {
    "contract": "moonbook.portable_outputs.v1",
    "outputs": [output],
  }
  let bytes = @utf8.encode(manifest.stringify())
  @fs.write_file(
    root + "/portable/outputs.manifest.v1.json",
    bytes,
    create=0o600,
    truncate=true,
  )
  let receipt_path = root + "/state/portable-source-binding.json"
  let receipt = @json.parse(@fs.read_file(receipt_path).text())
  guard receipt is Object(fields) &&
    fields.get("source") is Some(Object(source)) else {
    fail("fixture")
  }
  source["outputs_manifest_digest"] = hash(bytes).to_json()
  source["included_output_count"] = (0).to_json()
  source["reference_only_count"] = (1).to_json()
  @fs.write_file(receipt_path, receipt.stringify(), create=0o600, truncate=true)
  let catalog = discover(home + "/missing.json", home)
  assert_eq(catalog.books[0].outputs[0].reference, output.reference)
  assert_eq(catalog.books[0].state, "ready")
  assert_eq(
    respond(
      "GET",
      @contract.content_path(
        {
          ..selected,
          artifact_id: "reference",
          path: "portable/outputs/reference/content.txt",
          manifest_sha256: hash(bytes),
        },
        mode="text",
      ),
      home + "/missing.json",
      home,
    ).status,
    409,
  )
}

///|
async test "strict UTF-8 preserves BOM CRLF and escaped controls exactly" {
  let bytes = @utf8.encode("\uFEFF<script>\"\\\r\n学习\t😀")
  let (home, _, selected) = fixture(bytes)
  defer @fs.rmdir(home, recursive=true)
  let response = respond(
    "GET",
    @contract.content_path(selected, mode="text"),
    home + "/missing.json",
    home,
  )
  let reply = @contract.parse_text_reply(@utf8.decode(response.body)).unwrap()
  assert_eq(@utf8.encode(reply.content.unwrap()), bytes)
}
