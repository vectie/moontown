///|
struct EditorPipelineModuleConfig {
  version : Int
  description : String
  modules : Array[EditorPipelineModuleConfigEntry]
} derive(Debug, Eq, FromJson)

///|
struct EditorPipelineModuleConfigEntry {
  id : String
  enabled : Bool
  title : String
  book_id : String
  district : String
  building_kind : String
  grid_x : Int
  grid_y : Int
  footprint_w : Int
  footprint_h : Int
  display_w : Int
  display_h : Int
  entrance_x : Int
  entrance_y : Int
  interior_kind : String
  style_family : String
  asset_base : String
  asset_roof : String
  protocol_pattern : String
  use_case : String
  agent_flow : String
  summary : String
} derive(Debug, Eq, FromJson)

///|
fn default_editor_pipeline_module_config_path() -> String {
  "ui/assets/tilemap/modules/wenyu-town-modules.json"
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
  let parsed = match read_optional_json_file(path) {
    Some(json) => json
    None => return None
  }
  let config : EditorPipelineModuleConfig = @json.from_json(parsed) catch {
    _ => return None
  }
  Some(config)
}
