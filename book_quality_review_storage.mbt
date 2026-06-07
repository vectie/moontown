///|
fn book_quality_external_packet_path(
  review_dir : String,
  book_id : String,
) -> String {
  "\{book_quality_review_root(review_dir)}/moonclaw-packets/book-quality-ai-review-\{book_id}.json"
}

///|
fn book_quality_review_root(review_dir : String) -> String {
  book_quality_root_from_suffixed_path(
    review_dir,
    book_quality_review_packet_dir_suffix(),
  )
}

///|
fn book_quality_review_root_from_run_path(run_path : String) -> String {
  book_quality_root_from_suffixed_path(
    run_path,
    book_quality_review_run_ledger_suffix(),
  )
}

///|
fn book_quality_root_from_suffixed_path(
  path : String,
  suffix : String,
) -> String {
  if path.has_suffix(suffix) {
    path[:path.length() - suffix.length()].to_owned()
  } else {
    default_book_quality_review_root()
  }
}

///|
fn default_book_quality_review_root() -> String {
  ".moontown/book-quality"
}

///|
fn book_quality_review_packet_dir_suffix() -> String {
  "/ai-review-packets"
}

///|
fn book_quality_review_run_ledger_suffix() -> String {
  "/ai-review-runs.json"
}

///|
fn book_quality_moonclaw_home(review_dir : String) -> String {
  ignore(review_dir)
  default_book_quality_moonclaw_home()
}

///|
fn book_quality_moonclaw_home_from_run_path(run_path : String) -> String {
  ignore(run_path)
  default_book_quality_moonclaw_home()
}

///|
fn default_book_quality_moonclaw_home() -> String {
  ".moonclaw"
}

///|
async fn append_book_quality_review_run(
  run_path : String,
  run : BookQualityReviewRun,
) -> Unit {
  let ledger = load_book_quality_review_run_ledger(run_path)
  let updated = book_quality_review_run_ledger_with_appended_run(ledger, run)
  write_text_file(run_path, book_quality_review_run_ledger_to_text(updated))
}

///|
fn book_quality_review_run_ledger_with_appended_run(
  ledger : BookQualityReviewRunLedger,
  run : BookQualityReviewRun,
) -> BookQualityReviewRunLedger {
  let runs : Array[BookQualityReviewRun] = []
  for existing in ledger.runs {
    if !book_quality_review_run_same_ledger_slot(existing, run) {
      runs.push(existing)
    }
  }
  runs.push(run)
  BookQualityReviewRunLedger::{ runs, }
}

///|
fn book_quality_review_run_same_ledger_slot(
  left : BookQualityReviewRun,
  right : BookQualityReviewRun,
) -> Bool {
  left.book_id == right.book_id && left.run_id == right.run_id
}

///|
async fn load_book_quality_review_run_ledger(
  run_path : String,
) -> BookQualityReviewRunLedger {
  if !@fs.exists(run_path) {
    return empty_book_quality_review_run_ledger()
  }
  book_quality_review_run_ledger_from_text(@fs.read_file(run_path).text())
}

///|
fn book_quality_review_run_ledger_from_text(
  text : String,
) -> BookQualityReviewRunLedger {
  let parsed = @json.parse(text) catch {
    _ => return empty_book_quality_review_run_ledger()
  }
  @json.from_json(parsed) catch {
    _ => empty_book_quality_review_run_ledger()
  }
}

///|
fn book_quality_review_run_ledger_to_text(
  ledger : BookQualityReviewRunLedger,
) -> String {
  ledger.to_json().stringify(indent=2)
}

///|
fn empty_book_quality_review_run_ledger() -> BookQualityReviewRunLedger {
  BookQualityReviewRunLedger::{ runs: [] }
}

///|
async fn book_quality_review_result_content_from_run(
  run_id : String,
  cwd : String,
  home : String,
) -> String {
  moonclaw_run_result_text_from_run_with_home(
    run_id,
    cwd,
    home,
    fallback_summary=true,
  )
}
