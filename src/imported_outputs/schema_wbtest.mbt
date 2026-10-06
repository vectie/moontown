///|
async fn replace_test_manifest(
  root : String,
  outputs : Array[@contract.Output],
) -> Unit {
  let manifest : Json = {
    "contract": "moonbook.portable_outputs.v1",
    "outputs": outputs,
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
  source["included_output_count"] = outputs
    .filter(output => output.included)
    .length()
    .to_json()
  source["reference_only_count"] = outputs
    .filter(output => !output.included)
    .length()
    .to_json()
  @fs.write_file(receipt_path, receipt.stringify(), create=0o600, truncate=true)
}

///|
async test "hash-matched malformed manifests reject member schemas and duplicate identities" {
  let (home, root, _) = fixture(b"original")
  defer @fs.rmdir(home, recursive=true)
  let output = discover(home + "/missing.json", home).books[0].outputs[0]
  let file = output.files[0]
  let cases : Array[Array[@contract.Output]] = [
    [output, output],
    [{ ..output, files: [file, file], }],
    [
      {
        ..output,
        files: [{ ..file, path: "portable/outputs/result/../outside", }],
      },
    ],
    [{ ..output, files: [{ ..file, size_bytes: -1, }], }],
    [{ ..output, files: [{ ..file, size_bytes: MemberLimit + 1, }], }],
    [{ ..output, files: [{ ..file, digest: "sha256:BAD", }], }],
    [{ ..output, preview_path: Some("/etc/passwd"), }],
    [
      {
        ..output,
        app_entrypoint: Some("portable/outputs/result/missing.html"),
      },
    ],
    [{ ..output, included: false, reference: Some("https://example.invalid"), }],
  ]
  for outputs in cases {
    replace_test_manifest(root, outputs)
    assert_eq(
      discover(home + "/missing.json", home).books[0].state,
      "unavailable",
    )
  }
}

///|
async test "immutable selection rejects actual receipt source replacement" {
  let (home, root, selection) = fixture(b"original")
  defer @fs.rmdir(home, recursive=true)
  let receipt_path = root + "/state/portable-source-binding.json"
  let receipt = @json.parse(@fs.read_file(receipt_path).text())
  guard receipt is Object(fields) &&
    fields.get("source") is Some(Object(source)) else {
    fail("fixture")
  }
  source["package_sha256"] = hash(b"replacement-package").to_json()
  source["agent_version"] = "v2".to_json()
  @fs.write_file(receipt_path, receipt.stringify(), create=0o600, truncate=true)
  let current = discover(home + "/missing.json", home)
  assert_eq(current.books[0].source.unwrap().agent_version, "v2")
  assert_eq(
    respond(
      "GET",
      @contract.content_path(selection, mode="download"),
      home + "/missing.json",
      home,
    ).status,
    409,
  )
}

///|
async test "catalog aliases malformed catalog and missing roots remain read only and honest" {
  let (home, root, _) = fixture(b"original")
  defer @fs.rmdir(home, recursive=true)
  let catalog = home + "/catalog.json"
  @fs.write_file(catalog, "not-json", create=0o600, truncate=true)
  let partial = discover(catalog, home)
  assert_eq(partial.state, "ready")
  assert_true(partial.message.contains("could not be read safely"))
  assert_eq(partial.books.length(), 1)
  @fs.symlink(target=catalog, home + "/catalog-alias.json")
  assert_eq(
    discover(home + "/catalog-alias.json", home + "/missing-books").state,
    "unavailable",
  )
  let missing = home + "/not-created.json"
  assert_eq(discover(missing, home + "/missing-books").state, "empty")
  assert_false(@fs.exists(missing))
  @fs.write_file(
    root + "/state/portable-source-binding.json",
    "x".repeat(65537),
    create=0o600,
    truncate=true,
  )
  assert_eq(discover(missing, home).books[0].state, "unavailable")
}

///|
async test "aggregate catalog limit fails honestly instead of truncating a manifest" {
  let (home, root, _) = fixture(b"original")
  defer @fs.rmdir(home, recursive=true)
  let output = discover(home + "/missing.json", home).books[0].outputs[0]
  replace_test_manifest(root, [
    { ..output, label: "x".repeat(@contract.catalog_wire_limit()), },
  ])
  let result = discover(home + "/missing.json", home)
  assert_eq(result.state, "unavailable")
  assert_eq(result.books, [])
  assert_true(result.message.contains("4 MiB"))
}
