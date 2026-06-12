///|
fn editor_pipeline_selected_style_family(
  modules : Array[EditorPipelineModuleConfigEntry],
) -> String {
  @editor_pipeline.selected_style_family(
    editor_pipeline_module_placements(modules),
  )
}

///|
fn editor_pipeline_style_title(style_id : String) -> String {
  @editor_pipeline.style_title(style_id)
}

///|
fn editor_pipeline_style_asset_ref(style_id : String) -> String {
  @editor_pipeline.style_asset_ref(style_id)
}
