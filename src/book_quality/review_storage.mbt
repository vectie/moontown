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
  ".moontown/book-quality"
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
  ignore(review_dir)
  default_moonclaw_home()
}

///|
pub fn moonclaw_home_from_run_path(run_path : String) -> String {
  ignore(run_path)
  default_moonclaw_home()
}

///|
pub fn default_moonclaw_home() -> String {
  ".moonclaw"
}

///|
pub async fn write_accepted_review_result(
  result_dir : String,
  run : BookQualityReviewRun,
  content : String,
) -> Unit {
  write_text_file(review_result_path(result_dir, run.book_id), content)
}

///|
pub async fn read_review_result_text(
  result_dir : String,
  book_id : String,
) -> String {
  if !@fs.exists(review_result_path(result_dir, book_id)) {
    return ""
  }
  @fs.read_file(review_result_path(result_dir, book_id)).text()
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
  BookQualityReviewRunLedger::{ runs, }
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
  BookQualityReviewRunLedger::{ runs: [] }
}

///|
async fn write_text_file(path : String, content : String) -> Unit {
  ensure_parent_directory(path)
  @fs.write_file(
    path,
    @encoding/utf8.encode(content),
    create=0o644,
    truncate=true,
  )
}

///|
async fn ensure_parent_directory(path : String) -> Unit {
  let parent = @path.Path::dirname(path).to_string()
  if parent == "." || parent == "" || @fs.exists(parent) {
    return
  }
  ensure_parent_directory(parent)
  @fs.mkdir(parent, permission=0o755) catch {
    _ => ()
  }
}
