///|
/// Native worker summaries may contain the entire private result envelope.
/// Keep the existing public-text policy, but do not make that projection a
/// prerequisite for recording the worker's authoritative lifecycle outcome.
/// Full detail remains in the linked worker run; this fallback shares none of it.
fn marketplace_runtime_result_summary(
  detail : String,
  runtime_status : String,
) -> String {
  validate_public_text("marketplace runtime result summary", detail, 2000) catch {
    _ => {
      let status = match runtime_status {
        "succeeded" => "Worker completed."
        "failed" | "runtime_failed" => "Worker failed."
        "cancelled" => "Worker was cancelled."
        "waiting_for_input" => "Worker is waiting for input."
        _ => "Worker status updated."
      }
      status +
      " Detailed output remains with the publisher; its contents are not included in this public summary."
    }
  }
}
