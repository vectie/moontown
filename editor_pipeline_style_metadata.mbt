///|
fn editor_pipeline_selected_style_family(
  modules : Array[EditorPipelineModuleConfigEntry],
) -> String {
  for module_entry in modules {
    if module_entry.enabled && !module_entry.style_family.trim().is_empty() {
      return module_entry.style_family
    }
  }
  "white-tech-pavilion"
}

///|
fn editor_pipeline_style_title(style_id : String) -> String {
  match style_id {
    "white-tech-pavilion" => "White Tech Pavilion"
    "wenyu-pixel-backup" => "Wenyu Pixel Backup"
    "shape-label-workbench" => "Shape Label Workbench"
    _ => label_from_slug(style_id)
  }
}

///|
fn editor_pipeline_style_asset_ref(style_id : String) -> String {
  match style_id {
    "white-tech-pavilion" =>
      "ui/assets/tilemap/buildings/white-tech-pavilion/alpha"
    "wenyu-pixel-backup" => "ui/assets/tilemap/buildings/wenyu"
    "shape-label-workbench" => "ui/assets/tilemap/buildings/wenyu_shape"
    _ => "ui/assets/tilemap/buildings"
  }
}
