///|
priv struct MoondeskHandoffArtifact {
  id : String
  title : String
  kind : String
  status : String
  scope : String
  source_path : String
  target_path : String
  summary : String
  import_contract : Array[String]
} derive(FromJson)

///|
priv struct MoondeskHandoffIndex {
  version : Int
  description : String
  artifacts : Array[MoondeskHandoffArtifact]
} derive(FromJson)

///|
priv struct MoondeskBridgeRecord {
  id : String
  kind : String
  status : String
  path : String
  title : String
  summary : String
  target : String
  created_at : String
} derive(FromJson)

///|
priv struct MoondeskBridgeIndex {
  generated_at : String
  moondesk_root_available : Bool
  records : Array[MoondeskBridgeRecord]
} derive(FromJson)

///|
priv struct WenyuTownModuleConfig {
  version : Int
  description : String
  modules : Array[WenyuTownModule]
} derive(FromJson)

///|
priv struct WenyuTownModule {
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
} derive(FromJson)

///|
priv struct WenyuModuleRuntimeState {
  status_class : String
  status_label : String
  source_label : String
  detail : String
  running_count : Int
  waiting_count : Int
  review_count : Int
  blocked_count : Int
  completed_count : Int
  visible_agent_count : Int
  issue_count : Int
}
