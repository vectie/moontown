///|
priv struct BookQualityReviewLedgerReconcileResult {
  ledger : BookQualityReviewRunLedger
  written : Int
  changed : Bool
}

///|
priv struct BookQualityReviewRunReconcileResult {
  run : BookQualityReviewRun
  written : Bool
  changed : Bool
}

///|
fn book_quality_review_ledger_reconcile_result(
  runs : Array[BookQualityReviewRun],
  written : Int,
  changed : Bool,
) -> BookQualityReviewLedgerReconcileResult {
  { ledger: BookQualityReviewRunLedger::{ runs, }, written, changed }
}

///|
fn book_quality_review_ledger_reconcile_result_from_runs(
  run_results : Array[BookQualityReviewRunReconcileResult],
) -> BookQualityReviewLedgerReconcileResult {
  let runs : Array[BookQualityReviewRun] = []
  let mut written = 0
  let mut changed = false
  for result in run_results {
    runs.push(result.run)
    written += book_quality_review_run_reconcile_written_delta(result)
    changed = book_quality_review_ledger_reconcile_changed_after(
      changed, result,
    )
  }
  book_quality_review_ledger_reconcile_result(runs, written, changed)
}

///|
pub async fn reconcile_review_run_ledger_file(
  result_dir? : String = default_review_result_dir(),
  run_path? : String = default_review_run_path(),
) -> Int {
  let ledger = load_review_run_ledger(run_path)
  let root = review_root_from_run_path(run_path)
  let home = moonclaw_home_from_run_path(run_path)
  let result = reconcile_review_run_ledger(ledger, result_dir, root, home)
  if result.changed {
    write_text_file(run_path, review_run_ledger_to_text(result.ledger))
  }
  result.written
}

///|
async fn reconcile_review_run_ledger(
  ledger : BookQualityReviewRunLedger,
  result_dir : String,
  root : String,
  home : String,
) -> BookQualityReviewLedgerReconcileResult {
  let results : Array[BookQualityReviewRunReconcileResult] = []
  for run in ledger.runs {
    results.push(reconcile_review_run(run, result_dir, root, home))
  }
  book_quality_review_ledger_reconcile_result_from_runs(results)
}

///|
fn book_quality_review_run_reconcile_written_delta(
  run_result : BookQualityReviewRunReconcileResult,
) -> Int {
  if run_result.written {
    1
  } else {
    0
  }
}

///|
fn book_quality_review_ledger_reconcile_changed_after(
  already_changed : Bool,
  run_result : BookQualityReviewRunReconcileResult,
) -> Bool {
  already_changed || run_result.changed
}

///|
fn book_quality_review_run_reconcile_result(
  before : BookQualityReviewRun,
  after : BookQualityReviewRun,
  written~ : Bool,
) -> BookQualityReviewRunReconcileResult {
  {
    run: after,
    written,
    changed: written || review_run_status_or_summary_changed(before, after),
  }
}

///|
async fn reconcile_review_run(
  run : BookQualityReviewRun,
  result_dir : String,
  root : String,
  home : String,
  now_ms? : UInt64 = @env.now(),
) -> BookQualityReviewRunReconcileResult {
  let result_exists = @fs.exists(run.result_path)
  let mut result_content = ""
  match run.run_id {
    Some(run_id) =>
      if !result_exists {
        result_content = review_result_content_from_run(run_id, root, home)
      }
    None => ()
  }
  reconcile_review_run_with_observed_content(
    run,
    result_dir,
    root,
    home,
    result_exists~,
    result_content~,
    now_ms~,
  )
}

///|
async fn reconcile_review_run_with_observed_content(
  run : BookQualityReviewRun,
  result_dir : String,
  root : String,
  home : String,
  result_exists~ : Bool,
  result_content? : String = "",
  now_ms? : UInt64 = @env.now(),
) -> BookQualityReviewRunReconcileResult {
  if result_exists {
    return existing_result_review_run_reconcile_result(run)
  }
  match run.run_id {
    Some(run_id) =>
      if review_result_satisfies_contract(result_content) {
        write_accepted_review_result(result_dir, run, result_content)
        accepted_review_run_reconcile_result(run, run_id, now_ms~)
      } else {
        stale_review_run_reconcile_result(run, root, home, now_ms~)
      }
    None => unchanged_review_run_reconcile_result(run)
  }
}

///|
async fn review_result_content_from_run(
  run_id : String,
  cwd : String,
  home : String,
) -> String {
  let workspace_dir = match @moonclaw.run_workspace_dir(run_id, cwd~, home~) {
    Some(workspace_dir) => workspace_dir
    None => return ""
  }
  let result_path = "\{workspace_dir}/result.json"
  if !@fs.exists(result_path) {
    return ""
  }
  let parsed = @json.parse(@fs.read_file(result_path).text()) catch {
    _ => return ""
  }
  json_string_field(parsed, "content").unwrap_or(
    json_string_field(parsed, "summary").unwrap_or(""),
  )
}

///|
fn json_string_field(value : Json, key : String) -> String? {
  match value {
    Object(object) =>
      match object.get(key) {
        Some(String(value)) => Some(value)
        _ => None
      }
    _ => None
  }
}

///|
fn unchanged_review_run_reconcile_result(
  run : BookQualityReviewRun,
) -> BookQualityReviewRunReconcileResult {
  book_quality_review_run_reconcile_result(run, run, written=false)
}

///|
fn existing_result_review_run_reconcile_result(
  run : BookQualityReviewRun,
) -> BookQualityReviewRunReconcileResult {
  book_quality_review_run_reconcile_result(
    run,
    corrected_terminal_review_run(run),
    written=false,
  )
}

///|
fn accepted_review_run_reconcile_result(
  run : BookQualityReviewRun,
  run_id : String,
  now_ms~ : UInt64,
) -> BookQualityReviewRunReconcileResult {
  book_quality_review_run_reconcile_result(
    run,
    accepted_review_run(run, run_id, now_ms~),
    written=true,
  )
}
