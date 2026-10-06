///|
test "pinned query percent encoding does not expose arbitrary absolute paths" {
  let selection : @imported_output_contract.Selection = {
    book_handle: "book-" + "a".repeat(64),
    package_sha256: "sha256:" + "b".repeat(64),
    manifest_sha256: "sha256:" + "c".repeat(64),
    artifact_id: "result",
    path: "portable/outputs/result/学习 & #?.txt",
    digest: "sha256:" + "d".repeat(64),
    size_bytes: 0,
  }
  assert_true(@imported_output_contract.selection_valid(selection))
  let path = @imported_output_contract.content_path(selection, mode="download")
  assert_true(path.contains("%E5%AD%A6%E4%B9%A0%20%26%20%23%3F.txt"))
  assert_false(
    @imported_output_contract.selection_valid({
      ..selection,
      path: "/etc/passwd",
    }),
  )
  assert_false(
    @imported_output_contract.selection_valid({
      ..selection,
      path: "portable/outputs/result/../secret",
    }),
  )
}

///|
test "strict decoder validates byte-exact ready body including valid empty text" {
  let selection : @imported_output_contract.Selection = {
    book_handle: "book-" + "a".repeat(64),
    package_sha256: "sha256:" + "b".repeat(64),
    manifest_sha256: "sha256:" + "c".repeat(64),
    artifact_id: "result",
    path: "portable/outputs/result/content.txt",
    digest: "sha256:" + "d".repeat(64),
    size_bytes: 0,
  }
  let reply : @imported_output_contract.TextReply = {
    contract: "moontown.imported_output_text.v1",
    state: "ready",
    message: "",
    selection,
    content: Some(""),
  }
  assert_true(
    @imported_output_contract.parse_text_reply(reply.to_json().stringify())
    is Some(_),
  )
  assert_true(
    @imported_output_contract.parse_text_reply(
      { ..reply, content: Some("unexpected"), }.to_json().stringify(),
    )
    is None,
  )
  assert_true(
    @imported_output_contract.parse_text_reply(
      { ..reply, state: "unavailable", }.to_json().stringify(),
    )
    is None,
  )
}
