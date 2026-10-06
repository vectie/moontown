///|
/// Check the owner-bound projection of an already validated native settlement.
/// This grants no runtime permission and performs no product acceptance.
pub fn wenyu_no_change_receipt_satisfies_contract(work : Work) -> Bool {
  if work.state != "completed" ||
    !wenyu_result_satisfies_contract(work, work.output, no_change=true) {
    return false
  }
  guard work.reservation is Some(reservation) else { return false }
  let receipt = work.receipt
  let native = field(receipt, "native_receipt")
  let verdict = field(receipt, "native_completion_verdict")
  let policy = field(work.request.acceptance_policy, "completion_policy")
  let body = @json.parse(reservation.request_body) catch { _ => return false }
  if field(field(field(body, "payload"), "task_contract"), "completion_policy") !=
    policy ||
    text(receipt, "contract") != "wenyu.build.native_no_change_receipt.v1" ||
    text(receipt, "engineering_status") != "no_change" ||
    text(receipt, "result_decision") != "no_change" ||
    text(receipt, "completion_outcome") != "no_change" ||
    text(receipt, "acceptance_scope") != "engineering_only" ||
    text(receipt, "original_task_acceptance") != "unevaluated" ||
    field(receipt, "changed_files") != [].to_json() ||
    field(receipt, "baseline") != work.baseline ||
    text(receipt, "diff_check_status") != "passed" ||
    text(receipt, "commit_status") != "not_requested" ||
    text(receipt, "push_status") != "not_requested" ||
    field(receipt, "commit_sha") != Json::null() ||
    field(receipt, "focused_diff") != Json::null() ||
    text(receipt, "native_evidence_digest") == "" ||
    text(native, "status") != "runtime-completed" ||
    verdict != field(field(native, "execution"), "completion_verdict") ||
    text(verdict, "kind") != "mooncode-coding-completion-verdict" ||
    field(verdict, "accepted") != true.to_json() ||
    text(verdict, "completion_contract") != "mooncode.completion-outcome.v1" ||
    text(verdict, "completion_outcome") != "no_change" ||
    text(verdict, "acceptance_scope") != "engineering_only" ||
    text(verdict, "original_task_acceptance") != "unevaluated" ||
    field(receipt, "no_change") != field(verdict, "no_change") ||
    text(field(verdict, "no_change"), "reason") != "already_satisfied" ||
    text(field(verdict, "no_change"), "observation").trim() == "" ||
    field(receipt, "required_check_evidence") !=
    field(verdict, "required_check_evidence") ||
    finish_answer(native) != work.output {
    return false
  }
  let final = field(receipt, "final_observation")
  for key in ["root", "head", "index_digest", "source_digest"] {
    if text(work.baseline, key) == "" ||
      text(work.baseline, key) != text(final, key) {
      return false
    }
  }
  if text(final, "root") != work.request.execution_root ||
    text(final, "source_digest") != text(receipt, "checked_source_digest") {
    return false
  }
  let required = rows(policy, "required_checks")
  let claims = rows(receipt, "required_check_evidence")
  let checks = rows(receipt, "validation_commands")
  if claims.length() != required.length() ||
    checks.length() != required.length() {
    return false
  }
  for check in required {
    let matching = claims.filter(claim => text(claim, "id") == text(check, "id"))
    if matching.length() != 1 {
      return false
    }
    let id = text(matching[0], "event_id")
    if id == "" ||
      !rows(field(verdict, "no_change"), "evidence_refs").contains(id.to_json()) ||
      !rows(receipt, "event_ids").contains(id.to_json()) {
      return false
    }
    let proofs = checks.filter(proof => text(proof, "event_id") == id)
    if proofs.length() != 1 ||
      text(proofs[0], "command") != text(check, "command") ||
      text(proofs[0], "cwd") != work.request.execution_root ||
      field(proofs[0], "exit_code") != (0).to_json() {
      return false
    }
  }
  true
}

///|
/// Existing mutation receipts may predate optional completion projections, but
/// an explicit contradictory projection is never a valid mutation result.
pub fn wenyu_mutation_receipt_satisfies_contract(work : Work) -> Bool {
  if work.state != "completed" ||
    !wenyu_result_satisfies_contract(work, work.output) ||
    text(work.receipt, "engineering_status") != "applied_and_validated" {
    return false
  }
  let receipt = work.receipt
  let native = field(receipt, "native_receipt")
  let verdict = field(field(native, "execution"), "completion_verdict")
  if !["", "implemented"].contains(text(receipt, "result_decision")) ||
    !["", "mutation"].contains(text(receipt, "completion_outcome")) ||
    !["", "mutation"].contains(text(verdict, "completion_outcome")) ||
    field(receipt, "no_change") != Json::null() ||
    field(verdict, "no_change") != Json::null() ||
    field(receipt, "native_completion_verdict") != Json::null() {
    return false
  }
  if native != Json::null() {
    if text(native, "status") != "runtime-completed" ||
      finish_answer(native) != work.output {
      return false
    }
    let mut finish = Json::null()
    for result in rows(field(native, "execution"), "tool_results") {
      if text(result, "tool") == "finish" &&
        field(result, "accepted") == true.to_json() &&
        field(field(result, "result"), "is_error") != true.to_json() {
        finish = field(field(result, "result"), "metadata")
      }
    }
    if !["", "mutation"].contains(text(finish, "completion_outcome")) ||
      field(finish, "no_change") != Json::null() {
      return false
    }
  }
  if wenyu_no_change_enabled(work.request) {
    let baseline = field(receipt, "baseline")
    let final = field(receipt, "final_observation")
    if native == Json::null() ||
      text(receipt, "result_decision") != "implemented" ||
      rows(receipt, "changed_files").is_empty() ||
      text(baseline, "source_digest") == "" ||
      text(final, "source_digest") == "" ||
      text(baseline, "source_digest") == text(final, "source_digest") {
      return false
    }
  }
  true
}
