///|
pub fn default_editor_feature_selection_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{planbook_autonomy_base_dir(snapshot_path)}/editor-feature-selection.json"
}

///|
pub fn default_editor_feature_selection_markdown_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{planbook_autonomy_base_dir(snapshot_path)}/editor-feature-selection.md"
}

///|
pub fn editor_feature_selection_result_path(workspace_root : String) -> String {
  "\{editor_pipeline_raw_dir(workspace_root)}/next-feature.json"
}

///|
fn editor_selected_feature_implementation_path(
  workspace_root : String,
) -> String {
  "\{editor_pipeline_raw_dir(workspace_root)}/selected-feature-implementation.md"
}

///|
fn editor_implemented_features_ledger_path(workspace_root : String) -> String {
  "\{editor_pipeline_raw_dir(workspace_root)}/implemented-features.md"
}

///|
fn editor_feature_selection_context_path(workspace_root : String) -> String {
  "\{editor_pipeline_raw_dir(workspace_root)}/FEATURE_SELECTION_CONTEXT.md"
}

///|
fn editor_feature_selection_current_evidence_path(
  workspace_root : String,
) -> String {
  "\{editor_pipeline_raw_dir(workspace_root)}/CURRENT_UI_EVIDENCE.md"
}

///|
fn editor_feature_selection_packet_path(
  workspace_root : String,
  task_id : String,
) -> String {
  "\{editor_pipeline_raw_dir(workspace_root)}/\{task_id}.packet.json"
}

///|
fn editor_implemented_feature_archive_path(
  workspace_root : String,
  feature_id : String,
  suffix : String,
) -> String {
  "\{workspace_root}/raw/editor-pipeline/implemented-features/\{feature_id}.\{suffix}"
}

///|
pub fn editor_pipeline_plan_path(
  workspace_root : String,
  plan_id : String,
) -> String {
  "\{workspace_root}/plans/\{plan_id}/plan.md"
}

///|
pub fn planbook_workspace_root_for_source_root(source_root : String) -> String {
  "\{source_root}/.moontown/books/\{default_planbook_book_id()}"
}

///|
pub fn wenyu_course_workspace_root_for_source_root(
  source_root : String,
) -> String {
  "\{source_root}/.moontown/books/\{default_wenyu_course_book_id()}"
}

///|
fn editor_pipeline_raw_dir(workspace_root : String) -> String {
  "\{workspace_root}/raw/editor-pipeline"
}

///|
fn editor_workspace_root_from_result_path(result_path : String) -> String {
  let pipeline_dir = @path.Path::dirname(result_path).to_string()
  let raw_dir = @path.Path::dirname(pipeline_dir).to_string()
  @path.Path::dirname(raw_dir).to_string()
}

///|
fn editor_feature_absolute_path(path : String) -> String {
  @core.absolute_path_from_base(planbook_repair_source_root(), path)
}
