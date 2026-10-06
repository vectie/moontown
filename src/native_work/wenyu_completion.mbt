///|
/// An owner explicitly freezes this policy for a new Wenyu request. The checks
/// are derived from its existing validation commands, never a weaker checklist.
pub fn wenyu_completion_policy(commands : Array[String]) -> Json {
  let checks : Array[Json] = []
  for index, command in commands {
    checks.push({
      "id": "check-" + (index + 1).to_string(),
      "tool": "shell",
      "command": command,
      "cwd": ".",
      "exit_code": 0,
    })
  }
  {
    "contract": "mooncode.completion-outcome.v1",
    "allowed_outcomes": ["mutation", "no_change"],
    "no_change_reason": "already_satisfied",
    "alternative_milestone_ids": ["implementation"],
    "required_checks": checks,
    "evidence_scope": "native_tool_journal",
    "acceptance_scope": "engineering_only",
    "no_change_receipt_contract": "wenyu.build.native_no_change_receipt.v1",
  }
}

///|
fn wenyu_no_change_enabled(request : Request) -> Bool {
  field(request.acceptance_policy, "completion_policy") != Json::null() &&
  wenyu_policy_valid(request)
}

///|
fn wenyu_completion_guidance(work : Work) -> String {
  if wenyu_no_change_enabled(work.request) {
    "Every frozen validation command is required after the final source mutation or failed tool. Either return outcome implemented with attested source mutation, or outcome no_change with the exact frozen completion policy, accepted already_satisfied checkpoint/finish evidence and no net source change. Only the implementation milestone has an alternative; preserve all other original milestone requirements. Explain the already-existing behavior with source evidence. Original-task acceptance remains unevaluated and requires human product review. Never create a fake edit. Do not commit, push, or write Book pages."
  } else {
    "Completion requires attested source mutation and all frozen validation commands after the final mutation. No-change completion is not enabled. Do not commit or push."
  }
}

///|
fn native_no_change_receipt_contract(kind : String) -> String {
  match kind {
    "wenyu_build" => "wenyu.build.native_no_change_receipt.v1"
    "planbook_repair" => "planbook.repair.native_no_change_receipt.v1"
    _ => ""
  }
}
