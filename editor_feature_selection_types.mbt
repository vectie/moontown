///|
pub struct EditorFeatureSelectionTask {
  id : String
  status : String
  workspace_root : String
  packet_path : String
  result_path : String
  proposal_id : String?
  run_id : String?
  summary : String
  generated_at_ms : UInt64
} derive(Debug, Eq, ToJson, FromJson)
