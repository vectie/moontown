///|
priv struct EditorPipelineStageInputs {
  snapshot_path : String
  workspace_root : String
  course_page : String
  plan_path : String
  plan_ready : Bool
  course_ready : Bool
  command_ready : Bool
  ui_ready : Bool
  repair_status : String
  feature_selection_status : String
  feature_selection_summary : String
  lifecycle : EditorPipelineLifecycleRecord
  feature_history_ready : Bool
  movement_loop_ready : Bool
  placement_diff_ready : Bool
  terrain_label_ready : Bool
  style_comparison_ready : Bool
}

///|
fn editor_pipeline_stages(
  inputs : EditorPipelineStageInputs,
) -> Array[EditorPipelineStage] {
  [
    editor_pipeline_stage(
      "course-source",
      "Course Source",
      editor_pipeline_required_stage_status(inputs.course_ready),
      "Wenyu game-design course teaches map labeling, mode separation, and module editing boundaries.",
      inputs.course_page,
    ),
    editor_pipeline_stage(
      "planbook-plan",
      "PlanBook Plan",
      editor_pipeline_required_stage_status(inputs.plan_ready),
      "Durable plan stores acceptance criteria and self-build evidence.",
      inputs.plan_path,
    ),
    editor_pipeline_stage(
      "feature-selection",
      "AI Feature Selection",
      inputs.feature_selection_status,
      inputs.feature_selection_summary,
      editor_feature_selection_result_path(inputs.workspace_root),
    ),
    editor_pipeline_stage(
      "command-contract",
      "Command Contract",
      editor_pipeline_required_stage_status(inputs.command_ready),
      "`moon run cmd/main -- editor-pipeline refresh|status` publishes runtime state.",
      "cmd/main/main.mbt",
    ),
    editor_pipeline_stage(
      "repair-loop",
      "Repair Loop",
      inputs.repair_status,
      "PlanBook repair packets dispatch bounded MoonClaw work and reconcile valid repair-result contracts only.",
      default_planbook_repair_path(snapshot_path=inputs.snapshot_path),
    ),
    editor_pipeline_stage(
      "viewport-binding",
      "Viewport Binding",
      editor_pipeline_required_stage_status(inputs.ui_ready),
      "Editor mode reads `editor-pipeline.json` and shows plan/source/repair/output readiness.",
      "ui/rabbita-town/main/main.mbt",
    ),
    editor_pipeline_stage(
      "building-protocol-history",
      "Building Protocol History",
      editor_pipeline_required_stage_status(inputs.feature_history_ready),
      "At least one module interior shows durable inbox/reduction/review/accepted-result/outbox history with building-specific evidence refs.",
      "ui/rabbita-town/main/main.mbt + .moontown/civic/protocols/<building-id>/*.jsonl",
    ),
    editor_pipeline_stage(
      "movement-loop-evidence",
      "Movement Loop Evidence",
      editor_pipeline_selected_feature_stage_status(
        inputs.movement_loop_ready,
        inputs.lifecycle,
        "movement-loop-evidence",
      ),
      "Editor pipeline publishes module-level home -> building entrance -> output surface -> home route proof from the Wenyu module config.",
      default_editor_pipeline_module_config_ref(),
    ),
    editor_pipeline_stage(
      "placement-diff-preview",
      "Placement Diff Preview",
      editor_pipeline_selected_feature_stage_status(
        inputs.placement_diff_ready,
        inputs.lifecycle,
        "placement-diff-preview",
      ),
      "Editor pipeline compares current and proposed module placements before output mode treats map edits as exportable.",
      default_editor_placement_proposal_path(
        workspace_root=inputs.workspace_root,
      ),
    ),
    editor_pipeline_stage(
      "terrain-label-map",
      "Terrain Label Map Layers",
      editor_pipeline_selected_feature_stage_status(
        inputs.terrain_label_ready,
        inputs.lifecycle,
        "terrain-label-map",
      ),
      "Editor pipeline publishes terrain layers and module placement reasons from current Wenyu map/module data.",
      "ui/assets/tilemap/reference-map.json + \{default_editor_pipeline_module_config_ref()}",
    ),
    editor_pipeline_stage(
      "style-comparison-workbench",
      "Building Style Comparison Workbench",
      editor_pipeline_selected_feature_stage_status(
        inputs.style_comparison_ready,
        inputs.lifecycle,
        "style-comparison-workbench",
      ),
      "Editor pipeline compares available building visual systems, records the selected style, and links the choice to durable style-sheet evidence.",
      "docs/WENYU_BUILDING_STYLE_SHEET.md + ui/assets/tilemap/buildings",
    ),
  ]
}

///|
fn editor_pipeline_status(inputs : EditorPipelineStageInputs) -> String {
  if inputs.plan_ready &&
    inputs.course_ready &&
    inputs.command_ready &&
    inputs.ui_ready &&
    inputs.feature_history_ready &&
    inputs.movement_loop_ready &&
    inputs.placement_diff_ready &&
    inputs.terrain_label_ready &&
    inputs.style_comparison_ready &&
    inputs.lifecycle.lifecycle_status == "ready-to-export" {
    "ready"
  } else {
    "needs-repair"
  }
}

///|
fn editor_pipeline_required_stage_status(ready : Bool) -> String {
  if ready {
    "ready"
  } else {
    "missing"
  }
}

///|
fn editor_pipeline_selected_feature_stage_status(
  ready : Bool,
  lifecycle : EditorPipelineLifecycleRecord,
  feature_id : String,
) -> String {
  if ready {
    "ready"
  } else if lifecycle.selected_feature == feature_id {
    "missing"
  } else {
    "idle"
  }
}

///|
fn editor_pipeline_stage(
  id : String,
  title : String,
  status : String,
  summary : String,
  evidence : String,
) -> EditorPipelineStage {
  { id, title, status, summary, evidence }
}
