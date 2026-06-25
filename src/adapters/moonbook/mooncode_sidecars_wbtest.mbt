///|
test "decode book result payload accepts direct result and mooncode envelope" {
  let direct_text =
    #|{"result_id":"result-1","summary":"done","artifacts":["wiki/a.md"],"memory_candidates":[],"requires_review":false,"notify_town":true}
  let direct = @json.parse(direct_text)
  let direct_result = match decode_book_result_payload(direct) {
    Some(result) => result
    None => fail("expected direct result")
  }
  assert_eq(direct_result.result_id, "result-1")
  assert_eq(direct_result.notify_town, true)
  let envelope_text =
    #|{"kind":"mooncode-book-result","session_id":"session-1","command_id":"cmd-1","result_id":"result-cmd-1","result_path":"/tmp/book-result-cmd-1.json","book_result":{"result_id":"result-cmd-1","summary":"package created","artifacts":["portable/app-tool/demo/index.html"],"memory_candidates":[],"requires_review":true,"notify_town":true}}
  let envelope = @json.parse(envelope_text)
  let envelope_result = match decode_book_result_payload(envelope) {
    Some(result) => result
    None => fail("expected envelope result")
  }
  assert_eq(envelope_result.result_id, "result-cmd-1")
  assert_eq(envelope_result.requires_review, true)
}

///|
test "mooncode sidecar processed key prefers durable result path" {
  let payload_text =
    #|{"kind":"mooncode-book-result","session_id":"session-1","command_id":"cmd-1","result_id":"result-cmd-1","result_path":"/tmp/book-result-cmd-1.json","book_result":{"result_id":"result-cmd-1","summary":"package created","artifacts":[],"memory_candidates":[],"requires_review":true,"notify_town":true}}
  let payload = @json.parse(payload_text)
  assert_eq(
    mooncode_book_result_processed_key(
      payload, "session-fallback", "command-fallback", "task-fallback",
    ),
    "/tmp/book-result-cmd-1.json",
  )
}

///|
test "mooncode sidecar processed key falls back to session command task" {
  let payload_text =
    #|{"kind":"mooncode-book-result","session_id":"session-1","command_id":"cmd-1","result_id":"result-cmd-1","book_result":{"result_id":"result-cmd-1","summary":"package created","artifacts":[],"memory_candidates":[],"requires_review":true,"notify_town":true}}
  let payload = @json.parse(payload_text)
  assert_eq(
    mooncode_book_result_processed_key(
      payload, "session-1", "cmd-1", "result-cmd-1",
    ),
    "session-1:cmd-1:result-cmd-1",
  )
}

///|
async test "mooncode sidecar processed ledger dedupes keys" {
  let path = "/tmp/moontown-mooncode-sidecar-ledger/processed.jsonl"
  @support.write_text_file(path, "a\nb\na\n\n")
  let keys = read_mooncode_book_result_processed_keys(path)
  assert_true(keys == ["a", "b"])
  keys.push("c")
  write_mooncode_book_result_processed_keys(path, keys)
  let updated = read_mooncode_book_result_processed_keys(path)
  assert_true(updated == ["a", "b", "c"])
}

///|
async test "mooncode sidecar reconciler imports through moonbook cli and dedupes" {
  let moonbook_root = resolved_root_path("../moonbook")
  if !@fs.exists("\{moonbook_root}/moon.mod") {
    return
  }
  let root = "/tmp/moontown-mooncode-sidecar-e2e"
  @support.ignore_checked_command("rm", ["-rf", root])
  let entry = BookCatalogEntry::new(
    id="sidecar-e2e",
    name="Sidecar E2E",
    purpose="Verify MoonCode sidecar import",
    workspace_root=root,
  )
  let session_dir = "\{root}/.moonclaw/mooncode/sessions/session-1"
  let sidecar_text =
    #|{"kind":"mooncode-book-result","session_id":"session-1","command_id":"cmd-1","result_id":"result-cmd-1","result_path":"/tmp/moontown-mooncode-sidecar-e2e-result.json","book_result":{"result_id":"result-cmd-1","summary":"package created from mooncode sidecar","artifacts":["portable/app-tool/mooncode/session-1/book-result-cmd-1.json"],"memory_candidates":[],"requires_review":true,"notify_town":true}}
  @support.write_text_file(
    "\{session_dir}/book-results.jsonl",
    sidecar_text + "\n",
  )
  let imports = reconcile_mooncode_book_result_sidecars(entry, moonbook_root~)
  assert_eq(imports.length(), 1)
  assert_eq(imports[0].result_id, "result-cmd-1")
  assert_eq(imports[0].review_queued, true)
  let pending = @support.read_text_or_empty("\{root}/wiki/reviews/pending.md")
  assert_true(pending.contains("package created from mooncode sidecar"))
  let evidence = @support.read_text_or_empty(
    "\{root}/wiki/synthesis/evidence.md",
  )
  assert_true(evidence.contains("cmd-1"))
  let replay = reconcile_mooncode_book_result_sidecars(entry, moonbook_root~)
  assert_eq(replay.length(), 0)
}
