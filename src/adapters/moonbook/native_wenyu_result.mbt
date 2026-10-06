///|
fn native_wenyu_result_envelope(
  result : BookResult,
  work_id : String,
  request_digest : String,
) -> Json raise {
  guard !work_id.trim().is_empty() &&
    work_id.length() <= 256 &&
    !work_id.contains("\n") &&
    !work_id.contains("\r") &&
    request_digest.length() == 64 else {
    fail("invalid native Wenyu import identity")
  }
  for index in 0..<request_digest.length() {
    let unit = request_digest[index]
    guard (unit >= '0' && unit <= '9') || (unit >= 'a' && unit <= 'f') else {
      fail("native Wenyu request digest must be lowercase SHA-256 hex")
    }
  }
  guard result.memory_candidates.is_empty() &&
    result.requires_review &&
    result.notify_town &&
    !result.result_id.trim().is_empty() else {
    fail(
      "native Wenyu import requires review, Town notification, and no memory candidates",
    )
  }
  let book_result = result.to_json()
  let payload_digest = @crypto.bytes_to_hex_string(
    @crypto.sha256(@encoding/utf8.encode(book_result.stringify())),
  )
  {
    "book_result": book_result,
    "native_import": {
      "contract": "moontown.wenyu.import.v1",
      "work_id": work_id,
      "request_digest": request_digest,
      "payload_digest": payload_digest,
    },
  }
}

///|
/// Import a verified Wenyu result using the immutable native Work identity.
/// Replaying the same envelope returns the original MoonBook persistence receipt.
///
/// ```mbt check
/// test {
///   let import_saved = async fn(
///     entry : @moonbook.BookCatalogEntry,
///     result : @moonbook.BookResult,
///   ) {
///     @moonbook.persist_native_wenyu_result(
///       entry, result, "town-work-example", "0000000000000000000000000000000000000000000000000000000000000000",
///     )
///   }
///   ignore(import_saved)
/// }
/// ```
pub async fn persist_native_wenyu_result(
  entry : BookCatalogEntry,
  result : BookResult,
  work_id : String,
  request_digest : String,
  moonbook_root? : String = default_moonbook_root(),
) -> PersistResultOutcome {
  let payload = native_wenyu_result_envelope(result, work_id, request_digest)
  // Unlike legacy result_id scratch files, this transport path also binds the
  // exact Work and payload, so another generation cannot replace its contents.
  let key = @crypto.bytes_to_hex_string(
    @crypto.sha256(@encoding/utf8.encode(payload.stringify())),
  )
  let path = result_temp_path(entry.workspace_root, "native-wenyu-\{key}")
  @support.ensure_parent_directory(path)
  let lock = @fs.open(
    path + ".lock",
    mode=ReadWrite,
    create_mode=OpenOrCreate,
    permission=0o600,
  )
  defer lock.close()
  lock.lock(Exclusive)
  defer lock.unlock()
  save_result_payload_file(path, payload)
  let json = run_book_json_command(
    entry,
    ["persist", entry.workspace_root, path],
    moonbook_root~,
  )
  @json.from_json(json)
}
