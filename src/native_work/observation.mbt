///|
fn same_binding(value : Json, reservation : Reservation) -> Bool {
  text(value, "protocol") == "mooncode.v1" &&
  text(value, "session_id") == reservation.session_id &&
  text(value, "book_root") == reservation.execution_root &&
  text(value, "owner") == "moonclaw"
}

///|
fn finish_answer(receipt : Json) -> String {
  let mut answer = ""
  for item in rows(field(receipt, "execution"), "tool_results") {
    if text(item, "tool") != "finish" ||
      field(item, "accepted") != true.to_json() {
      continue
    }
    let result = field(item, "result")
    if field(result, "is_error") == true.to_json() {
      continue
    }
    let explicit = text(field(result, "metadata"), "answer")
    answer = if explicit != "" { explicit } else { text(result, "output") }
  }
  answer
}

///|
/// Only native receipt/event facts are examined. An answer's claims about
/// tool use, model identity, validation or mutation cannot grant acceptance.
async fn observe(
  work : Work,
  claim : Json,
  events : Json,
  service : Json,
  instance : String,
  now : UInt64,
) -> Work {
  let reservation = work.reservation.unwrap()
  for value in [claim, events, service] {
    if !same_binding(value, reservation) {
      return waiting(
        work, "dispatch_uncertain", "native_observation_identity_mismatch", now,
      )
    }
  }
  let mut selected = Json::null()
  let mut found = false
  for
    category in [
      "claimable_commands", "claimed_commands", "order_blocked_commands", "delivered_commands",
      "invalid_commands",
    ] {
    for item in rows(claim, category) {
      if text(item, "command_id") == reservation.command_id {
        if found {
          return waiting(
            work, "dispatch_uncertain", "native_command_identity_conflict", now,
          )
        }
        selected = item
        found = true
      }
    }
  }
  if !found {
    if !work.observed_instances.contains(instance) {
      return waiting(
        work, "dispatch_uncertain", "runtime_continuity_unverified", now,
      )
    }
    return waiting(work, "queued", "", now)
  }
  let receipt = field(selected, "receipt")
  let accepted_command = field(selected, "command")
  let expected_command = @json.parse(reservation.request_body)
  if accepted_command != expected_command {
    return waiting(
      work, "dispatch_uncertain", "native_command_body_mismatch", now,
    )
  }
  let status = text(receipt, "status")
  if status != "" &&
    (
      text(receipt, "session_id") != reservation.session_id ||
      text(receipt, "command_id") != reservation.command_id
    ) {
    return waiting(
      work, "dispatch_uncertain", "native_receipt_identity_mismatch", now,
    )
  }
  let instances = work.observed_instances.copy()
  if !instances.contains(instance) {
    instances.push(instance)
  }
  let work = { ..work, observed_instances: instances, }
  if [
      "runtime-failed", "runtime-rejected", "runtime-cancelled", "runtime-completed",
    ].contains(status) &&
    (
      !same_binding(receipt, reservation) ||
      field(receipt, "command") != expected_command
    ) {
    return waiting(
      work, "dispatch_uncertain", "native_receipt_command_binding_mismatch", now,
    )
  }
  if ["runtime-failed", "runtime-rejected", "runtime-cancelled"].contains(
      status,
    ) {
    let owner_receipt = if work.request.kind == "wenyu_build" {
      let final_snapshot = source_snapshot(work.request.execution_root) catch {
        _ => Json::null()
      }
      wenyu_failure_receipt(work, receipt, events, final_snapshot, status)
    } else {
      receipt
    }
    return {
      ..work,
      state: if status == "runtime-cancelled" {
        "cancelled"
      } else {
        "failed"
      },
      blocked_reason: status,
      receipt: owner_receipt,
      last_attempt_at_ms: now,
    }
  }
  if status != "runtime-completed" {
    if unresolved_approval(rows(events, "events"), reservation) {
      return waiting(work, "awaiting_approval", "native_approval_required", now)
    }
    return waiting(work, "running", "", now)
  }
  if !same_binding(receipt, reservation) ||
    field(receipt, "command") != expected_command {
    return waiting(
      work, "dispatch_uncertain", "native_receipt_command_binding_mismatch", now,
    )
  }
  if is_workspace_change(work.request.kind) {
    let final_snapshot = source_snapshot(work.request.execution_root) catch {
      _ =>
        return waiting(
          work, "waiting_source_binding", "source_final_observation_unavailable",
          now,
        )
    }
    let check = @integration.run("git", [
      "-C",
      work.request.execution_root,
      "diff",
      "--check",
      "--no-ext-diff",
      "--no-textconv",
    ])
    let result = reconcile_repair_evidence(
      work,
      receipt,
      events,
      final_snapshot,
      check.status,
      now,
    )
    let result = attach_focused_diff(result, now)
    let result = verify_final_source_freshness(result, now)
    if result.state == "waiting_result" {
      if work.request.kind == "wenyu_build" {
        return {
          ..result,
          state: "failed",
          output: "",
          receipt: wenyu_failure_receipt(
            work,
            receipt,
            events,
            final_snapshot,
            result.blocked_reason,
          ),
        }
      }
      return {
        ..result,
        state: "failed",
        receipt: {
          "contract": "planbook.repair.native_patch_receipt.v1",
          "request_id": work.id,
          "request_digest": work.request_digest,
          "criterion_id": work.request.criterion_id,
          "source_root": work.request.execution_root,
          "engineering_status": if text(work.baseline, "source_digest") !=
            text(final_snapshot, "source_digest") {
            "applied_validation_failed"
          } else {
            "blocked"
          },
          "commit_status": "not_requested",
          "push_status": "not_requested",
          "push_performed": null,
          "publication_verification": "not_verified",
          "blocked_reason": result.blocked_reason,
          "native_receipt": receipt,
          "final_observation": final_snapshot,
          "native_evidence_digest": digest(events.stringify()),
        },
      }
    }
    return result
  }
  // Review execution enforcement is not yet available in the current runtime.
  // Do not accept a host-supplied assertion as proof of the missing boundary.
  // This owner receipt seam stays fail-closed until the independently verified
  // runtime contract and full evidence validator land.
  let answer = finish_answer(receipt)
  if !@book_quality.review_result_satisfies_contract(answer) {
    return waiting(
      work, "waiting_result", "review_output_contract_invalid", now,
    )
  }
  {
    ..waiting(
      work, "waiting_native_capability", "read_only_runtime_evidence_unverified",
      now,
    ),
    receipt,
  }
}

///|
fn unresolved_approval(events : Array[Json], reservation : Reservation) -> Bool {
  let mut pending : Json? = None
  for event in events {
    if text(event, "session_id") != reservation.session_id ||
      text(event, "command_id") != reservation.command_id {
      continue
    }
    if text(event, "state") == "awaiting-approval" {
      pending = Some(event)
    } else if text(event, "kind") == "runtime.turn_checkpointed" {
      pending = None
    }
  }
  guard pending is Some(pending) else { return false }
  let approval_id = text(pending, "approval_id")
  for event in events {
    if text(event, "session_id") == reservation.session_id &&
      approval_id != "" &&
      text(event, "approval_id") == approval_id &&
      (
        ["approved", "rejected", "cancelled"].contains(text(event, "state")) ||
        [
          "tool.approval_approved", "tool.approval_rejected", "tool.approval_cancelled",
        ].contains(text(event, "kind"))
      ) {
      return false
    }
  }
  true
}
