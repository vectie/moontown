///|
fn editor_pipeline_module_moved(
  current : EditorPipelineModuleConfigEntry,
  proposed : EditorPipelineModuleConfigEntry,
) -> Bool {
  current.grid_x != proposed.grid_x ||
  current.grid_y != proposed.grid_y ||
  current.footprint_w != proposed.footprint_w ||
  current.footprint_h != proposed.footprint_h ||
  current.entrance_x != proposed.entrance_x ||
  current.entrance_y != proposed.entrance_y
}

///|
fn editor_pipeline_placement_ref(
  module_entry : EditorPipelineModuleConfigEntry,
) -> String {
  "tile:\{module_entry.grid_x},\{module_entry.grid_y}/\{module_entry.footprint_w}x\{module_entry.footprint_h}"
}

///|
fn editor_pipeline_entrance_ref(
  module_entry : EditorPipelineModuleConfigEntry,
) -> String {
  "tile:\{module_entry.entrance_x},\{module_entry.entrance_y}"
}

///|
fn editor_pipeline_placement_terrain_status(
  module_entry : EditorPipelineModuleConfigEntry,
) -> String {
  if module_entry.entrance_x < 0 || module_entry.entrance_y < 0 {
    return "blocked:missing-entrance"
  }
  if module_entry.footprint_w <= 0 || module_entry.footprint_h <= 0 {
    return "blocked:invalid-footprint"
  }
  "reviewable:entrance-and-footprint-present"
}
