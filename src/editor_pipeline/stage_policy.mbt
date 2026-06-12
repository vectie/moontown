///|
pub(all) struct EditorPipelineStageInputs {
  course_page : String
  plan_path : String
  feature_selection_result_path : String
  repair_task_path : String
  module_config_ref : String
  placement_proposal_path : String
  course_ready : Bool
  plan_ready : Bool
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
pub fn pipeline_stages(
  inputs : EditorPipelineStageInputs,
) -> Array[EditorPipelineStage] {
  [
    pipeline_stage(
      "course-source",
      "Course Source",
      required_stage_status(inputs.course_ready),
      "Wenyu game-design course teaches map labeling, mode separation, and module editing boundaries.",
      inputs.course_page,
    ),
    pipeline_stage(
      "planbook-plan",
      "PlanBook Plan",
      required_stage_status(inputs.plan_ready),
      "Durable plan stores acceptance criteria and self-build evidence.",
      inputs.plan_path,
    ),
    pipeline_stage(
      "feature-selection",
      "AI Feature Selection",
      inputs.feature_selection_status,
      inputs.feature_selection_summary,
      inputs.feature_selection_result_path,
    ),
    pipeline_stage(
      "command-contract",
      "Command Contract",
      required_stage_status(inputs.command_ready),
      "`moon run src/cmd/main -- editor-pipeline refresh|status` publishes runtime state.",
      "src/cmd/main/main.mbt",
    ),
    pipeline_stage(
      "repair-loop",
      "Repair Loop",
      inputs.repair_status,
      "PlanBook repair packets dispatch bounded MoonClaw work and reconcile valid repair-result contracts only.",
      inputs.repair_task_path,
    ),
    pipeline_stage(
      "viewport-binding",
      "Viewport Binding",
      required_stage_status(inputs.ui_ready),
      "Editor mode reads `editor-pipeline.json` and shows plan/source/repair/output readiness.",
      "src/ui/rabbita-town/main/main.mbt",
    ),
    pipeline_stage(
      "building-protocol-history",
      "Building Protocol History",
      required_stage_status(inputs.feature_history_ready),
      "At least one module interior shows durable inbox/reduction/review/accepted-result/outbox history with building-specific evidence refs.",
      "src/ui/rabbita-town/main/main.mbt + .moontown/civic/protocols/<building-id>/*.jsonl",
    ),
    pipeline_stage(
      "movement-loop-evidence",
      "Movement Loop Evidence",
      selected_feature_stage_status(
        inputs.movement_loop_ready,
        inputs.lifecycle,
        "movement-loop-evidence",
      ),
      "Editor pipeline publishes module-level home -> building entrance -> output surface -> home route proof from the Wenyu module config.",
      inputs.module_config_ref,
    ),
    pipeline_stage(
      "placement-diff-preview",
      "Placement Diff Preview",
      selected_feature_stage_status(
        inputs.placement_diff_ready,
        inputs.lifecycle,
        "placement-diff-preview",
      ),
      "Editor pipeline compares current and proposed module placements before output mode treats map edits as exportable.",
      inputs.placement_proposal_path,
    ),
    pipeline_stage(
      "terrain-label-map",
      "Terrain Label Map Layers",
      selected_feature_stage_status(
        inputs.terrain_label_ready,
        inputs.lifecycle,
        "terrain-label-map",
      ),
      "Editor pipeline publishes terrain layers and module placement reasons from current Wenyu map/module data.",
      "ui/assets/tilemap/reference-map.json + \{inputs.module_config_ref}",
    ),
    pipeline_stage(
      "style-comparison-workbench",
      "Building Style Comparison Workbench",
      selected_feature_stage_status(
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
pub fn pipeline_status(inputs : EditorPipelineStageInputs) -> String {
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
pub fn required_stage_status(ready : Bool) -> String {
  if ready {
    "ready"
  } else {
    "missing"
  }
}

///|
pub fn selected_feature_stage_status(
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
fn pipeline_stage(
  id : String,
  title : String,
  status : String,
  summary : String,
  evidence : String,
) -> EditorPipelineStage {
  { id, title, status, summary, evidence }
}
