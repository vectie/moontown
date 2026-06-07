///|
test "planbook repair request rules keep selected feature source of truth" {
  let selected_rule = planbook_repair_selected_feature_task_rule()
  assert_true(selected_rule.contains("editor-selected-feature-implementation"))
  assert_true(selected_rule.contains("raw/editor-pipeline/next-feature.json"))
  assert_true(
    selected_rule.contains("Do not replace it with a fixed feature list"),
  )
  assert_true(
    selected_rule.contains(
      "raw/editor-pipeline/selected-feature-implementation.md",
    ),
  )
  assert_true(
    selected_rule.contains(editor_selected_feature_implementation_contract()),
  )
  assert_true(selected_rule.contains("implementation_status: accepted"))
  assert_true(selected_rule.contains("only after validation"))
}

///|
test "planbook repair request rules keep full engineering loop explicit" {
  assert_eq(planbook_repair_request_task_rules().length(), 13)
  assert_true(
    planbook_repair_request_task_rules()[0].contains(
      "Read `skills/planbook-repair/SKILL.md`",
    ),
  )
  assert_true(
    planbook_repair_request_task_rules()[12].contains(
      "evidence exists after validation",
    ),
  )
  assert_true(
    planbook_repair_validation_task_rule().contains(
      "required validation commands",
    ),
  )
  assert_true(
    planbook_repair_diff_hygiene_task_rule().contains("git status --short"),
  )
  assert_true(
    planbook_repair_diff_hygiene_task_rule().contains("git diff --check"),
  )
  assert_true(
    planbook_repair_commit_task_rule().contains("prepare a local commit"),
  )
  assert_true(
    planbook_repair_no_churn_task_rule().contains("do not patch for activity"),
  )
  assert_true(planbook_repair_stale_plan_task_rule().contains("plan is stale"))
  assert_true(
    planbook_repair_result_write_task_rule().contains("commit status"),
  )
  assert_true(
    planbook_repair_satisfaction_gate_task_rule().contains(
      "evidence exists after validation",
    ),
  )
}

///|
test "planbook repair request text preserves the full bounded worker contract" {
  let criterion : PlanbookCriterionStatus = {
    id: "editor-selected-feature-implementation",
    plan_id: "test-plan",
    title: "Selected editor feature repair",
    owner: "moontown+planbook+moonclaw",
    satisfied: false,
    evidence: "selected feature exists but proof is missing",
    next_action: "apply the selected feature through PlanBook repair",
  }
  let request = planbook_repair_request_text(criterion)
  assert_true(
    request.contains("Open criterion: `editor-selected-feature-implementation`"),
  )
  assert_true(request.contains("Owner boundary: moontown+planbook+moonclaw."))
  assert_true(request.contains("Task:"))
  assert_true(request.contains("1. Read `skills/planbook-repair/SKILL.md`"))
  assert_true(request.contains("4. If it can be fixed safely"))
  assert_true(
    request.contains(
      "5. If the criterion is `editor-selected-feature-implementation`",
    ),
  )
  assert_true(request.contains("13. Do not mark the criterion satisfied"))
  assert_true(request.contains("Target files:"))
  assert_true(request.contains("editor_feature_selection.mbt"))
  assert_true(request.contains("raw/editor-pipeline/next-feature.json"))
}
