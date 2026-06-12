///|
async fn inspect_editor_pipeline_movement_loops() -> Array[
  EditorPipelineMovementLoopRecord,
] {
  let config = match load_default_editor_pipeline_module_config() {
    Some(config) => config
    None => return []
  }
  ignore(config.version)
  ignore(config.description)
  @editor_pipeline.movement_loop_records(
    editor_pipeline_module_placements(config.modules),
  )
}

///|
fn editor_pipeline_movement_loop_ready(
  lifecycle : EditorPipelineLifecycleRecord,
  records : Array[EditorPipelineMovementLoopRecord],
) -> Bool {
  @editor_pipeline.movement_loop_ready(lifecycle, records)
}
