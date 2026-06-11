///|
pub(all) struct AppToolBookInstallSpec {
  book_id : String
  title : String
  purpose : String
  websites : Array[String]
  analysis_method : String
  analysis_method_path : String
  tool_spec : String
  tool_spec_path : String
  civic_building_id : String
  cadence_ticks : Int
  workspace_root : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct AppToolBookStatus {
  book_id : String
  workspace_root : String
  required_count : Int
  missing_count : Int
  missing_paths : Array[String]
  has_catalog_entry : Bool
  has_standing_goal : Bool
  standing_goal_enabled : Bool
  has_tool_manifest : Bool
  ready : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
priv struct AppToolBookPathSpec {
  path : String
  copy_from_template : Bool
}

///|
pub(all) struct AppToolBookConfig {
  template_id : String
  template_version : String
  book_id : String
  book_type : String
  title : String
  purpose : String
  workspace_root : String
  tags : Array[String]
  skills : Array[String]
  watch : AppToolBookWatchSettings
  analysis : AppToolBookAnalysisSettings
  app : AppToolBookAppSettings
  civic : AppToolBookCivicSettings
  moondesk : AppToolBookMoondeskSettings
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct AppToolBookWatchSettings {
  websites : Array[String]
  cadence_ticks : Int
  source_policy : String
  notify_when : Array[String]
  required_outputs : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct AppToolBookAnalysisSettings {
  method_path : String
  report_path : String
  data_path : String
  review_path : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct AppToolBookAppSettings {
  tool_spec_path : String
  manifest_path : String
  app_root : String
  app_entrypoint : String
  generated_tool_path : String
  build_command : String
  review_status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct AppToolBookCivicSettings {
  building_id : String
  open_tool_action : String
  open_report_action : String
  configure_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct AppToolBookMoondeskSettings {
  create_mode : String
  editable_files : Array[String]
  output_files : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct AppToolManifest {
  schema : String
  book_id : String
  title : String
  purpose : String
  civic_building_id : String
  report_path : String
  app_entrypoint : String
  generated_tool_path : String
  data_path : String
  tool_spec_path : String
  build_command : String
  review_status : String
  last_successful_build_ms : UInt64?
} derive(Debug, Eq, ToJson, FromJson)
