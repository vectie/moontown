///|
async fn apply_owner_result(work : Work) -> Work {
  if editor_owner_opted_in(work.request) {
    return apply_editor_owner_result(work)
  }
  if work.state != "completed" || work.request.kind != "planbook_repair" {
    return work
  }
  let expected = work.request.book_root + "/raw/repair/repair-result.md"
  if work.request.result_path != expected || !validate_book(work.request) {
    return work
  }
  let engineering = text(work.receipt, "engineering_status")
  if !["applied_and_validated", "no_change"].contains(engineering) {
    return work
  }
  let decision = if engineering == "no_change" {
    "no_change"
  } else {
    "accepted"
  }
  let result = "contract: planbook.repair.result.v1\ncriterion_id: " +
    work.request.criterion_id +
    "\nrepair_decision: " +
    decision +
    "\nengineering_status: " +
    engineering +
    "\ncommit_status: not_requested\npush_status: not_requested\npush_performed: unknown\npublication_verification: not_verified\n\n" +
    (if engineering == "applied_and_validated" {
      "Applied and validated; uncommitted.\n\n"
    } else {
      "native_receipt_contract: planbook.repair.native_no_change_receipt.v1\noriginal_task_acceptance: unevaluated\nacceptance_scope: engineering_only\n\nNo net source change; required checks passed.\n\nWorker observation (original-task acceptance unevaluated):\n"
    }) +
    work.output +
    "\n"
  @support.write_text_file(
    expected + ".native-receipt.json",
    work.receipt.stringify(indent=2),
  )
  @support.write_text_file(expected, result)
  work
}

///|
async fn verify_final_source_freshness(work : Work, now : UInt64) -> Work {
  if work.state != "completed" || !is_workspace_change(work.request.kind) {
    return work
  }
  let current = source_snapshot(work.request.execution_root) catch {
    _ =>
      return waiting(
        work, "waiting_result", "native_source_changed_during_reconciliation", now,
      )
  }
  let observed = field(work.receipt, "final_observation")
  for key in ["root", "head", "index_digest", "source_digest"] {
    if text(current, key) != text(observed, key) {
      return waiting(
        work, "waiting_result", "native_source_changed_during_reconciliation", now,
      )
    }
  }
  work
}

///|
async fn attach_focused_diff(work : Work, now : UInt64) -> Work {
  if work.state != "completed" ||
    text(work.receipt, "engineering_status") != "applied_and_validated" {
    return work
  }
  let patches : Array[String] = []
  for file in rows(work.receipt, "changed_files") {
    let path = text(file, "path")
    let before = text(file, "before_fingerprint")
    let args = if before == "absent" {
      [
        "-C",
        work.request.execution_root,
        "diff",
        "--no-index",
        "--binary",
        "--no-ext-diff",
        "--no-textconv",
        "--",
        "/dev/null",
        path,
      ]
    } else {
      [
        "-C",
        work.request.execution_root,
        "diff",
        "--binary",
        "--no-ext-diff",
        "--no-textconv",
        "HEAD",
        "--",
        path,
      ]
    }
    let diff = @integration.run("git", args)
    if diff.status != 0 && !(before == "absent" && diff.status == 1) {
      return waiting(
        work, "waiting_result", "native_focused_diff_unavailable", now,
      )
    }
    patches.push(diff.stdout)
  }
  let diff = patches.join("\n")
  if diff == "" || diff.length() > 2_000_000 {
    return waiting(
      work, "waiting_result", "native_focused_diff_missing_or_too_large", now,
    )
  }
  let current = source_snapshot(work.request.execution_root)
  if text(current, "source_digest") !=
    text(work.receipt, "checked_source_digest") {
    return waiting(
      work, "waiting_result", "native_source_changed_during_reconciliation", now,
    )
  }
  if work.receipt is Object(fields) {
    fields["focused_diff"] = diff.to_json()
    fields["focused_diff_digest"] = digest(diff).to_json()
    { ..work, receipt: Json::object(fields), }
  } else {
    waiting(work, "waiting_result", "native_receipt_invalid", now)
  }
}

///|
pub async fn accepted_repair(
  book_root : String,
  criterion : String,
  path? : String = default_path(),
) -> Bool {
  if !@fs.exists(path) {
    return false
  }
  for work in load(path~).work {
    if work.request.kind == "planbook_repair" &&
      work.request.book_root == book_root &&
      work.request.criterion_id == criterion &&
      work.state == "completed" &&
      text(work.receipt, "engineering_status") == "applied_and_validated" {
      if editor_owner_pending(work) {
        continue
      }
      if !source_still_bound(work.request.source_binding, strict_digest=false) {
        continue
      }
      let current = source_snapshot(work.request.execution_root) catch {
        _ => continue
      }
      if text(current, "source_digest") ==
        text(work.receipt, "checked_source_digest") &&
        text(current, "index_digest") ==
        text(field(work.receipt, "final_observation"), "index_digest") {
        return true
      }
    }
  }
  false
}
