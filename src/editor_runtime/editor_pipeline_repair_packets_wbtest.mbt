///|
async test "editor pipeline exposes bounded course context for repair" {
  let workspace = planbook_autonomy_test_workspace(
    "/tmp/moontown-editor-pipeline-repair-packet-wbtest",
  )
  let workspace_root = workspace.workspace_root
  write_editor_feature_selection_workspace(workspace_root)
  let targets = editor_feature_selection_target_files().join("\n")
  assert_true(targets.contains("course-wenyu-game-design"))
  assert_true(targets.contains("2026-05-31-editor-mode-real-pipeline"))
  assert_true(targets.contains("beginner-course.md"))
  assert_true(targets.contains("exercises.md"))
  assert_true(targets.contains("progress-rubric.md"))
}

///|
async test "selected editor feature evidence is repair-ready" {
  let workspace = planbook_autonomy_test_workspace(
    "/tmp/moontown-selected-editor-feature-repair-wbtest",
  )
  let workspace_root = workspace.workspace_root
  @support.write_text_file(
    editor_feature_selection_result_path(workspace_root),
    test_editor_feature_selection_json_with_gap(
      "building-protocol-history", "Building Protocol History", "history missing",
      "render protocol history", "visible history",
    ),
  )
  let evidence = editor_selected_feature_implementation_evidence(workspace_root)
  let next_action = editor_selected_feature_implementation_next_action(
    workspace_root,
  )
  assert_true(evidence.contains("building-protocol-history"))
  assert_true(evidence.contains("history missing"))
  assert_true(next_action.contains("planbook repair --dispatch"))
  assert_true(next_action.contains("raw/editor-pipeline/next-feature.json"))
  assert_true(
    next_action.contains(
      "raw/editor-pipeline/selected-feature-implementation.md",
    ),
  )
}
