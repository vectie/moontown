///|
pub fn default_audit_path() -> String {
  ".moontown/book-quality/audit.json"
}

///|
pub fn default_review_dir() -> String {
  ".moontown/book-quality/ai-review-packets"
}

///|
pub fn default_review_result_dir() -> String {
  ".moontown/book-quality/ai-review-results"
}

///|
pub fn review_result_path(result_dir : String, book_id : String) -> String {
  "\{result_dir}/\{book_id}.md"
}

///|
pub fn workspace_path(root : String, relative : String) -> String {
  "\{root}/\{relative}"
}

///|
pub fn default_review_run_path() -> String {
  ".moontown/book-quality/ai-review-runs.json"
}

///|
pub fn default_repair_bridge_path() -> String {
  ".moontown/book-quality/repair-bridge.json"
}

///|
pub fn wiki_index_path() -> String {
  "wiki/index.md"
}

///|
pub fn projection_state_path() -> String {
  "book/moonbook-ui-state.json"
}

///|
pub fn generated_site_path() -> String {
  @policy.default_generated_site_projection_path()
}

///|
pub fn policy_output_path(policy : @policy.BookPolicy) -> String {
  @policy.output_projection_path(policy)
}

///|
pub fn policy_type_output_path(book_type : String) -> String {
  policy_output_path(@policy.policy_for_type(book_type))
}

///|
pub fn policy_output_required_path(
  policy : @policy.BookPolicy,
  points : Int,
) -> BookQualityRequiredPath {
  required_path(policy_output_path(policy), points)
}

///|
pub fn policy_type_output_required_path(
  book_type : String,
  points : Int,
) -> BookQualityRequiredPath {
  policy_output_required_path(@policy.policy_for_type(book_type), points)
}
