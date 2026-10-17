///|
/// Reuses the read-only retained verifier and ordinary optimistic save. No
/// collector, runtime, prior decisions or Book mutations enter the new round.
pub async fn Store::save_retained_inquiry(
  self : Store,
  input : @contract.RetainedInquiry,
  recorded_at : String,
) -> @contract.SavedDraft {
  let outcome = self.inspect_outcome(input.origin)
  let draft = match @contract.retained_inquiry_draft(input, outcome) {
    Ok(value) => value
    Err(error) => raise CollaborationError(error)
  }
  self.save(draft, "", recorded_at)
}
