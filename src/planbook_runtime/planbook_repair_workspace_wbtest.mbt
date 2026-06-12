///|
fn test_planbook_repair_workspace_criterion() -> PlanbookCriterionStatus {
  {
    id: "editor-selected-feature-implementation",
    plan_id: "2026-05-31-editor-mode-real-pipeline",
    title: "Implement the AI-selected editor-mode feature",
    owner: "moontown+planbook+moonclaw",
    satisfied: false,
    evidence: "selected feature exists but implementation evidence is missing",
    next_action: "implement the selected feature through PlanBook repair",
  }
}

///|
test "planbook repair context keeps ownership and selection boundaries" {
  let criterion = test_planbook_repair_workspace_criterion()
  let context = planbook_repair_context_markdown(criterion)
  assert_true(context.contains("# PlanBook Repair Context"))
  assert_true(
    context.contains("- Criterion: `editor-selected-feature-implementation`"),
  )
  assert_true(context.contains("## Target Files"))
  assert_true(context.contains("raw/editor-pipeline/next-feature.json"))
  assert_true(context.contains("selected-feature-implementation.md"))
  assert_true(context.contains("## Boundary Rule"))
  assert_true(context.contains("Moontown may repair routing"))
  assert_true(context.contains("MoonBook owns native book profiles"))
  assert_true(context.contains("MoonClaw owns execution runtime behavior"))
  assert_true(context.contains("Do not copy another project into Moontown"))
  assert_true(context.contains("## AI-Selected Editor Feature"))
  assert_true(context.contains("must not silently choose a different feature"))
}

///|
test "planbook repair plan requires validation and ownership evidence" {
  let criterion = test_planbook_repair_workspace_criterion()
  let plan = planbook_repair_plan_markdown(criterion)
  assert_true(plan.contains("# Plan: Self-Heal"))
  assert_true(
    plan.contains("selected feature exists but implementation evidence"),
  )
  assert_true(
    plan.contains("implement the selected feature through PlanBook repair"),
  )
  assert_true(plan.contains("## Acceptance Criteria"))
  assert_true(plan.contains(planbook_repair_result_relative_path()))
  assert_true(plan.contains("Required validation commands"))
  assert_true(plan.contains("git diff --check"))
  assert_true(plan.contains(".moontown/planbook/autonomy.json"))
  assert_true(plan.contains("does not fake completion"))
}

///|
test "planbook repair skill exposes strict engineering result contract" {
  let skill = @planbook_policy.repair_skill_markdown()
  assert_true(skill.contains("name: planbook-repair"))
  assert_true(skill.contains("## Required Decision"))
  assert_true(skill.contains("repair_decision"))
  assert_true(skill.contains("files_changed"))
  assert_true(skill.contains("validation"))
  assert_true(skill.contains("commit_status"))
  assert_true(skill.contains("push_status"))
  assert_true(skill.contains("## Rules"))
  assert_true(
    skill.contains("Never claim success because a markdown plan exists"),
  )
  assert_true(skill.contains("Rerun the PlanBook doctor"))
  assert_true(
    skill.contains("Use exact `target_files` before any broad search"),
  )
  assert_true(skill.contains("configured Codex ACP target"))
  assert_true(skill.contains("## Concrete Example"))
  assert_true(skill.contains("repair_decision: accepted"))
}
