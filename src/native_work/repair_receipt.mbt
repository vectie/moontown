///|
fn successful_native_event(event : Json, work : Work) -> Bool {
  let reservation = work.reservation.unwrap()
  text(event, "source") == "moonclaw-native-tool-exec" &&
  text(event, "session_id") == reservation.session_id &&
  text(event, "command_id") == reservation.command_id &&
  text(event, "book_root") == reservation.execution_root &&
  text(event, "id") != "" &&
  field(field(event, "tool_result"), "ok") == true.to_json() &&
  field(field(event, "tool_result"), "is_error") == false.to_json()
}

///|
fn reconcile_repair_evidence(
  work : Work,
  native_receipt : Json,
  events : Json,
  final_snapshot : Json,
  diff_check_exit : Int,
  now : UInt64,
) -> Work {
  if work.request.kind == "wenyu_build" && !wenyu_policy_valid(work.request) {
    return waiting(work, "waiting_result", "wenyu_native_policy_invalid", now)
  }
  if text(work.request.acceptance_policy, "commit_requirement") !=
    "not_requested" {
    return waiting(
      work, "awaiting_commit", "native_required_selective_commit_missing", now,
    )
  }
  let baseline = work.baseline
  let before_files = field(baseline, "files")
  let final_files = field(final_snapshot, "files")
  if text(baseline, "root") != work.request.execution_root ||
    text(final_snapshot, "root") != work.request.execution_root ||
    text(baseline, "head") != text(final_snapshot, "head") {
    return waiting(
      work, "waiting_result", "native_source_head_or_root_changed", now,
    )
  }
  if text(baseline, "index_digest") != text(final_snapshot, "index_digest") {
    return waiting(
      work, "waiting_result", "native_unrelated_index_changed", now,
    )
  }
  let ordered = rows(events, "events")
  if field(events, "event_count") != ordered.length().to_json() {
    return waiting(
      work, "waiting_result", "native_event_evidence_incomplete", now,
    )
  }
  let authored : Map[String, Json] = Map([])
  let validations : Map[String, Json] = Map([])
  let process_evidence : Array[Json] = []
  let event_ids : Array[String] = []
  let dirty = rows(baseline, "dirty_paths")
  let mut last_mutation = -1
  let mut last_sequence = 0UL
  let terminal_sequence = @string.parse_uint64(
    text(native_receipt, "journal_sequence"),
  ) catch {
    _ => 0UL
  }
  if terminal_sequence == 0UL {
    return waiting(
      work, "waiting_result", "native_terminal_journal_evidence_missing", now,
    )
  }
  for index, event in ordered {
    if text(event, "source") == "moonclaw-native-tool-exec" &&
      text(event, "book_root") == work.request.execution_root &&
      text(event, "session_id") == work.reservation.unwrap().session_id &&
      text(event, "command_id") == work.reservation.unwrap().command_id &&
      ["shell", "moon_cmd"].contains(text(event, "tool")) {
      let metadata = field(field(event, "tool_result"), "metadata")
      let command = if text(event, "tool") == "shell" {
        text(metadata, "cmd")
      } else {
        text(metadata, "command")
      }
      if observed_forbidden_git_operation(command) {
        return waiting(
          work, "waiting_result", "native_forbidden_git_operation", now,
        )
      }
      process_evidence.push({
        "event_id": text(event, "id"),
        "command": command,
        "cwd": text(metadata, "cwd"),
        "exit_code": field(metadata, "exit_code"),
        "run_id": text(metadata, "run_id"),
        "approval_id": text(metadata, "approval_id"),
        "sandbox_evidence": field(metadata, "sandbox_evidence"),
      })
      validations.remove(command) |> ignore
    }
    let early_metadata = field(field(event, "tool_result"), "metadata")
    let failed_sandbox_mutation = text(event, "source") ==
      "moonclaw-native-tool-exec" &&
      text(event, "session_id") == work.reservation.unwrap().session_id &&
      text(event, "command_id") == work.reservation.unwrap().command_id &&
      text(event, "book_root") == work.request.execution_root &&
      ["shell", "moon_cmd"].contains(text(event, "tool")) &&
      text(early_metadata, "execution_sandbox_policy") == "grant-bound" &&
      field(early_metadata, "exit_code") is Number(_) &&
      text(early_metadata, "run_id") != "" &&
      text(early_metadata, "approval_id") != "" &&
      field(field(early_metadata, "sandbox_evidence"), "cleanup_verified") ==
      true.to_json() &&
      !rows(field(early_metadata, "sandbox_evidence"), "changes").is_empty()
    if !successful_native_event(event, work) && !failed_sandbox_mutation {
      continue
    }
    let sequence = @string.parse_uint64(text(event, "journal_sequence")) catch {
      _ => 0UL
    }
    if sequence <= last_sequence || terminal_sequence <= sequence {
      return waiting(
        work, "waiting_result", "native_journal_evidence_order_invalid", now,
      )
    }
    last_sequence = sequence
    let id = text(event, "id")
    if event_ids.contains(id) {
      return waiting(
        work, "waiting_result", "native_duplicate_evidence_id", now,
      )
    }
    event_ids.push(id)
    let tool = text(event, "tool")
    let metadata = field(field(event, "tool_result"), "metadata")
    for mutation in mutation_proofs(tool, metadata, before_files, final_files) {
      let path = text(mutation, "path")
      let before = text(mutation, "before_fingerprint")
      let after = text(mutation, "after_fingerprint")
      if !relative_path(path) || before == "" || after == "" {
        return waiting(
          work, "waiting_result", "native_mutation_fingerprint_missing", now,
        )
      }
      if dirty.contains(path.to_json()) {
        return waiting(
          work,
          "waiting_result",
          "native_preexisting_dirty_path_touched: " + path,
          now,
        )
      }
      let expected_before = match authored.get(path) {
        Some(previous) => text(previous, "after_fingerprint")
        None => {
          let value = text(before_files, path)
          if value == "" {
            "absent"
          } else {
            value
          }
        }
      }
      if before != expected_before {
        return waiting(
          work,
          "waiting_result",
          "native_mutation_chain_mismatch: " + path,
          now,
        )
      }
      authored[path] = {
        "path": path,
        "before_fingerprint": if text(before_files, path) == "" {
          "absent"
        } else {
          text(before_files, path)
        },
        "after_fingerprint": after,
        "event_id": id,
      }
      last_mutation = index
      validations.clear()
    }
    if tool == "shell" || tool == "moon_cmd" {
      let command = if tool == "shell" {
        text(metadata, "cmd")
      } else {
        text(metadata, "command")
      }
      let sandbox = field(metadata, "sandbox_evidence")
      // The native runtime already validates the operator's grant and its
      // assurance requirement, including supported AllowDegraded execution.
      // Preserve that evidence without imposing a stronger Town policy.
      // Validation may generate ignored build/runtime artifacts; authored
      // source changes must still have explicit native mutation fingerprints.
      if successful_native_event(event, work) &&
        text(metadata, "execution_sandbox_policy") == "grant-bound" &&
        field(metadata, "exit_code") == (0).to_json() &&
        text(metadata, "run_id") != "" &&
        text(metadata, "approval_id") != "" &&
        text(sandbox, "command_digest") != "" &&
        field(sandbox, "cleanup_verified") == true.to_json() &&
        field(metadata, "pipeline_exit_ambiguous") != true.to_json() &&
        [".", work.request.execution_root].contains(text(metadata, "cwd")) {
        validations[command] = {
          "command": command,
          "cwd": work.request.execution_root,
          "exit_code": 0,
          "event_id": id,
          "run_id": text(metadata, "run_id"),
          "command_digest": text(sandbox, "command_digest"),
          "approval_id": text(metadata, "approval_id"),
          "sandbox_evidence": sandbox,
          "event_index": index,
        }
      }
    }
  }
  let changed : Array[Json] = []
  let paths : Map[String, Bool] = Map([])
  for files in [before_files, final_files] {
    if files is Object(fields) {
      for path, _ in fields {
        paths[path] = true
      }
    }
  }
  for path, _ in paths {
    let before_mode = field(field(baseline, "executable"), path)
    let after_mode = field(field(final_snapshot, "executable"), path)
    if before_mode != Json::null() &&
      after_mode != Json::null() &&
      before_mode != after_mode {
      return waiting(
        work,
        "waiting_result",
        "native_unattested_executable_mode_change: " + path,
        now,
      )
    }
    let before = text(before_files, path)
    let after = text(final_files, path)
    if before == after {
      continue
    }
    guard authored.get(path) is Some(proof) &&
      text(proof, "after_fingerprint") == after else {
      return waiting(
        work,
        "waiting_result",
        "native_unattributed_or_final_file_mismatch: " + path,
        now,
      )
    }
    changed.push(proof)
  }
  for path, proof in authored {
    // A newly created then removed untracked file is absent from Git's final
    // inventory. Only the explicit no-change branch may normalize that final
    // absence; its complete mutation chain and final checks still apply.
    let restored_absence = text(proof, "after_fingerprint") == "absent" &&
      field(final_files, path) == Json::null() &&
      field(work.request.acceptance_policy, "completion_policy") != Json::null() &&
      text(
        field(field(native_receipt, "execution"), "completion_verdict"),
        "completion_outcome",
      ) ==
      "no_change"
    if text(proof, "after_fingerprint") != text(final_files, path) &&
      !restored_absence {
      return waiting(
        work,
        "waiting_result",
        "native_final_file_mismatch: " + path,
        now,
      )
    }
  }
  let answer = finish_answer(native_receipt)
  let verdict = field(field(native_receipt, "execution"), "completion_verdict")
  let no_change = changed.is_empty() ||
    text(verdict, "completion_outcome") == "no_change"
  if no_change &&
    field(work.request.acceptance_policy, "completion_policy") == Json::null() {
    // Current workspace_change completion requires accepted net mutation.
    // A synthetic completed/no-change receipt is not a supported native path.
    return waiting(
      work, "waiting_result", "native_no_change_settlement_unsupported", now,
    )
  }
  if work.request.kind == "wenyu_build" &&
    !wenyu_result_satisfies_contract(work, answer, no_change~) {
    return waiting(
      work, "waiting_result", "wenyu_native_output_contract_invalid", now,
    )
  }
  if editor_owner_opted_in(work.request) &&
    !editor_result_satisfies_contract(work, answer, no_change) {
    return waiting(
      work, "waiting_result", "editor_native_output_contract_invalid", now,
    )
  }
  if work.request.kind != "wenyu_build" &&
    !editor_owner_opted_in(work.request) &&
    !no_change &&
    !answer.split("\n").any(line => line.trim() == "repair_decision: accepted") {
    return waiting(
      work, "waiting_result", "native_repair_output_decision_missing", now,
    )
  }
  let checks : Array[Json] = []
  for
    required in rows(
      work.request.acceptance_policy,
      "required_validation_commands",
    ) {
    guard required is String(command) && validations.get(command) is Some(proof) else {
      return waiting(
        work,
        "waiting_result",
        "native_required_validation_missing_or_failed: " + required.stringify(),
        now,
      )
    }
    checks.push(proof)
  }
  if checks.is_empty() ||
    (!no_change && last_mutation < 0) ||
    diff_check_exit != 0 {
    return waiting(
      work, "waiting_result", "native_validation_or_diff_check_failed", now,
    )
  }
  if no_change {
    let reason = validate_no_change(
      work, native_receipt, events, final_snapshot, changed, checks, last_mutation,
    )
    if reason != "" {
      return waiting(work, "waiting_result", reason, now)
    }
  }
  let reservation = work.reservation.unwrap()
  let receipt : Json = {
    "contract": if no_change {
      native_no_change_receipt_contract(work.request.kind)
    } else if work.request.kind == "wenyu_build" {
      "wenyu.build.native_patch_receipt.v1"
    } else {
      "planbook.repair.native_patch_receipt.v1"
    },
    "request_id": work.id,
    "request_digest": work.request_digest,
    "criterion_id": work.request.criterion_id,
    "book_root": work.request.book_root,
    "source_root": work.request.execution_root,
    "model_workspace": reservation.model_workspace,
    "model": reservation.model,
    "session_id": reservation.session_id,
    "command_id": reservation.command_id,
    "request_body_digest": reservation.body_digest,
    "base_head": text(baseline, "head"),
    "final_head": text(final_snapshot, "head"),
    "changed_files": changed,
    "validation_commands": checks,
    "process_evidence": process_evidence,
    "checked_source_digest": text(final_snapshot, "source_digest"),
    "diff_check_status": "passed",
    "baseline": baseline,
    "final_observation": final_snapshot,
    "native_receipt": native_receipt,
    "native_evidence_digest": digest(events.stringify()),
    "event_ids": event_ids,
    "last_tool_journal_sequence": last_sequence.to_string(),
    "terminal_journal_sequence": terminal_sequence.to_string(),
    "runtime_instances": work.observed_instances,
    "output_contract": work.request.output_contract,
    "output_digest": digest(answer),
    "engineering_status": if no_change {
      "no_change"
    } else {
      "applied_and_validated"
    },
    "commit_status": "not_requested",
    "commit_sha": null,
    "push_status": "not_requested",
    "push_performed": null,
    "publication_verification": "not_verified",
    "result_decision": if no_change {
      "no_change"
    } else if work.request.kind == "wenyu_build" {
      "implemented"
    } else {
      "accepted"
    },
  }
  if work.request.kind == "wenyu_build" && receipt is Object(fields) {
    fields["book_id"] = work.request.book_id.to_json()
    fields["task_id"] = field(work.request.acceptance_policy, "task_id")
    fields["goal_id"] = field(work.request.acceptance_policy, "goal_id")
    fields["original_task_acceptance"] = "unevaluated".to_json()
  }
  if no_change && receipt is Object(fields) {
    fields["completion_outcome"] = "no_change".to_json()
    fields["acceptance_scope"] = "engineering_only".to_json()
    fields["original_task_acceptance"] = "unevaluated".to_json()
    fields["native_completion_verdict"] = verdict
    fields["no_change"] = field(verdict, "no_change")
    fields["required_check_evidence"] = field(
      verdict, "required_check_evidence",
    )
  }
  {
    ..work,
    state: "completed",
    blocked_reason: "",
    output: answer,
    receipt,
    last_attempt_at_ms: now,
  }
}
