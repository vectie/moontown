///|
pub fn active_review_dispatch_message(active : Int) -> String {
  "AI semantic book-quality review already active; daemon will not dispatch a duplicate. active=\{active}"
}

///|
pub fn no_pending_review_dispatch_message(result_dir : String) -> String {
  "No pending AI semantic book-quality review remains. Results are stored under \{result_dir}."
}
