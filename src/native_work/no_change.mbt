///|
/// Town verifies the runtime-owned verdict against frozen policy and journal
/// evidence. Worker observations remain separate from original-task acceptance.
fn validate_no_change(
  work : Work,
  native_receipt : Json,
  events : Json,
  final_snapshot : Json,
  changed : Array[Json],
  checks : Array[Json],
  last_mutation : Int,
) -> String {
  let policy = field(work.request.acceptance_policy, "completion_policy")
  let reserved = @json.parse(work.reservation.unwrap().request_body) catch {
    _ => return "native_no_change_policy_binding_invalid"
  }
  if policy !=
    field(
      field(field(reserved, "payload"), "task_contract"),
      "completion_policy",
    ) ||
    text(policy, "contract") != "mooncode.completion-outcome.v1" ||
    !rows(policy, "allowed_outcomes").contains("no_change".to_json()) ||
    text(policy, "no_change_reason") != "already_satisfied" ||
    text(policy, "evidence_scope") != "native_tool_journal" ||
    text(policy, "acceptance_scope") != "engineering_only" ||
    text(policy, "no_change_receipt_contract") !=
    native_no_change_receipt_contract(work.request.kind) ||
    native_no_change_receipt_contract(work.request.kind) == "" {
    return "native_no_change_policy_binding_invalid"
  }
  if !changed.is_empty() ||
    text(work.baseline, "source_digest") == "" ||
    text(work.baseline, "source_digest") !=
    text(final_snapshot, "source_digest") {
    return "native_no_change_source_changed"
  }
  let execution = field(native_receipt, "execution")
  let verdict = field(execution, "completion_verdict")
  let proposal = field(verdict, "no_change")
  if text(verdict, "kind") != "mooncode-coding-completion-verdict" ||
    field(verdict, "accepted") != true.to_json() ||
    text(verdict, "completion_contract") != "mooncode.completion-outcome.v1" ||
    text(verdict, "completion_outcome") != "no_change" ||
    text(verdict, "acceptance_scope") != "engineering_only" ||
    text(verdict, "original_task_acceptance") != "unevaluated" ||
    text(proposal, "reason") != "already_satisfied" ||
    text(proposal, "observation").trim() == "" {
    return "native_no_change_verdict_invalid"
  }
  let ordered = rows(events, "events")
  let accepted : Map[String, Json] = Map([])
  let positions : Map[String, Int] = Map([])
  let identities : Array[String] = []
  let mut sequence = 0UL
  let terminal = @string.parse_uint64(text(native_receipt, "journal_sequence")) catch {
    _ => 0UL
  }
  let mut latest_invalidating = last_mutation
  let mut checkpoint = Json::null()
  let mut checkpoint_index = -1
  let mut finish = Json::null()
  let mut finish_index = -1
  for index, event in ordered {
    if text(event, "source") != "moonclaw-native-tool-exec" {
      continue
    }
    let reservation = work.reservation.unwrap()
    if text(event, "book_root") != reservation.execution_root ||
      text(event, "session_id") != reservation.session_id ||
      text(event, "command_id") != reservation.command_id {
      continue
    }
    let next_sequence = @string.parse_uint64(text(event, "journal_sequence")) catch {
      _ => 0UL
    }
    let id = text(event, "id")
    if id == "" ||
      identities.contains(id) ||
      next_sequence <= sequence ||
      terminal <= next_sequence {
      return "native_no_change_journal_order_invalid"
    }
    identities.push(id)
    sequence = next_sequence
    if !successful_native_event(event, work) {
      latest_invalidating = index
      continue
    }
    accepted[id] = event
    positions[id] = index
    let metadata = field(field(event, "tool_result"), "metadata")
    if text(event, "tool") == "checkpoint" {
      checkpoint = metadata
      checkpoint_index = index
    }
    if text(event, "tool") == "finish" {
      finish = metadata
      finish_index = index
    }
  }
  let checkpoint_proposal = field(checkpoint, "checkpoint")
  if field(checkpoint, "all_done") != true.to_json() ||
    text(checkpoint_proposal, "completion_outcome") != "no_change" ||
    field(checkpoint_proposal, "no_change") != proposal ||
    text(finish, "completion_outcome") != "no_change" ||
    field(finish, "no_change") != proposal ||
    checkpoint_index <= latest_invalidating ||
    finish_index <= checkpoint_index {
    return "native_no_change_checkpoint_finish_mismatch"
  }
  let alternatives = rows(policy, "alternative_milestone_ids")
  let resolved : Array[String] = []
  for milestone in rows(checkpoint_proposal, "milestones") {
    if text(milestone, "status") != "done" {
      return "native_no_change_milestone_invalid"
    }
    let mutation_kind = ["mutation", "path_changed"].contains(
      text(milestone, "evidence_kind"),
    )
    if mutation_kind && text(milestone, "resolution") != "already_satisfied" {
      return "native_no_change_milestone_invalid"
    }
    if text(milestone, "resolution") == "already_satisfied" {
      let id = text(milestone, "id")
      if !mutation_kind ||
        !alternatives.contains(id.to_json()) ||
        resolved.contains(id) {
        return "native_no_change_milestone_invalid"
      }
      resolved.push(id)
    }
  }
  if rows(checkpoint_proposal, "milestones").is_empty() {
    return "native_no_change_milestone_invalid"
  }
  let mut final_finish = Json::null()
  for result in rows(execution, "tool_results") {
    if text(result, "tool") == "finish" &&
      field(result, "accepted") == true.to_json() &&
      field(field(result, "result"), "is_error") != true.to_json() {
      final_finish = field(field(result, "result"), "metadata")
    }
  }
  if text(final_finish, "completion_outcome") != "no_change" ||
    field(final_finish, "no_change") != proposal {
    return "native_no_change_finish_projection_mismatch"
  }
  let references : Array[String] = []
  for reference in rows(proposal, "evidence_refs") {
    guard reference is String(id) &&
      id != "" &&
      !references.contains(id) &&
      accepted.contains(id) &&
      positions.get(id).unwrap_or(checkpoint_index) < checkpoint_index else {
      return "native_no_change_evidence_reference_invalid"
    }
    references.push(id)
  }
  if references.is_empty() {
    return "native_no_change_evidence_reference_invalid"
  }
  let required = rows(policy, "required_checks")
  let claims = rows(verdict, "required_check_evidence")
  if required.is_empty() || required.length() != claims.length() {
    return "native_no_change_required_check_invalid"
  }
  let ids : Array[String] = []
  for check in required {
    let id = text(check, "id")
    let tool = text(check, "tool")
    let command = text(check, "command")
    let cwd = text(check, "cwd")
    if id == "" ||
      ids.contains(id) ||
      !["shell", "moon_cmd"].contains(tool) ||
      command == "" ||
      cwd == "" ||
      field(check, "exit_code") != (0).to_json() {
      return "native_no_change_required_check_invalid"
    }
    ids.push(id)
    let matching = claims.filter(claim => text(claim, "id") == id)
    if matching.length() != 1 {
      return "native_no_change_required_check_invalid"
    }
    let event_id = text(matching[0], "event_id")
    guard accepted.get(event_id) is Some(event) &&
      positions.get(event_id) is Some(position) &&
      references.contains(event_id) &&
      position > latest_invalidating &&
      position < checkpoint_index else {
      return "native_no_change_required_check_stale_or_missing"
    }
    // A later attempt at this exact command supersedes the selected proof,
    // including accepted nonzero exits, wrong cwd/tool and invalid assurance.
    // This applies to task-specific checks absent from the legacy command list.
    for later in ordered[position + 1:] {
      let later_tool = text(later, "tool")
      let reservation = work.reservation.unwrap()
      if text(later, "source") != "moonclaw-native-tool-exec" ||
        text(later, "session_id") != reservation.session_id ||
        text(later, "command_id") != reservation.command_id ||
        text(later, "book_root") != reservation.execution_root ||
        !["shell", "moon_cmd"].contains(later_tool) {
        continue
      }
      let later_metadata = field(field(later, "tool_result"), "metadata")
      let later_command = text(
        later_metadata,
        if later_tool == "shell" {
          "cmd"
        } else {
          "command"
        },
      )
      if later_command == command {
        return "native_no_change_required_check_superseded"
      }
    }
    let metadata = field(field(event, "tool_result"), "metadata")
    let actual_command = text(
      metadata,
      if tool == "shell" {
        "cmd"
      } else {
        "command"
      },
    )
    let actual_cwd = text(metadata, "cwd")
    let same_cwd = actual_cwd == cwd ||
      (
        [".", work.request.execution_root].contains(cwd) &&
        [".", work.request.execution_root].contains(actual_cwd)
      )
    let sandbox = field(metadata, "sandbox_evidence")
    if text(event, "tool") != tool ||
      actual_command != command ||
      !same_cwd ||
      text(metadata, "execution_sandbox_policy") != "grant-bound" ||
      field(metadata, "exit_code") != (0).to_json() ||
      text(metadata, "run_id") == "" ||
      text(metadata, "approval_id") == "" ||
      text(sandbox, "command_digest") == "" ||
      field(sandbox, "cleanup_verified") != true.to_json() ||
      field(metadata, "pipeline_exit_ambiguous") == true.to_json() {
      return "native_no_change_required_check_invalid"
    }
    if !checks.any(proof => text(proof, "event_id") == event_id) {
      checks.push({
        "command": command,
        "cwd": actual_cwd,
        "exit_code": 0,
        "event_id": event_id,
        "run_id": text(metadata, "run_id"),
        "approval_id": text(metadata, "approval_id"),
        "command_digest": text(sandbox, "command_digest"),
        "sandbox_evidence": sandbox,
        "event_index": position,
      })
    }
  }
  ""
}
