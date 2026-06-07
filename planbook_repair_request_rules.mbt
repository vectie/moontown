///|
fn planbook_repair_request_task_rules() -> Array[String] {
  [
    planbook_repair_read_context_task_rule(),
    planbook_repair_ownership_decision_task_rule(),
    planbook_repair_exact_targets_task_rule(),
    planbook_repair_small_patch_task_rule(),
    planbook_repair_selected_feature_task_rule(),
    planbook_repair_validation_task_rule(),
    planbook_repair_diff_hygiene_task_rule(),
    planbook_repair_commit_task_rule(),
    planbook_repair_no_churn_task_rule(),
    planbook_repair_stale_plan_task_rule(),
    planbook_repair_backlog_completion_task_rule(),
    planbook_repair_result_write_task_rule(),
    planbook_repair_satisfaction_gate_task_rule(),
  ]
}

///|
fn planbook_repair_read_context_task_rule() -> String {
  "1. Read `skills/planbook-repair/SKILL.md` and the repair context."
}

///|
fn planbook_repair_ownership_decision_task_rule() -> String {
  "2. Decide whether this can be fixed inside Moontown or must be handed to MoonBook/MoonClaw."
}

///|
fn planbook_repair_exact_targets_task_rule() -> String {
  "3. Use only the exact target files first; do not run broad `find .`, broad `rg`, or whole-repo `search_files` unless those target files prove insufficient."
}

///|
fn planbook_repair_small_patch_task_rule() -> String {
  "4. If it can be fixed safely, apply the smallest code/docs change through the configured Codex ACP source-patching target."
}

///|
fn planbook_repair_selected_feature_task_rule() -> String {
  [
    "5. If the criterion is `editor-selected-feature-implementation`, treat `raw/editor-pipeline/next-feature.json` as the source of truth.",
    "Do not replace it with a fixed feature list.",
    "Implement the selected feature acceptance criteria and write `raw/editor-pipeline/selected-feature-implementation.md` with `contract: \{editor_selected_feature_implementation_contract()}`, `selected_feature: <id>`, and `implementation_status: accepted` only after validation.",
  ].join(" ")
}

///|
fn planbook_repair_validation_task_rule() -> String {
  "6. Run the required validation commands unless the result explicitly explains why a command could not run."
}

///|
fn planbook_repair_diff_hygiene_task_rule() -> String {
  "7. Inspect `git status --short`, `git diff --check`, and the focused diff before declaring success."
}

///|
fn planbook_repair_commit_task_rule() -> String {
  "8. If validation passes and files changed, prepare a local commit with a clear message according to the repair packet git policy; do not push unless policy allows it."
}

///|
fn planbook_repair_no_churn_task_rule() -> String {
  "9. If you reach the code-building step and discover the requested work is already done, do not patch for activity. Update the PlanBook progress/backlog documents and write completion evidence."
}

///|
fn planbook_repair_stale_plan_task_rule() -> String {
  "10. If the plan is stale, update the plan/backlog document first, then either stop with `no_change` or continue only if the updated plan still requires code."
}

///|
fn planbook_repair_backlog_completion_task_rule() -> String {
  "11. For backlog criteria named `backlog-*`, also write `raw/backlog/completed/<backlog-id>.md` after validation or after accepted `no_change`, where `<backlog-id>` is the criterion id without the `backlog-` prefix."
}

///|
fn planbook_repair_result_write_task_rule() -> String {
  "12. Write `\{planbook_repair_result_relative_path()}` with decision, files changed, validation, diff summary, commit status, plan update status, remaining blockers, cookbook impact, and `patch_receipt` using `\{planbook_repair_patch_receipt_contract()}` for accepted repairs."
}

///|
fn planbook_repair_satisfaction_gate_task_rule() -> String {
  "13. Do not mark the criterion satisfied unless accepted source-root ACP patch receipt evidence exists after validation; do not directly fix individual live/runtime autonomy symptoms while repairing self-patching."
}
