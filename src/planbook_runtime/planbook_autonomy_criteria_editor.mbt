///|
async fn planbook_editor_pipeline_criterion(
  workspace_root : String,
) -> PlanbookCriterionStatus {
  let plan_ready = @fs.exists(
    "\{workspace_root}/plans/2026-05-31-editor-mode-real-pipeline/plan.md",
  )
  let command_ready = @fs.exists("src/editor_runtime/editor_pipeline.mbt") &&
    text_file_contains("src/cmd/main/main.mbt", "editor-pipeline") &&
    text_file_contains(
      "src/cmd/main/planning_commands.mbt", "render_editor_pipeline_command",
    )
  let state_ready = text_file_contains(
      "src/editor_runtime/editor_pipeline.mbt", "moontown.editor_pipeline.v1",
    ) &&
    text_file_contains(
      "src/editor_runtime/editor_pipeline_lifecycle.mbt", "selected-feature-implementation",
    )
  let ui_ready = text_file_contains(
      "src/ui/rabbita-town/main/bootstrap_moondesk.mbt", "parse_bootstrap_editor_pipeline",
    ) &&
    text_file_contains(
      "src/ui/rabbita-town/main/app_tick_optional_refresh.mbt", "refresh_editor_pipeline",
    ) &&
    text_file_contains(
      "src/ui/rabbita-town/main/viewport_mode_editor.mbt", "render_editor_pipeline_panel",
    ) &&
    text_file_contains(
      "src/ui/rabbita-town/main/viewport_output.mbt", "render_editor_pipeline_lifecycle",
    )
  let ready = plan_ready && command_ready && state_ready && ui_ready
  planbook_criterion(
    "editor-mode-real-pipeline",
    "2026-05-31-editor-mode-real-pipeline",
    "Editor mode creates a real PlanBook-to-MoonClaw implementation pipeline",
    "moontown+planbook+moonclaw",
    ready,
    if ready {
      "PlanBook plan exists, MoonTown exposes an editor-pipeline command/state contract, and editor mode references the pipeline"
    } else if plan_ready {
      "PlanBook has the editor pipeline plan, but MoonTown still lacks the command/state/UI integration"
    } else {
      "PlanBook is missing the editor pipeline plan and MoonTown still lacks the command/state/UI integration"
    },
    "use the Wenyu course book as source context, then implement a restartable editor-pipeline contract, command surface, UI binding, and validation evidence through PlanBook repair",
  )
}

///|
async fn planbook_editor_feature_selection_criterion(
  workspace_root : String,
) -> PlanbookCriterionStatus {
  let ready = @editor_runtime.editor_feature_selection_ready(workspace_root~)
  planbook_criterion(
    "editor-feature-ai-selection",
    "2026-05-31-editor-mode-real-pipeline",
    "AI selects the next missing editor-mode feature from the course book",
    "moontown+planbook+moonclaw",
    ready,
    @editor_runtime.editor_feature_selection_evidence(workspace_root~),
    "run `moon run src/cmd/main -- editor-pipeline feature-select --dispatch`, then verify `raw/editor-pipeline/next-feature.json` satisfies `\{@editor_pipeline.feature_selection_result_contract()}`",
  )
}

///|
async fn planbook_editor_selected_feature_implementation_criterion(
  workspace_root : String,
) -> PlanbookCriterionStatus {
  let ready = @editor_runtime.editor_selected_feature_implementation_ready(
    workspace_root,
  )
  planbook_criterion(
    "editor-selected-feature-implementation",
    "2026-05-31-editor-mode-real-pipeline",
    "Implement the AI-selected editor-mode feature",
    "moontown+planbook+moonclaw",
    ready,
    @editor_runtime.editor_selected_feature_implementation_evidence(
      workspace_root,
    ),
    @editor_runtime.editor_selected_feature_implementation_next_action(
      workspace_root,
    ),
  )
}
