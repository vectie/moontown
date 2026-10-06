///|
/// Only these owners may use the source-change evidence path. Review retains
/// its independent, fail-closed execution policy.
pub fn is_workspace_change(kind : String) -> Bool {
  kind == "planbook_repair" || kind == "wenyu_build"
}

///|
fn wenyu_policy_valid(request : Request) -> Bool {
  let policy = request.acceptance_policy
  if request.kind != "wenyu_build" ||
    request.output_contract != "wenyu.build.native-result.v1" ||
    text(policy, "contract") != "wenyu.build.native-policy.v1" ||
    text(policy, "goal_id").trim() == "" ||
    text(policy, "task_id").trim() == "" ||
    text(policy, "task_kind") != "code-patch" ||
    text(policy, "commit_requirement") != "not_requested" ||
    field(policy, "preserve_preexisting_unrelated_dirty_files") !=
    true.to_json() ||
    field(policy, "push_requested") != false.to_json() {
    return false
  }
  let commands = rows(policy, "required_validation_commands")
  let seen : Array[String] = []
  for value in commands {
    guard value is String(command) &&
      command.trim() != "" &&
      !observed_forbidden_git_operation(command) &&
      !seen.contains(command) else {
      return false
    }
    seen.push(command)
  }
  let completion = field(policy, "completion_policy")
  !commands.is_empty() &&
  (completion == Json::null() || completion == wenyu_completion_policy(seen))
}

///|
/// Validate the exact Wenyu answer against its owner-frozen permission and
/// identities. Source mutation and checks are separately attested by the
/// workspace-change evidence validator; this predicate alone grants no success.
pub fn wenyu_result_satisfies_contract(
  work : Work,
  answer : String,
  no_change? : Bool = false,
) -> Bool {
  if !wenyu_policy_valid(work.request) ||
    answer.length() > 1_000_000 ||
    (no_change && !wenyu_no_change_enabled(work.request)) {
    return false
  }
  let result = @json.parse(answer, max_nesting_depth=4) catch {
    _ => return false
  }
  guard result is Object(fields) && fields.length() == 9 else { return false }
  // Core JSON parsing retains the last occurrence of duplicate keys. Count
  // top-level members in the already-valid text so hidden duplicates cannot
  // satisfy the exact owner schema after map normalization.
  let mut depth = 0
  let mut quoted = false
  let mut escaped = false
  let mut members = 0
  for character in answer {
    if quoted {
      if escaped {
        escaped = false
      } else if character == '\\' {
        escaped = true
      } else if character == '"' {
        quoted = false
      }
    } else if character == '"' {
      quoted = true
    } else if character == '{' || character == '[' {
      depth += 1
    } else if character == '}' || character == ']' {
      depth -= 1
    } else if character == ':' && depth == 1 {
      members += 1
    }
  }
  if members != 9 {
    return false
  }
  let keys = [
    "contract", "work_id", "book_id", "task_id", "goal_id", "outcome", "summary",
    "behavior", "residual_risks",
  ]
  for key, _ in fields {
    if !keys.contains(key) {
      return false
    }
  }
  if text(result, "contract") != work.request.output_contract ||
    text(result, "work_id") != work.id ||
    text(result, "book_id") != work.request.book_id ||
    text(result, "task_id") != text(work.request.acceptance_policy, "task_id") ||
    text(result, "goal_id") != text(work.request.acceptance_policy, "goal_id") ||
    text(result, "outcome") !=
    (if no_change { "no_change" } else { "implemented" }) ||
    text(result, "summary").trim() == "" {
    return false
  }
  guard field(result, "behavior") is String(_) &&
    field(result, "residual_risks") is Array(risks) else {
    return false
  }
  risks.all(value => value is String(_))
}

///|
fn workspace_reservation_blocker(state : State, work : Work) -> String {
  if !is_workspace_change(work.request.kind) || work.reservation is Some(_) {
    return ""
  }
  for existing in state.work {
    if existing.id != work.id &&
      !terminal(existing.state) &&
      is_workspace_change(existing.request.kind) &&
      existing.request.execution_root == work.request.execution_root &&
      existing.reservation is Some(_) {
      return "source_workspace_busy: " + existing.id
    }
  }
  ""
}

///|
fn wenyu_finish_schema(work : Work) -> Json {
  {
    "contract": "wenyu.build.native-result.v1",
    "work_id": work.id,
    "book_id": work.request.book_id,
    "task_id": text(work.request.acceptance_policy, "task_id"),
    "goal_id": text(work.request.acceptance_policy, "goal_id"),
    "outcome": if wenyu_no_change_enabled(work.request) {
      "no_change"
    } else {
      "implemented"
    },
    "summary": if wenyu_no_change_enabled(work.request) {
      "Describe the verified result"
    } else {
      "Describe the implemented change"
    },
    "behavior": "Describe the resulting behavior",
    "residual_risks": [],
  }
}

///|
fn wenyu_reserved_prompt(work : Work) -> String {
  work.request.prompt +
  (if wenyu_no_change_enabled(work.request) {
    "\n\nOwner-issued native result identity (return exactly these nine JSON keys, preserving the identity fields; choose outcome no_change for verified already-satisfied work or implemented for attested mutation, with your summary, behavior, and residual_risks; no extra keys or Markdown fences):\n"
  } else {
    "\n\nOwner-issued native result identity (return exactly this JSON schema, with your summary, behavior, and residual_risks; no extra keys or Markdown fences):\n"
  }) +
  wenyu_finish_schema(work).stringify() +
  "\n" +
  wenyu_completion_guidance(work) +
  "\n"
}

///|
fn wenyu_failure_receipt(
  work : Work,
  native_receipt : Json,
  events : Json,
  final_snapshot : Json,
  reason : String,
) -> Json {
  let reservation = work.reservation.unwrap()
  {
    "contract": "wenyu.build.native_patch_receipt.v1",
    "request_id": work.id,
    "request_digest": work.request_digest,
    "book_id": work.request.book_id,
    "task_id": text(work.request.acceptance_policy, "task_id"),
    "goal_id": text(work.request.acceptance_policy, "goal_id"),
    "book_root": work.request.book_root,
    "source_root": work.request.execution_root,
    "model_workspace": reservation.model_workspace,
    "model": reservation.model,
    "session_id": reservation.session_id,
    "command_id": reservation.command_id,
    "control_command_id": text(native_receipt, "control_command_id"),
    "request_body_digest": reservation.body_digest,
    "engineering_status": if final_snapshot == Json::null() {
      "source_unverified"
    } else if text(work.baseline, "source_digest") !=
      text(final_snapshot, "source_digest") {
      "applied_validation_failed"
    } else {
      "blocked"
    },
    "commit_status": "not_requested",
    "push_status": "not_requested",
    "push_performed": null,
    "publication_verification": "not_verified",
    "blocked_reason": reason,
    "baseline": work.baseline,
    "final_observation": final_snapshot,
    "native_receipt": native_receipt,
    "native_events": events,
    "native_evidence_digest": digest(events.stringify()),
    "output_contract": work.request.output_contract,
    "output_digest": digest(finish_answer(native_receipt)),
    "original_task_acceptance": "unevaluated",
  }
}

///|
fn wenyu_unreserved_receipt(work : Work, reason : String) -> Json {
  {
    "contract": "wenyu.build.native_patch_receipt.v1",
    "request_id": work.id,
    "request_digest": work.request_digest,
    "book_id": work.request.book_id,
    "task_id": text(work.request.acceptance_policy, "task_id"),
    "goal_id": text(work.request.acceptance_policy, "goal_id"),
    "book_root": work.request.book_root,
    "source_root": work.request.execution_root,
    "engineering_status": "not_started",
    "reservation_status": "not_reserved",
    "blocked_reason": reason,
    "baseline": work.baseline,
    "final_observation": null,
    "native_receipt": null,
    "commit_status": "not_requested",
    "push_status": "not_requested",
    "push_performed": null,
    "publication_verification": "not_verified",
    "original_task_acceptance": "unevaluated",
  }
}
