///|
fn planbook_seed_plan_markdown() -> String {
  [
    "# Plan: Raise MoonBook Quality Governance",
    planbook_quality_problem_section(),
    planbook_quality_goal_section(),
    planbook_quality_non_goals_section(),
    planbook_quality_acceptance_section(),
  ].join("\n")
}

///|
fn planbook_plans_index_markdown() -> String {
  [
    "# Plans Index",
    "",
    "| Plan | Status | Owner | Stable-State Impact |",
    "| --- | --- | --- | --- |",
    planbook_plan_index_row(
      "2026-05-29-live-autonomy-spine/plan.md", "top-priority", "Moontown Mayor + MoonBook + MoonClaw",
      "connects daemon, workers, accepted outputs, journal, projection, and operator UI",
    ),
    planbook_plan_index_row(
      "2026-05-31-editor-mode-real-pipeline/plan.md", "self-build-test", "Moontown PlanBook + MoonClaw",
      "turns Wenyu editor-mode guidance into a real plan-to-code pipeline",
    ),
    planbook_plan_index_row(
      "2026-05-29-book-quality-upgrade/plan.md", "active-review", "Moontown + MoonBook",
      "separates structural readiness from semantic quality and formalizes planbook/cookbook/course/civic workspaces",
    ),
    "",
    "Planbook rule: update the existing plan and evidence pages instead of creating noisy `v1`, `v2`, `v3` copies.",
  ].join("\n")
}

///|
fn planbook_editor_pipeline_plan_markdown() -> String {
  [
    "# Plan: Editor Mode Real Pipeline",
    "",
    editor_pipeline_plan_source_section(),
    editor_pipeline_plan_problem_section(),
    editor_pipeline_plan_goal_section(),
    editor_pipeline_plan_ownership_section(),
    editor_pipeline_plan_implementation_section(),
    editor_pipeline_plan_acceptance_section(),
  ].join("\n")
}

///|
fn planbook_live_autonomy_plan_markdown() -> String {
  [
    "# Plan: Live Autonomy Spine",
    live_autonomy_priority_section(),
    live_autonomy_problem_section(),
    live_autonomy_goal_section(),
    live_autonomy_ownership_section(),
    live_autonomy_acceptance_section(),
    live_autonomy_validation_section(),
  ].join("\n")
}
