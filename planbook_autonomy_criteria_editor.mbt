///|
async fn planbook_editor_pipeline_criterion(
  workspace_root : String,
) -> PlanbookCriterionStatus {
  let plan_ready = @fs.exists(
    "\{workspace_root}/plans/2026-05-31-editor-mode-real-pipeline/plan.md",
  )
  let command_ready = @fs.exists("editor_pipeline.mbt") &&
    text_file_contains("cmd/main/main.mbt", "editor-pipeline")
  let ui_ready = text_file_contains(
      "ui/rabbita-town/main/main.mbt", "editor_pipeline",
    ) ||
    text_file_contains("ui/rabbita-town/main/main.mbt", "Editor Pipeline")
  let ready = plan_ready && command_ready && ui_ready
  planbook_criterion(
    "editor-mode-real-pipeline",
    "2026-05-31-editor-mode-real-pipeline",
    "Editor mode creates a real PlanBook-to-MoonClaw implementation pipeline",
    "moontown+planbook+moonclaw",
    ready,
    if ready {
      "PlanBook plan exists, Moontown exposes an editor-pipeline command/state contract, and editor mode references the pipeline"
    } else if plan_ready {
      "PlanBook has the editor pipeline plan, but Moontown still lacks the command/state/UI integration"
    } else {
      "PlanBook is missing the editor pipeline plan and Moontown still lacks the command/state/UI integration"
    },
    "use the Wenyu course book as source context, then implement a restartable editor-pipeline contract, command surface, UI binding, and validation evidence through PlanBook repair",
  )
}

///|
async fn planbook_editor_feature_selection_criterion(
  workspace_root : String,
) -> PlanbookCriterionStatus {
  let ready = editor_feature_selection_ready(workspace_root~)
  planbook_criterion(
    "editor-feature-ai-selection",
    "2026-05-31-editor-mode-real-pipeline",
    "AI selects the next missing editor-mode feature from the course book",
    "moontown+planbook+moonclaw",
    ready,
    editor_feature_selection_evidence(workspace_root~),
    "run `moon run cmd/main -- editor-pipeline feature-select --dispatch`, then verify `raw/editor-pipeline/next-feature.json` satisfies `\{editor_feature_selection_result_contract()}`",
  )
}

///|
async fn planbook_editor_selected_feature_implementation_criterion(
  workspace_root : String,
) -> PlanbookCriterionStatus {
  let ready = editor_selected_feature_implementation_ready(workspace_root)
  planbook_criterion(
    "editor-selected-feature-implementation",
    "2026-05-31-editor-mode-real-pipeline",
    "Implement the AI-selected editor-mode feature",
    "moontown+planbook+moonclaw",
    ready,
    editor_selected_feature_implementation_evidence(workspace_root),
    editor_selected_feature_implementation_next_action(workspace_root),
  )
}
