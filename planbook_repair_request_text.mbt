///|
fn planbook_repair_request_text(criterion : PlanbookCriterionStatus) -> String {
  [
    planbook_repair_request_header(criterion),
    planbook_repair_request_task_section(),
    planbook_repair_request_target_files_section(criterion),
  ].join("\n")
}

///|
fn planbook_repair_request_header(
  criterion : PlanbookCriterionStatus,
) -> String {
  [
    "You are the PlanBook repair worker for Moontown.",
    "Open criterion: `\{criterion.id}`.",
    "Title: \{criterion.title}",
    "Owner boundary: \{criterion.owner}.",
    "Evidence: \{criterion.evidence}",
    "Required next action: \{criterion.next_action}",
  ].join("\n")
}

///|
fn planbook_repair_request_task_section() -> String {
  ["Task:", @planbook_policy.repair_request_task_rules().join("\n")].join("\n")
}

///|
fn planbook_repair_request_target_files_section(
  criterion : PlanbookCriterionStatus,
) -> String {
  ["Target files:", planbook_repair_target_files_markdown(criterion.id)].join(
    "\n",
  )
}
