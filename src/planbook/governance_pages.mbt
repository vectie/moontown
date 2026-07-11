///|
pub fn quality_gates_markdown() -> String {
  [
    "# Planbook Quality Gates", "", "| Gate | Required Evidence |", "| --- | --- |",
    "| Intent | problem, goal, non-goals, owner boundary |", "| Design | selected approach plus alternatives |",
    "| Execution | changed files or explicit blocker |", "| Validation | commands and results |",
    "| Review | accepted criteria, unresolved risks, cookbook impact |",
  ].join("\n")
}

///|
pub fn execution_evidence_markdown() -> String {
  [
    "# Execution Evidence", "", "This page records what changed for active plans. It is intentionally separate from the plan text so execution can continue without rewriting the intent.",
    "", "## Current Evidence", "", "- Planbook workspace exists as a registered MoonBook.",
    "- Course, cookbook, civic, operational, and planbook workspaces have separate structural expectations.",
    "- Book-quality audit now separates structural readiness from semantic AI review.",
    "", "## Required Future Evidence", "", "- Commands run and results.", "- Files changed.",
    "- Review findings.", "- Cookbook impact.", "- Remaining risks.",
  ].join("\n")
}

///|
pub fn active_review_markdown() -> String {
  [
    "# Active Plan Review", "", "## Review State", "", "- Status: active-review",
    "- Reviewer: keeper/operator or MoonClaw reviewer", "- Decision: pending semantic review",
    "", "## Findings To Check", "", "- Does the course book avoid research-report language?",
    "- Do civic books contain real service ledgers and review history, not just contracts?",
    "- Does the cookbook explain stable-state boundaries clearly enough for MoonDesk and MoonTown?",
    "- Does the planbook provide execution evidence and review state, not just templates?",
  ].join("\n")
}

///|
pub fn decision_log_markdown() -> String {
  [
    "# Decision Log", "", "| Date | Decision | Reason |", "| --- | --- | --- |",
    "| 2026-05-29 | Separate structural readiness from semantic quality | File completeness cannot judge usefulness, originality, correctness, or genre fit. |",
    "| 2026-05-29 | Treat planbook as a first-class MoonBook workspace | Complex code/product changes need durable plan, evidence, review, and cookbook handoff state. |",
  ].join("\n")
}

///|
pub fn record_schema_markdown() -> String {
  [
    "# Plan Record Schema", "", "- `id`: stable plan id", "- `status`: proposed, active, blocked, active-review, accepted, superseded",
    "- `problem`: why the plan exists", "- `owner_boundary`: MoonTown, MoonBook, MoonClaw, MoonDesk responsibility split",
    "- `affected_files`: expected implementation/doc files", "- `acceptance_criteria`: checklist",
    "- `execution_evidence`: changed files, commands, result links", "- `review_decision`: accepted, needs-fix, blocked",
    "- `cookbook_impact`: none, update-needed, updated",
  ].join("\n")
}

///|
pub fn open_questions_markdown() -> String {
  [
    "# Open Planning Questions", "", "- Which book has the weakest current quality score?",
    "- Is the weakness a MoonBook skill/profile issue, a MoonTown routing issue, or a MoonClaw execution issue?",
    "- Does fixing the weakness change the stable cookbook contract?",
  ].join("\n")
}
