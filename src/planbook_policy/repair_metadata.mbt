///|
pub fn repair_required_engineering_steps() -> Array[String] {
  [
    "inspect-plan", "apply-small-patch", "run-validation", "inspect-git-diff", "write-repair-result",
    "write-patch-receipt", "commit-repair-owned-files-only",
  ]
}

///|
pub fn repair_patch_receipt_required_fields() -> Array[String] {
  [
    "contract", "criterion_id", "source_root", "execution_mode", "execution_target",
    "run_id", "acp_run_id", "base_head", "final_head", "changed_files", "validation_commands",
    "diff_check_status", "commit_status", "commit_sha", "commit_message", "push_status",
    "result_decision",
  ]
}

///|
pub fn repair_git_policy_json() -> Json {
  {
    "inspect_status": true,
    "inspect_diff": true,
    "commit_after_validation": true,
    "commit_only_repair_owned_files": true,
    "preserve_preexisting_unrelated_dirty_files": true,
    "push_after_commit": false,
    "commit_message_required": true,
  }
}
