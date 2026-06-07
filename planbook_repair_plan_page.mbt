///|
fn planbook_repair_plan_markdown(criterion : PlanbookCriterionStatus) -> String {
  [
    planbook_repair_plan_header(criterion),
    planbook_repair_plan_problem_section(criterion),
    planbook_repair_plan_goal_section(criterion),
    planbook_repair_plan_acceptance_criteria(),
  ].join("\n")
}

///|
fn planbook_repair_plan_header(criterion : PlanbookCriterionStatus) -> String {
  "# Plan: Self-Heal `\{criterion.id}`"
}

///|
fn planbook_repair_plan_problem_section(
  criterion : PlanbookCriterionStatus,
) -> String {
  ["## Problem", "", criterion.evidence].join("\n")
}

///|
fn planbook_repair_plan_goal_section(
  criterion : PlanbookCriterionStatus,
) -> String {
  ["## Goal", "", criterion.next_action].join("\n")
}

///|
fn planbook_repair_plan_acceptance_criteria() -> String {
  [
    "## Acceptance Criteria",
    "",
    "- [ ] Repair worker writes `\{planbook_repair_result_relative_path()}`.",
    "- [ ] Required validation commands are run or explicitly blocked.",
    "- [ ] `git diff --check`, `git status --short`, and focused diff hygiene are recorded.",
    "- [ ] Local commit readiness is recorded; if files changed and validation passed, the worker prepares a commit according to policy.",
    "- [ ] PlanBook autonomy doctor reruns and updates `.moontown/planbook/autonomy.json`.",
    "- [ ] If ownership is outside Moontown, the result names the correct repository and does not fake completion.",
  ].join("\n")
}
