///|
async fn inspect_editor_pipeline_placement_diffs(
  workspace_root : String,
) -> Array[EditorPipelinePlacementDiffRecord] {
  let current_config = match load_default_editor_pipeline_module_config() {
    Some(config) => config
    None => return []
  }
  let proposal_path = default_editor_placement_proposal_path(workspace_root~)
  let proposed_config = match
    load_editor_pipeline_module_config(proposal_path) {
    Some(config) => config
    None => current_config
  }
  editor_pipeline_placement_diff_records(
    current_config.modules,
    proposed_config.modules,
  )
}

///|
fn editor_pipeline_placement_diff_ready(
  lifecycle : EditorPipelineLifecycleRecord,
  records : Array[EditorPipelinePlacementDiffRecord],
) -> Bool {
  @editor_pipeline.placement_diff_ready(lifecycle, records)
}
