///|
/// A current Book review observation, never task or goal acceptance.
pub struct NativeWenyuReviewResolution {
  contract : String
  status : String
  root : String
  work_id : String
  request_digest : String
  payload_digest : String
  result_id : String
  review_id : String
  evidence_id : String
  resolution_timestamp : String?
  original_task_acceptance : String
  reason : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn validate_native_wenyu_review_resolution(
  resolution : NativeWenyuReviewResolution,
  entry : BookCatalogEntry,
  work_id : String,
  request_digest : String,
  payload_digest : String,
  result_id : String,
) -> Unit raise {
  let key = @crypto.bytes_to_hex_string(
    @crypto.sha256(@encoding/utf8.encode(work_id)),
  )
  guard resolution.contract == "moonbook.native-wenyu-review.v1" &&
    ["pending", "approved", "rejected", "unresolved"].contains(
      resolution.status,
    ) &&
    resolution.root == entry.workspace_root &&
    resolution.work_id == work_id &&
    resolution.request_digest == request_digest &&
    resolution.payload_digest == payload_digest &&
    resolution.result_id == result_id &&
    resolution.review_id == "result-review-native-wenyu-" + key &&
    resolution.evidence_id == "EV-native-wenyu-" + key &&
    resolution.original_task_acceptance == "unevaluated" else {
    fail("wenyu_book_review_response_binding_mismatch")
  }
  if resolution.status == "approved" || resolution.status == "rejected" {
    guard resolution.resolution_timestamp is Some(timestamp) &&
      !timestamp.is_empty() &&
      timestamp.length() <= 24 else {
      fail("wenyu_book_review_resolution_missing")
    }
    for index in 0..<timestamp.length() {
      guard (timestamp[index] >= '0' && timestamp[index] <= '9') ||
        (index == 0 && timestamp.length() > 1 && timestamp[index] == '-') else {
        fail("wenyu_book_review_resolution_invalid")
      }
    }
  }
}

///|
/// Read only the exact existing review; unlike result persistence this does not
/// call ensure_workspace, create payload files, initialize or enable anything.
///
/// ```mbt check
/// test {
///   let observe = async fn(entry : @moonbook.BookCatalogEntry) {
///     @moonbook.read_native_wenyu_review(
///       entry, "work", "request", "payload", "task",
///     )
///   }
///   ignore(observe)
/// }
/// ```
pub async fn read_native_wenyu_review(
  entry : BookCatalogEntry,
  work_id : String,
  request_digest : String,
  payload_digest : String,
  result_id : String,
  moonbook_root? : String = default_moonbook_root(),
) -> NativeWenyuReviewResolution {
  let command = match installed_moonbook_command() {
    Some(command) => command
    None => fail("native_wenyu_review_requires_existing_moonbook_executable")
  }
  let args = [
    "wiki",
    "review",
    "native-status",
    entry.workspace_root,
    work_id,
    request_digest,
    payload_digest,
    result_id,
  ]
  let json = @integration.run_json(
    command,
    args,
    cwd=Some(resolved_root_path(moonbook_root)),
  )
  let resolution : NativeWenyuReviewResolution = @json.from_json(json)
  validate_native_wenyu_review_resolution(
    resolution, entry, work_id, request_digest, payload_digest, result_id,
  )
  resolution
}
