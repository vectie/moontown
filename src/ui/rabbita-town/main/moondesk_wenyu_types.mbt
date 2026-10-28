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
  version : Int32
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
  version : Int32
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
  running_count : Int32
  waiting_count : Int32
  review_count : Int32
  blocked_count : Int32
  completed_count : Int32
  visible_agent_count : Int32
  issue_count : Int32
}
