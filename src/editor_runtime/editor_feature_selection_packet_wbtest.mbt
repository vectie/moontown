///|
async test "editor feature selection packet asks ai to choose from course evidence" {
  let workspace = planbook_autonomy_test_workspace(
    "/tmp/moontown-editor-feature-selection-wbtest",
  )
  let snapshot_path = workspace.snapshot_path
  let workspace_root = workspace.workspace_root
  let task_id = "editor-feature-selection"
  let packet_path = editor_feature_selection_packet_path(
    workspace_root, task_id,
  )
  let selection_path = editor_feature_selection_result_path(workspace_root)
  let implementation_path = editor_selected_feature_implementation_path(
    workspace_root,
  )
  let message = write_editor_feature_selection_task(
    snapshot_path~,
    workspace_root~,
  )
  let task_text = @support.read_text_or_empty(
    default_editor_feature_selection_path(snapshot_path~),
  )
  let packet_text = @support.read_text_or_empty(packet_path)
  let skill_text = @support.read_text_or_empty(
    "\{workspace_root}/skills/editor-feature-rater/SKILL.md",
  )
  let profile_text = @support.read_text_or_empty(
    "\{workspace_root}/moonclaw.jobs.json",
  )
  assert_true(message.contains("Editor feature selection task"))
  assert_true(task_text.contains("\"status\": \"queued\""))
  assert_true(
    packet_text.contains(@editor_pipeline.feature_selection_result_contract()),
  )
  assert_true(packet_text.contains("course-wenyu-game-design"))
  assert_true(packet_text.contains("\"disable_waiting_for_input\":true"))
  assert_true(packet_text.contains("\"best_effort_on_missing_input\":true"))
  assert_true(packet_text.contains("\"best_effort_on_timeout\":false"))
  assert_true(packet_text.contains("Do not rely on a hardcoded candidate list"))
  assert_true(skill_text.contains("Editor Feature Rater Skill"))
  assert_true(skill_text.contains("Scoring Rubric"))
  assert_true(profile_text.contains("editor_feature_rater"))
  assert_true(
    @support.read_text_or_empty(
      editor_pipeline_plan_path(
        workspace_root, "2026-05-31-editor-mode-real-pipeline",
      ),
    ).contains("Editor Mode Real Pipeline"),
  )
  assert_true(
    packet_text.contains(
      "Write JSON to `\{workspace_root}/raw/editor-pipeline/next-feature.json`",
    ),
  )
  assert_true(!editor_feature_selection_ready(workspace_root~))
  @support.write_text_file(
    selection_path,
    test_editor_feature_selection_json("x", "X", 1, "small", "visible"),
  )
  assert_true(editor_feature_selection_ready(workspace_root~))
  assert_true(
    editor_selected_feature_implementation_evidence(workspace_root).contains(
      "AI selected `x`",
    ),
  )
  @support.write_text_file(
    implementation_path,
    test_editor_feature_implementation_proof("x"),
  )
  assert_true(editor_selected_feature_implementation_ready(workspace_root))
  ignore(write_editor_feature_selection_task(snapshot_path~, workspace_root~))
  let repeat_packet_text = @support.read_text_or_empty(packet_path)
  let repeat_context = @support.read_text_or_empty(
    editor_feature_selection_context_path(workspace_root),
  )
  let repeat_evidence = @support.read_text_or_empty(
    editor_feature_selection_current_evidence_path(workspace_root),
  )
  let ledger = @support.read_text_or_empty(
    editor_implemented_features_ledger_path(workspace_root),
  )
  assert_true(repeat_packet_text.contains("Already Implemented Features"))
  assert_true(repeat_packet_text.contains("exclude every feature"))
  assert_true(
    repeat_evidence.contains(
      ".moonsuite/products/moontown/editor-pipeline.json",
    ),
  )
  assert_true(!repeat_evidence.contains(".moontown/editor-pipeline.json"))
  assert_true(repeat_context.contains("## Already Implemented Features"))
  assert_true(repeat_context.contains("- `x`"))
  assert_true(ledger.contains("- `x`"))
  assert_true(
    @fs.exists(
      editor_implemented_feature_archive_path(
        workspace_root, "x", "selection.json",
      ),
    ),
  )
}
