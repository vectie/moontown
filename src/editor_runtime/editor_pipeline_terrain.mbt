///|
async fn inspect_editor_pipeline_terrain_layers() -> Array[
  EditorPipelineTerrainLayerRecord,
] {
  let config = match load_default_editor_pipeline_module_config() {
    Some(config) => config
    None => return []
  }
  @editor_pipeline.terrain_layers_for_modules(
    editor_pipeline_module_placements(config.modules),
  )
}

///|
async fn inspect_editor_pipeline_terrain_reasons() -> Array[
  EditorPipelineTerrainReasonRecord,
] {
  let config = match load_default_editor_pipeline_module_config() {
    Some(config) => config
    None => return []
  }
  ignore(config.version)
  ignore(config.description)
  @editor_pipeline.terrain_reason_records(
    editor_pipeline_module_placements(config.modules),
  )
}

///|
fn editor_pipeline_terrain_label_ready(
  lifecycle : EditorPipelineLifecycleRecord,
  layers : Array[EditorPipelineTerrainLayerRecord],
  reasons : Array[EditorPipelineTerrainReasonRecord],
) -> Bool {
  @editor_pipeline.terrain_label_ready(lifecycle, layers, reasons)
}
