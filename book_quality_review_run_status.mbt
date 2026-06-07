///|
fn book_quality_review_run_in_progress_status(status : String) -> Bool {
  book_quality_review_run_status_bucket(status) ==
  book_quality_review_run_in_progress_bucket()
}

///|
fn book_quality_review_run_problem_status(status : String) -> Bool {
  book_quality_review_run_status_bucket(status) ==
  book_quality_review_run_problem_bucket()
}

///|
fn book_quality_review_run_terminal_status(status : String) -> Bool {
  book_quality_review_run_status_bucket(status) ==
  book_quality_review_run_terminal_bucket()
}

///|
fn book_quality_review_run_status_bucket(status : String) -> String {
  if status == book_quality_review_run_dispatched_status() ||
    status == book_quality_review_run_queued_status() ||
    status == book_quality_review_run_running_status() {
    book_quality_review_run_in_progress_bucket()
  } else if status == book_quality_review_run_written_status() {
    book_quality_review_run_terminal_bucket()
  } else if status == book_quality_review_run_orphaned_status() ||
    status == book_quality_review_run_blocked_status() {
    book_quality_review_run_problem_bucket()
  } else {
    book_quality_review_run_other_bucket()
  }
}

///|
fn book_quality_review_run_dispatched_status() -> String {
  "dispatched"
}

///|
fn book_quality_review_run_queued_status() -> String {
  "queued"
}

///|
fn book_quality_review_run_running_status() -> String {
  "running"
}

///|
fn book_quality_review_run_written_status() -> String {
  "written"
}

///|
fn book_quality_review_run_orphaned_status() -> String {
  "orphaned"
}

///|
fn book_quality_review_run_blocked_status() -> String {
  "blocked"
}

///|
fn book_quality_review_run_in_progress_bucket() -> String {
  "in-progress"
}

///|
fn book_quality_review_run_terminal_bucket() -> String {
  "terminal"
}

///|
fn book_quality_review_run_problem_bucket() -> String {
  "problem"
}

///|
fn book_quality_review_run_other_bucket() -> String {
  "other"
}
