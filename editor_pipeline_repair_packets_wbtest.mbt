///|
async test "editor pipeline repair packet keeps course source context bounded" {
  let workspace = planbook_autonomy_test_workspace(
    "/tmp/moontown-editor-pipeline-repair-packet-wbtest",
  )
  let workspace_root = workspace.workspace_root
  let criterion : PlanbookCriterionStatus = {
    id: "editor-mode-real-pipeline",
    plan_id: "2026-05-31-editor-mode-real-pipeline",
    title: "Editor mode creates a real PlanBook-to-MoonClaw implementation pipeline",
    owner: "moontown+planbook+moonclaw",
    satisfied: false,
    evidence: "PlanBook has the editor pipeline plan, but Moontown still lacks the command/state/UI integration",
    next_action: "use the Wenyu course book as source context, then implement a restartable editor-pipeline contract, command surface, UI binding, and validation evidence through PlanBook repair",
  }
  ignore(
    materialize_planbook_repair_task(
      criterion,
      workspace.snapshot_path,
      workspace_root,
      workspace.catalog_path,
      false,
      false,
    ),
  )
  let packet_text = read_text_or_empty(
    planbook_repair_packet_path_for_criterion(
      workspace_root, "editor-mode-real-pipeline",
    ),
  )
  assert_true(packet_text.contains(planbook_repair_result_contract()))
  assert_true(packet_text.contains("\"target_files\""))
  assert_true(packet_text.contains("\"best_effort_on_timeout\":false"))
  assert_true(packet_text.contains("course-wenyu-game-design"))
  assert_true(packet_text.contains("2026-05-31-editor-mode-real-pipeline"))
}

///|
async test "selected editor feature repair packet is driven by ai selection artifact" {
  let workspace = planbook_autonomy_test_workspace(
    "/tmp/moontown-selected-editor-feature-repair-wbtest",
  )
  let workspace_root = workspace.workspace_root
  write_text_file(
    editor_feature_selection_result_path(workspace_root),
    test_editor_feature_selection_json_with_gap(
      "building-protocol-history", "Building Protocol History", "history missing",
      "render protocol history", "visible history",
    ),
  )
  let criterion : PlanbookCriterionStatus = {
    id: "editor-selected-feature-implementation",
    plan_id: "2026-05-31-editor-mode-real-pipeline",
    title: "Implement the AI-selected editor-mode feature",
    owner: "moontown+planbook+moonclaw",
    satisfied: false,
    evidence: editor_selected_feature_implementation_evidence(workspace_root),
    next_action: editor_selected_feature_implementation_next_action(
      workspace_root,
    ),
  }
  ignore(
    materialize_planbook_repair_task(
      criterion,
      workspace.snapshot_path,
      workspace_root,
      workspace.catalog_path,
      false,
      false,
    ),
  )
  let packet_text = read_text_or_empty(
    planbook_repair_packet_path_for_criterion(
      workspace_root, "editor-selected-feature-implementation",
    ),
  )
  let skill_text = read_text_or_empty(
    planbook_repair_path_in_workspace(
      workspace_root,
      planbook_repair_skill_relative_path(),
    ),
  )
  assert_true(packet_text.contains("editor-selected-feature-implementation"))
  assert_true(packet_text.contains("building-protocol-history"))
  assert_true(packet_text.contains("next-feature.json"))
  assert_true(packet_text.contains("selected-feature-implementation.md"))
  assert_true(skill_text.contains("do not choose a different feature"))
}
