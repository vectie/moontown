///|
async fn write_planbook_repair_workspace(
  criterion : PlanbookCriterionStatus,
  workspace_root : String,
) -> Unit {
  write_text_file(
    planbook_repair_context_path(workspace_root),
    planbook_repair_context_markdown(criterion),
  )
  write_text_file(
    planbook_repair_skill_path(workspace_root),
    @planbook_policy.repair_skill_markdown(),
  )
  write_text_file(
    planbook_repair_plan_path(workspace_root),
    planbook_repair_plan_markdown(criterion),
  )
  write_planbook_repair_moonclaw_profile(workspace_root)
  write_planbook_repair_acp_target(workspace_root)
}
