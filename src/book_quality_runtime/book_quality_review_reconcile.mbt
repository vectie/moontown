///|
priv struct BookQualityReviewRunRuntimeObservation {
  result_exists : Bool
  result_content : String
  process_alive : Bool
  poll_summary : String
}

///|
pub async fn reconcile_book_quality_ai_review_results(
  result_dir? : String = @book_quality.default_review_result_dir(),
  run_path? : String = @book_quality.default_review_run_path(),
) -> Int {
  let ledger = load_review_run_ledger_file(run_path)
  let root = @book_quality.review_root_from_run_path(run_path)
  let home = @book_quality.moonclaw_home_from_run_path(run_path)
  let runs : Array[@book_quality.BookQualityReviewRun] = []
  let mut written = 0
  let mut changed = false
  for run in ledger.runs {
    let observation = observe_book_quality_review_run(run, root, home)
    let result = @book_quality.reconcile_review_run_from_observation(
      run,
      result_exists=observation.result_exists,
      result_content=observation.result_content,
      process_alive=observation.process_alive,
      poll_summary=observation.poll_summary,
      now_ms=@env.now(),
    )
    if result.written {
      write_accepted_review_result(result_dir, run, observation.result_content)
      written += 1
    }
    changed = changed || result.changed
    runs.push(result.run)
  }
  if changed {
    write_review_run_ledger_file(run_path, @book_quality.BookQualityReviewRunLedger::{
      runs,
    })
  }
  written
}

///|
async fn active_book_quality_review_count(
  result_dir : String,
  run_path : String,
) -> Int {
  let ledger = load_review_run_ledger_file(run_path)
  let mut active = 0
  for run in ledger.runs {
    let result_exists = @fs.exists(
        @book_quality.review_result_path(result_dir, run.book_id),
      ) ||
      @fs.exists(run.result_path)
    let process_alive = match run.run_id {
      Some(run_id) => @moonclaw.run_process_alive(run_id)
      None => false
    }
    if @book_quality.review_run_active_by_observation(
        run,
        has_result=result_exists,
        process_alive~,
        now_ms=@env.now(),
      ) {
      active += 1
    }
  }
  active
}

///|
async fn observe_book_quality_review_run(
  run : @book_quality.BookQualityReviewRun,
  root : String,
  home : String,
) -> BookQualityReviewRunRuntimeObservation {
  let result_exists = @fs.exists(run.result_path)
  let mut result_content = ""
  let mut process_alive = false
  let mut poll_summary = ""
  match run.run_id {
    Some(run_id) => {
      if !result_exists {
        result_content = review_result_content_from_run(run_id, root, home)
      }
      process_alive = @moonclaw.run_process_alive(run_id)
      if !process_alive && !result_exists && result_content.is_empty() {
        let poll = @moonclaw.poll_run(
          "book-quality-ai-review-\{run.book_id}",
          run_id,
          cwd=root,
          home~,
        )
        poll_summary = poll.summary
      }
    }
    None => ()
  }
  { result_exists, result_content, process_alive, poll_summary }
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
