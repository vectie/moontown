///|
#derive(Eq, ToJson, FromJson)
pub(all) struct BookQualityScore {
  book_id : String
  title : String
  book_type : String
  workspace_root : String
  structural_score : Int32
  structural_grade : String
  semantic_score : Int32?
  semantic_grade : String
  quality_status : String
  score : Int32
  grade : String
  ready : Bool
  strengths : Array[String]
  gaps : Array[String]
  next_action : String
}

///|
#derive(Eq, ToJson, FromJson)
pub(all) struct BookQualityAudit {
  generated_at : String
  catalog_path : String
  total : Int32
  world_class_count : Int32
  ready_count : Int32
  weakest_book_id : String
  weakest_score : Int32
  scores : Array[BookQualityScore]
}

///|
#derive(Eq, ToJson, FromJson)
pub(all) struct BookQualityReviewPacket {
  book_id : String
  book_type : String
  policy : @policy.BookPolicy
  workspace_root : String
  structural_score : Int32
  review_skill_path : String
  context_pages : Array[String]
  prompt : String
  output_contract : String
}

///|
#derive(ToJson, FromJson)
pub(all) struct BookQualityReviewProposalSpec {
  packet_id : String
  title : String
  summary : String
  request_text : String
  profile : String
  output_contract : String
  context_pages : Array[String]
  skill_paths : Array[String]
  notes : Array[String]
  tags : Array[String]
  metadata : Json
}

///|
#derive(Eq, ToJson, FromJson)
pub(all) struct BookQualityReviewRun {
  book_id : String
  packet_path : String
  result_path : String
  proposal_id : String?
  run_id : String?
  status : String
  summary : String
  generated_at_ms : UInt64
}

///|
#derive(ToJson, FromJson)
pub(all) struct BookQualityReviewRunLedger {
  runs : Array[BookQualityReviewRun]
}

///|
#derive(Eq)
pub(all) struct BookQualityReviewRunObservation {
  run : BookQualityReviewRun
  has_result : Bool
  process_alive : Bool
}

///|
priv struct BookQualityReviewRunDisplayRow {
  run : BookQualityReviewRun
  result_state : String
}

///|
#derive(Eq, ToJson, FromJson)
pub(all) struct BookQualityRequiredPath {
  relative : String
  points : Int32
}

///|
#derive(Eq, ToJson, FromJson)
pub(all) struct BookQualityPathSetAssessment {
  score : Int32
  strength : String?
  gap : String?
}

///|
#derive(Eq, ToJson, FromJson)
pub(all) struct BookQualityPathAssessment {
  score : Int32
  strength : String?
  gap : String?
}

///|
#derive(Eq, ToJson, FromJson)
pub(all) struct BookQualityWorkspaceAssessment {
  score : Int32
  strengths : Array[String]
  gaps : Array[String]
}

///|
#derive(Eq, ToJson, FromJson)
pub(all) struct BookQualitySignalAssessment {
  score : Int32
  strengths : Array[String]
  gaps : Array[String]
}

///|
#derive(Eq, ToJson, FromJson)
pub(all) struct BookQualityContentObservation {
  semantic_review_text : String
  research_deep_report_word_count : Int32
  course_index_text : String
  cookbook_audit_exists : Bool
}

///|
#derive(Eq, ToJson, FromJson)
pub(all) struct BookQualityStructuralObservation {
  workspace_exists : Bool
  wiki_index_exists : Bool
  projection_state_exists : Bool
  existing_relative_paths : Array[String]
  civic_latest_result_exists : Bool
}

///|
#derive(Eq, ToJson, FromJson)
pub(all) struct BookQualityRepairBridgeItem {
  book_id : String
  book_type : String
  workspace_root : String
  semantic_score : Int32
  semantic_grade : String
  repair_owner : String
  next_repair_task : String
  review_result_path : String
  book_review_path : String
  standing_goal_id : String
  status : String
  generated_at_ms : UInt64
}

///|
#derive(Eq, ToJson, FromJson)
pub(all) struct BookQualityRepairBridgeLedger {
  items : Array[BookQualityRepairBridgeItem]
}
