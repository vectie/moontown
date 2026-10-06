///|
fn pinned_selection(
  size : Int,
  digest : String,
) -> @imported_output_contract.Selection {
  {
    book_handle: "book-" + "a".repeat(64),
    package_sha256: "sha256:" + "b".repeat(64),
    manifest_sha256: "sha256:" + "c".repeat(64),
    artifact_id: "result",
    path: "portable/outputs/result/content.bin",
    digest: "sha256:" + digest,
    size_bytes: size,
  }
}

///|
test "held bytes verify standard empty ASCII and binary SHA256 vectors" {
  for
    (bytes, digest) in [
      (b"", "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"),
      (
        b"abc", "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
      ),
      (
        b"\x00", "6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d",
      ),
    ] {
    assert_true(
      @imported_output_contract.selection_bytes_match(
        pinned_selection(bytes.length(), digest),
        bytes,
      ),
    )
  }
}

///|
test "held bytes reject same length changed content truncated and extra data" {
  let selection = pinned_selection(
    3, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
  )
  for bytes in [b"abd", b"ab", b"abcd", b""] {
    assert_false(
      @imported_output_contract.selection_bytes_match(selection, bytes),
    )
  }
}

///|
test "held byte verification retains all pinned selection validation" {
  let selection = pinned_selection(
    3, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
  )
  for
    invalid in [
      { ..selection, book_handle: "arbitrary-root", },
      { ..selection, package_sha256: "unknown-package", },
      { ..selection, manifest_sha256: "unknown-manifest", },
      { ..selection, artifact_id: "../result", },
      { ..selection, path: "/etc/passwd", },
      { ..selection, digest: "sha256:bad", },
      { ..selection, size_bytes: -1, },
      { ..selection, size_bytes: 16 * 1024 * 1024 + 1, },
    ] {
    assert_false(
      @imported_output_contract.selection_bytes_match(invalid, b"abc"),
    )
  }
}
