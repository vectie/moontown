///|
#derive(Debug, Eq, FromJson)
struct EditorPipelineModuleConfig {
  version : Int32
  description : String
  modules : Array[EditorPipelineModuleConfigEntry]
}

///|
#derive(Debug, Eq, FromJson)
struct EditorPipelineModuleConfigEntry {
  id : String
  enabled : Bool
  title : String
  book_id : String
  district : String
  building_kind : String
  grid_x : Int32
  grid_y : Int32
  footprint_w : Int32
  footprint_h : Int32
  display_w : Int32
  display_h : Int32
  entrance_x : Int32
  entrance_y : Int32
  interior_kind : String
  style_family : String
  asset_base : String
  asset_roof : String
  protocol_pattern : String
  use_case : String
  agent_flow : String
  summary : String
}

///|
fn default_editor_pipeline_module_config_path() -> String {
  "src/ui/assets/tilemap/modules/wenyu-town-modules.json"
}

///|
fn default_editor_pipeline_module_config_ref() -> String {
  default_editor_pipeline_module_config_path()
}

///|
async fn load_default_editor_pipeline_module_config() -> EditorPipelineModuleConfig? {
  load_editor_pipeline_module_config(
    default_editor_pipeline_module_config_path(),
  )
}

///|
async fn load_editor_pipeline_module_config(
  path : String,
) -> EditorPipelineModuleConfig? {
  let parsed = match @support.read_optional_json_file(path) {
    Some(json) => json
    None => return None
  }
  let config : EditorPipelineModuleConfig = @json.from_json(parsed) catch {
    _ => return None
  }
  Some(config)
}

///|
fn editor_pipeline_module_placement(
  module_entry : EditorPipelineModuleConfigEntry,
) -> EditorPipelineModulePlacement {
  {
    id: module_entry.id,
    enabled: module_entry.enabled,
    title: module_entry.title,
    book_id: module_entry.book_id,
    district: module_entry.district,
    building_kind: module_entry.building_kind,
    grid_x: module_entry.grid_x,
    grid_y: module_entry.grid_y,
    footprint_w: module_entry.footprint_w,
    footprint_h: module_entry.footprint_h,
    entrance_x: module_entry.entrance_x,
    entrance_y: module_entry.entrance_y,
    style_family: module_entry.style_family,
  }
}

///|
fn editor_pipeline_module_placements(
  modules : Array[EditorPipelineModuleConfigEntry],
) -> Array[EditorPipelineModulePlacement] {
  modules.map(editor_pipeline_module_placement)
}
