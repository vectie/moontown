///|
pub async fn write_editor_pipeline_state(
  snapshot_path? : String = @storage.default_snapshot_path(),
  workspace_root? : String = default_planbook_workspace_root(),
) -> String {
  let state = inspect_editor_pipeline_state(snapshot_path, workspace_root)
  @support.write_text_file(
    default_editor_pipeline_path(snapshot_path~),
    state.to_json().stringify(indent=2),
  )
  @support.write_text_file(
    default_editor_pipeline_markdown_path(snapshot_path~),
    render_editor_pipeline_markdown(state),
  )
  default_editor_pipeline_path(snapshot_path~)
}

///|
pub async fn render_editor_pipeline_status(
  snapshot_path? : String = @storage.default_snapshot_path(),
  workspace_root? : String = default_planbook_workspace_root(),
) -> String {
  ignore(write_editor_pipeline_state(snapshot_path~, workspace_root~))
  render_editor_pipeline_markdown(
    inspect_editor_pipeline_state(snapshot_path, workspace_root),
  )
}

///|
async fn inspect_editor_pipeline_state(
  snapshot_path : String,
  workspace_root : String,
) -> EditorPipelineState {
  let plan_id = "2026-05-31-editor-mode-real-pipeline"
  let course_page = "\{default_wenyu_course_workspace_root()}/wiki/course/beginner-course.md"
  let plan_path = "\{workspace_root}/plans/\{plan_id}/plan.md"
  let plan_ready = @fs.exists(plan_path)
  let course_ready = @fs.exists(course_page)
  let command_ready = text_file_contains(
    "src/cmd/main/main.mbt", "editor-pipeline",
  )
  let ui_ready = text_file_contains(
      "src/ui/rabbita-town/main/main.mbt", "editor_pipeline",
    ) ||
    text_file_contains("src/ui/rabbita-town/main/main.mbt", "Editor Pipeline")
  let repair_status = current_editor_pipeline_repair_status(snapshot_path)
  let feature_selection_status = editor_feature_selection_stage_status(
    snapshot_path, workspace_root,
  )
  let feature_selection_summary = editor_feature_selection_stage_summary(
    workspace_root,
  )
  let lifecycle = inspect_editor_pipeline_lifecycle(
    snapshot_path, workspace_root, plan_id,
  )
  let feature_history_ready = editor_pipeline_feature_history_ready(
    workspace_root,
  )
  let movement_loops = inspect_editor_pipeline_movement_loops()
  let movement_loop_ready = editor_pipeline_movement_loop_ready(
    lifecycle, movement_loops,
  )
  let placement_diffs = inspect_editor_pipeline_placement_diffs(workspace_root)
  let placement_diff_ready = editor_pipeline_placement_diff_ready(
    lifecycle, placement_diffs,
  )
  let terrain_layers = inspect_editor_pipeline_terrain_layers()
  let terrain_reasons = inspect_editor_pipeline_terrain_reasons()
  let terrain_label_ready = editor_pipeline_terrain_label_ready(
    lifecycle, terrain_layers, terrain_reasons,
  )
  let style_candidates = inspect_editor_pipeline_style_candidates()
  let style_selection = inspect_editor_pipeline_style_selection(
    style_candidates,
  )
  let style_comparison_ready = editor_pipeline_style_comparison_ready(
    lifecycle, style_candidates, style_selection,
  )
  let stage_inputs : EditorPipelineStageInputs = {
    course_page,
    plan_path,
    feature_selection_result_path: editor_feature_selection_result_path(
      workspace_root,
    ),
    repair_task_path: default_planbook_repair_path(snapshot_path~),
    module_config_ref: default_editor_pipeline_module_config_ref(),
    placement_proposal_path: default_editor_placement_proposal_path(
      workspace_root~,
    ),
    plan_ready,
    course_ready,
    command_ready,
    ui_ready,
    repair_status,
    feature_selection_status,
    feature_selection_summary,
    lifecycle,
    feature_history_ready,
    movement_loop_ready,
    placement_diff_ready,
    terrain_label_ready,
    style_comparison_ready,
  }
  let stages = editor_pipeline_stages(stage_inputs)
  let status = editor_pipeline_status(stage_inputs)
  {
    contract: "moontown.editor_pipeline.v1",
    status,
    source_course_book: default_wenyu_course_book_id(),
    source_course_page: course_page,
    planbook_id: default_planbook_book_id(),
    plan_id,
    repair_status,
    editor_mode_url: "./viewport.html?assets=generated&mode=editor&v=editor-pipeline",
    output_mode_url: "./viewport.html?assets=generated&mode=output&v=editor-pipeline",
    generated_at_ms: @env.now(),
    stages,
    lifecycle,
    movement_loops,
    placement_diffs,
    terrain_layers,
    terrain_reasons,
    style_candidates,
    style_selection,
  }
}
