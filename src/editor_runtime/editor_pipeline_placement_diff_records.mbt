///|
fn editor_pipeline_placement_diff_records(
  current_modules : Array[EditorPipelineModuleConfigEntry],
  proposed_modules : Array[EditorPipelineModuleConfigEntry],
) -> Array[EditorPipelinePlacementDiffRecord] {
  @editor_pipeline.placement_diff_records(
    editor_pipeline_module_placements(current_modules),
    editor_pipeline_module_placements(proposed_modules),
  )
}
