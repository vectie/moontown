///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct BookTemplateDescriptor {
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
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct BookTemplateRegistry {
  registry_path : String
  templates : Array[BookTemplateDescriptor]
  missing_count : Int32
  missing_paths : Array[String]
  ready : Bool
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct BookTemplateRegistryFile {
  templates : Array[BookTemplateDescriptor]
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct BookTemplateRequest {
  id : String
  template_id : String
  config_path : String
  status : String
  summary : String
  last_processed_tick : Int32
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct BookTemplateRequestLedger {
  requests : Array[BookTemplateRequest]
}

///|
#derive(Debug, Eq)
pub(all) struct BookTemplateRequestProcessResult {
  request : BookTemplateRequest
  processed : Bool
  reconciled_event : Bool
}

///|
#derive(Debug, Eq)
pub(all) struct BookTemplateRequestProcessingOutcome {
  ledger : BookTemplateRequestLedger
  processed : Int32
  reconciled_events : Int32
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct BookTemplateRequestEvent {
  id : String
  request_id : String
  template_id : String
  status : String
  config_path : String
  summary : String
  tick : Int32
  generated_at_ms : UInt64
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct BookTemplateRequestStatus {
  request_path : String
  event_path : String
  request_count : Int32
  pending_count : Int32
  installed_count : Int32
  failed_count : Int32
  retry_count : Int32
  ready : Bool
  summary : String
  latest_event_summary : String
}

///|
#derive(Debug, Eq)
pub(all) struct BookTemplateRequestStatusCounts {
  total : Int32
  pending : Int32
  installed : Int32
  failed : Int32
  retry : Int32
}

///|
#derive(Debug, Eq)
pub(all) struct BookTemplateRuntimeCounts {
  total : Int32
  pending : Int32
  failed : Int32
}
