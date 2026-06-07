///|
pub struct BookTemplateDescriptor {
  template_id : String
  book_type : String
  specialization : String
  title : String
  purpose : String
  root : String
  install_example : String
  install_command : String
  status_command : String
  required_paths : Array[String]
  editable_files : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct BookTemplateRegistry {
  registry_path : String
  templates : Array[BookTemplateDescriptor]
  missing_count : Int
  missing_paths : Array[String]
  ready : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct BookTemplateRequest {
  id : String
  template_id : String
  config_path : String
  status : String
  summary : String
  last_processed_tick : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct BookTemplateRequestLedger {
  requests : Array[BookTemplateRequest]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct BookTemplateRequestEvent {
  id : String
  request_id : String
  template_id : String
  status : String
  config_path : String
  summary : String
  tick : Int
  generated_at_ms : UInt64
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct BookTemplateRequestStatus {
  request_path : String
  event_path : String
  request_count : Int
  pending_count : Int
  installed_count : Int
  failed_count : Int
  retry_count : Int
  ready : Bool
  summary : String
  latest_event_summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
priv struct BookTemplateRequestProcessContext {
  request_base_dir : String
  event_path : String
  registry_path : String
  book_catalog_path : String
  standing_goal_path : String
  tick : Int
}

///|
priv struct BookTemplateRequestProcessResult {
  request : BookTemplateRequest
  processed : Bool
  reconciled_event : Bool
}

///|
struct BookTemplateRegistryFile {
  templates : Array[BookTemplateDescriptor]
} derive(Debug, Eq, ToJson, FromJson)
