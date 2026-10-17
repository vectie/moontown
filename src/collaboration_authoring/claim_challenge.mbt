///|
/// Verify the very buffers that save_internal will persist. Never re-read live
/// files between comparison checking and saving. Catalog roots come only from capture.
fn verify_claim_capture(
  input : @contract.ClaimChallenge,
  captured : Array[(@contract.SourceSnapshot, Bytes)],
) -> Unit raise {
  let report = match @contract.decode_claim_comparison(input.comparison) {
    Ok(value) => value
    Err(error) => raise CollaborationError(error)
  }
  guard report.groups.get(input.group_index) is Some(group) else {
    raise CollaborationError("Select an existing report group")
  }
  for claim in group.claims {
    let mappings = input.mappings.filter(m => m.claim_id == claim.claim_id)
    guard mappings.length() == 1 else {
      raise CollaborationError("Missing or ambiguous claim mapping")
    }
    let mapping = mappings[0]
    let files = captured.filter(pair => {
      pair.0.book_id == mapping.book_id &&
      pair.0.source_path == mapping.source_path
    })
    let reported = report.sources.filter(s => s.path == claim.source_path)
    guard files.length() == 1 && reported.length() == 1 else {
      raise CollaborationError("Mapped source was not captured")
    }
    let (snapshot, bytes) = files[0]
    guard snapshot.digest == reported[0].digest &&
      bytes.length() == reported[0].size_bytes else {
      raise CollaborationError(
        "Mapped source bytes differ from the report for " +
        claim.claim_id +
        ". Regenerate the comparison or correct the mapping before saving",
      )
    }
    let text = @utf8.decode(bytes) catch {
      _ => raise CollaborationError("Mapped claim source must be UTF-8")
    }
    guard text.contains(claim.quote) else {
      raise CollaborationError(
        "Reported quote is absent from the mapped captured source: " +
        claim.claim_id,
      )
    }
  }
}

///|
/// Creates an ordinary draft with current-source equality checks, no work,
/// inherited decisions, execution, schedules, or Book writes.
pub async fn Store::save_claim_challenge(
  self : Store,
  input : @contract.ClaimChallenge,
  recorded_at : String,
) -> @contract.SavedDraft {
  let draft = match @contract.claim_challenge_draft(input, self.books()) {
    Ok(value) => value
    Err(error) => raise CollaborationError(error)
  }
  self.save_internal(draft, "", recorded_at, claim_challenge=input)
}
