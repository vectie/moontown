///|
pub fn default_editor_pipeline_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{planbook_autonomy_base_dir(snapshot_path)}/editor-pipeline.json"
}

///|
pub fn default_editor_pipeline_markdown_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{planbook_autonomy_base_dir(snapshot_path)}/editor-pipeline.md"
}

///|
pub fn default_editor_placement_proposal_path(
  workspace_root? : String = default_planbook_workspace_root(),
) -> String {
  "\{workspace_root}/raw/editor-pipeline/placement-proposal.json"
}
