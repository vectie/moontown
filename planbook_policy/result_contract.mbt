///|
pub fn repair_result_contract() -> String {
  "planbook.repair.result.v1"
}

///|
pub fn repair_result_decisions() -> Array[String] {
  ["accepted", "needs_external_owner", "blocked", "no_change"]
}

///|
pub fn repair_result_engineering_evidence_markers() -> Array[String] {
  [
    "validation:", "diff_summary:", "plan_update_status:", "commit_status:", "commit_message:",
    "push_status:",
  ]
}

///|
pub fn repair_result_mentions_criterion(
  text : String,
  criterion_id : String,
) -> Bool {
  text.contains("criterion_id: \{criterion_id}") ||
  text.contains("\"criterion_id\":\"\{criterion_id}\"") ||
  text.contains("\"criterion_id\": \"\{criterion_id}\"")
}

///|
pub fn repair_result_has_decision(text : String, decision : String) -> Bool {
  text.contains("repair_decision: \{decision}") ||
  text.contains("\"repair_decision\":\"\{decision}\"") ||
  text.contains("\"repair_decision\": \"\{decision}\"")
}

///|
pub fn repair_result_has_any_decision(text : String) -> Bool {
  repair_result_decisions().any(fn(decision) {
    repair_result_has_decision(text, decision)
  })
}

///|
pub fn repair_result_has_accepted_decision(text : String) -> Bool {
  repair_result_has_decision(text, "accepted")
}

///|
pub fn repair_result_has_external_owner_decision(text : String) -> Bool {
  repair_result_has_decision(text, "needs_external_owner")
}

///|
pub fn repair_result_has_blocked_decision(text : String) -> Bool {
  repair_result_has_decision(text, "blocked")
}

///|
pub fn repair_result_has_no_change_decision(text : String) -> Bool {
  repair_result_has_decision(text, "no_change")
}

///|
pub fn repair_result_has_handoff_decision(text : String) -> Bool {
  repair_result_has_external_owner_decision(text) ||
  repair_result_has_blocked_decision(text)
}

///|
pub fn repair_result_records_validation_passes(text : String) -> Bool {
  let lowered = text.to_lower()
  repair_required_commands().all(fn(command) {
    lowered.contains(command.to_lower()) && lowered.contains("passed")
  })
}

///|
pub fn repair_result_has_engineering_evidence(text : String) -> Bool {
  repair_result_records_validation_passes(text) &&
  repair_result_engineering_evidence_markers().all(fn(marker) {
    text.contains(marker)
  })
}

///|
pub fn repair_result_satisfies_contract(
  text : String,
  criterion_id : String,
  source_root : String,
) -> Bool {
  if !repair_result_mentions_criterion(text, criterion_id) {
    return false
  }
  if !repair_result_has_any_decision(text) {
    return false
  }
  !repair_result_has_accepted_decision(text) ||
  (
    repair_result_has_engineering_evidence(text) &&
    repair_text_has_valid_patch_receipt(text, criterion_id, source_root)
  )
}

///|
pub fn repair_run_result_satisfies_contract(
  payload : Json,
  text : String,
  run_id : String,
  criterion_id : String,
  source_root : String,
) -> Bool {
  if !repair_result_mentions_criterion(text, criterion_id) {
    return false
  }
  if !repair_result_has_any_decision(text) {
    return false
  }
  !repair_result_has_accepted_decision(text) ||
  repair_run_result_has_accepted_evidence(
    payload, text, run_id, criterion_id, source_root,
  )
}

///|
pub fn repair_run_result_has_accepted_evidence(
  payload : Json,
  text : String,
  run_id : String,
  criterion_id : String,
  source_root : String,
) -> Bool {
  repair_result_has_accepted_decision(text) &&
  repair_result_has_engineering_evidence(text) &&
  repair_payload_has_valid_patch_receipt(
    payload, criterion_id, source_root, run_id,
  )
}
