///|
async fn write_planbook_autonomy_workspace(
  status : PlanbookAutonomyStatus,
  workspace_root : String,
) -> Unit {
  ignore(ensure_planbook_backlog(workspace_root))
  @support.write_text_file(
    "\{workspace_root}/wiki/planning/execution-evidence.md",
    planbook_autonomy_execution_evidence(status),
  )
  @support.write_text_file(
    "\{workspace_root}/wiki/reviews/active-plan-review.md",
    planbook_autonomy_active_review(status),
  )
  @support.write_text_file(
    "\{workspace_root}/wiki/planning/self-healing.md",
    render_planbook_autonomy_markdown(status),
  )
  @support.write_text_file(
    "\{workspace_root}/wiki/history/daily-engineering-digest.md",
    planbook_daily_engineering_digest_markdown(status, workspace_root),
  )
  @support.write_text_file(
    "\{workspace_root}/book/moonbook-ui-state.json",
    planbook_autonomy_ui_state_json(status),
  )
  append_planbook_change_log(
    workspace_root,
    "autonomy doctor",
    "Status `\{status.status}` with \{status.open_count} open gap(s) and \{status.satisfied_count} satisfied criterion/criteria.",
  )
}
