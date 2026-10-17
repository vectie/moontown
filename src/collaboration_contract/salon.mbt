///|
/// A salon compares retained outputs. It does not infer agreement, manufacture
/// agent votes, or qualify the autonomous emergence protocol.
pub fn salon_candidates(work : OneoffWork) -> Array[ParticipantWork] {
  work.participants.filter(p => {
    p.status == "completed" &&
    !p.output_text.trim().is_empty() &&
    !p.output_ref.is_empty() &&
    !p.output_digest.is_empty()
  })
}

///|
pub fn salon_ready(work : OneoffWork) -> Bool {
  ["completed", "partial"].contains(work.status) &&
  !work.result_digest.is_empty() &&
  work.participants.all(p => ["completed", "failed"].contains(p.status)) &&
  salon_candidates(work).length() >= 2 &&
  salon_candidates(work).length() ==
  work.participants.filter(p => p.status == "completed").length()
}

///|
fn salon_text(fields : Json, key : String) -> Result[String, String] {
  match fields {
    Object(values) =>
      match values.get(key) {
        Some(String(value)) if !value.trim().is_empty() &&
          value.length() <= 4000 => Ok(value)
        _ => Err("Enter " + key + " (up to 4000 characters)")
      }
    _ => Err("Salon comparison fields are missing")
  }
}

///|
/// Called by the existing Book intake constructor. Every comparison row is
/// bound here to server-retained output identities, never browser-supplied refs.
/// The result review approves the source account; the selection is explicitly
/// an operator proposal that still needs Book's independent review.
pub fn salon_selection(
  saved : SavedDraft,
  work : OneoffWork,
  fields : Json,
) -> Result[Json?, String] {
  let mode = match fields {
    Object(values) => values.get("salon_mode")
    _ => None
  }
  if mode is (None | Some(String("off"))) {
    return Ok(None)
  }
  guard mode is Some(String("compare")) else {
    return Err("Unknown salon comparison mode")
  }
  guard salon_ready(work) &&
    work.draft_id == saved.draft.draft_id &&
    work.revision == saved.revision else {
    return Err(
      "Collect at least two completed contributions from this exact saved question before comparing",
    )
  }
  let bound = match salon_text(fields, "salon_result_digest") {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  guard bound == work.result_digest else {
    return Err(
      "Salon notes belong to an earlier result; compare the current outputs again",
    )
  }
  let selected = match salon_text(fields, "salon_selected_book") {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let candidates = salon_candidates(work)
  guard candidates.any(p => p.book_id == selected) else {
    return Err(
      "Choose a completed contribution; failed and unknown Books cannot be selected",
    )
  }
  let statement : Map[String, Json] = {
    "contract_version": "moontown.idea-salon-selection.v1".to_json(),
    "draft_id": saved.draft.draft_id.to_json(),
    "revision": saved.revision.to_json(),
    "question": saved.draft.question.to_json(),
    "result_digest": work.result_digest.to_json(),
    "selected_book_id": selected.to_json(),
    "comparison_kind": "operator-authored comparison of retained outputs".to_json(),
    "genuine_emergence_verified": false.to_json(),
    "authority": "Proposed outcome only. Result review covers the accurate source account; Book independently reviews this selection. Fixture outputs remain fixture rehearsals.".to_json(),
    "authored_objection": saved.draft.objection.to_json(),
    "failed_book_ids": work.participants
    .filter(p => p.status == "failed")
    .map(p => p.book_id)
    .to_json(),
  }
  for key in ["basis", "rationale", "alternatives", "dissent", "assumptions"] {
    match salon_text(fields, "salon_" + key) {
      Ok(value) => statement[key] = value.to_json()
      Err(error) => return Err(error)
    }
  }
  let comparisons : Array[Json] = []
  let seen : Array[String] = []
  for candidate in candidates {
    guard !seen.contains(candidate.book_id) &&
      saved.sources.any(source => source.book_id == candidate.book_id) else {
      return Err(
        "Each comparison needs a unique Book and its captured input snapshot",
      )
    }
    seen.push(candidate.book_id)
    let assessment = match
      salon_text(fields, "salon_assessment_" + candidate.book_id) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    comparisons.push({
      "book_id": candidate.book_id,
      "selected": candidate.book_id == selected,
      "assessment": assessment,
      "proposal_id": candidate.proposal_id,
      "run_id": candidate.run_id,
      "output_ref": candidate.output_ref,
      "output_digest": candidate.output_digest,
      "source_snapshots": saved.sources
      .filter(source => source.book_id == candidate.book_id)
      .to_json(),
    })
  }
  statement["comparisons"] = comparisons.to_json()
  Ok(Some(Json::object(statement)))
}

///|
/// Comparison notes survive interrupted requests, but cannot leak into another
/// question, source revision, or collected result through navigation.
fn clear_salon_fields(fields : Map[String, String]) -> Map[String, String] {
  let kept : Map[String, String] = Map([])
  for key, value in fields {
    if !key.has_prefix("work_salon_") {
      kept[key] = value
    }
  }
  kept
}
