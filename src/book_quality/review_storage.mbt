///|
pub fn review_root(review_dir : String) -> String {
  root_from_suffixed_path(review_dir, review_packet_dir_suffix())
}

///|
pub fn review_root_from_run_path(run_path : String) -> String {
  root_from_suffixed_path(run_path, review_run_ledger_suffix())
}

///|
pub fn external_packet_path(review_dir : String, book_id : String) -> String {
  "\{review_root(review_dir)}/moonclaw-packets/book-quality-ai-review-\{book_id}.json"
}

///|
fn root_from_suffixed_path(path : String, suffix : String) -> String {
  if path.has_suffix(suffix) {
    path[:path.length() - suffix.length()].to_owned()
  } else {
    default_review_root()
  }
}

///|
pub fn default_review_root() -> String {
  default_book_quality_dir()
}

///|
fn review_packet_dir_suffix() -> String {
  "/ai-review-packets"
}

///|
fn review_run_ledger_suffix() -> String {
  "/ai-review-runs.json"
}

///|
pub fn moonclaw_home(review_dir : String) -> String {
  @moonsuite.product_artifact_for_workspace_root(
    review_root(review_dir),
    "moonclaw",
    "",
  )
}

///|
pub fn moonclaw_home_from_run_path(run_path : String) -> String {
  @moonsuite.product_artifact_for_workspace_root(
    review_root_from_run_path(run_path),
    "moonclaw",
    "",
  )
}

///|
pub fn default_moonclaw_home() -> String {
  @moonsuite.product_artifact_for_workspace_root(
    default_review_root(),
    "moonclaw",
    "",
  )
}

///|
pub fn moonclaw_config_path(review_dir : String) -> String {
  @moonsuite.product_artifact_for_workspace_root(
    review_root(review_dir),
    "moonclaw",
    "moonclaw.json",
  )
}

///|
pub fn review_run_ledger_with_appended_run(
  ledger : BookQualityReviewRunLedger,
  run : BookQualityReviewRun,
) -> BookQualityReviewRunLedger {
  let runs : Array[BookQualityReviewRun] = []
  for existing in ledger.runs {
    if !review_run_same_ledger_slot(existing, run) {
      runs.push(existing)
    }
  }
  runs.push(run)
  { runs, }
}

///|
fn review_run_same_ledger_slot(
  left : BookQualityReviewRun,
  right : BookQualityReviewRun,
) -> Bool {
  left.book_id == right.book_id && left.run_id == right.run_id
}

///|
pub fn review_run_ledger_from_text(text : String) -> BookQualityReviewRunLedger {
  let parsed = @json.parse(text) catch { _ => return empty_review_run_ledger() }
  @json.from_json(parsed) catch {
    _ => empty_review_run_ledger()
  }
}

///|
pub fn review_run_ledger_to_text(ledger : BookQualityReviewRunLedger) -> String {
  ledger.to_json().stringify(indent=2)
}

///|
pub fn empty_review_run_ledger() -> BookQualityReviewRunLedger {
  { runs: [] }
}
