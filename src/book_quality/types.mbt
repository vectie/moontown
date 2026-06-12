///|
pub(all) struct BookQualityScore {
  book_id : String
  title : String
  book_type : String
  workspace_root : String
  structural_score : Int
  structural_grade : String
  semantic_score : Int?
  semantic_grade : String
  quality_status : String
  score : Int
  grade : String
  ready : Bool
  strengths : Array[String]
  gaps : Array[String]
  next_action : String
} derive(Eq, ToJson, FromJson)

///|
pub(all) struct BookQualityAudit {
  generated_at : String
  catalog_path : String
  total : Int
  world_class_count : Int
  ready_count : Int
  weakest_book_id : String
  weakest_score : Int
  scores : Array[BookQualityScore]
} derive(Eq, ToJson, FromJson)

///|
pub(all) struct BookQualityReviewPacket {
  book_id : String
  book_type : String
  policy : @policy.BookPolicy
  workspace_root : String
  structural_score : Int
  review_skill_path : String
  context_pages : Array[String]
  prompt : String
  output_contract : String
} derive(Eq, ToJson, FromJson)

///|
pub(all) struct BookQualityReviewRun {
  book_id : String
  packet_path : String
  result_path : String
  proposal_id : String?
  run_id : String?
  status : String
  summary : String
  generated_at_ms : UInt64
} derive(Eq, ToJson, FromJson)

///|
priv struct BookQualityReviewRunLedger {
  runs : Array[BookQualityReviewRun]
} derive(ToJson, FromJson)

///|
priv struct BookQualityReviewRunDisplayRow {
  run : BookQualityReviewRun
  result_state : String
}

///|
pub(all) struct BookQualityRequiredPath {
  relative : String
  points : Int
} derive(Eq, ToJson, FromJson)

///|
pub(all) struct BookQualityPathSetAssessment {
  score : Int
  strength : String?
  gap : String?
} derive(Eq, ToJson, FromJson)

///|
pub(all) struct BookQualityPathAssessment {
  score : Int
  strength : String?
  gap : String?
} derive(Eq, ToJson, FromJson)

///|
pub(all) struct BookQualityWorkspaceAssessment {
  score : Int
  strengths : Array[String]
  gaps : Array[String]
} derive(Eq, ToJson, FromJson)

///|
pub(all) struct BookQualitySignalAssessment {
  score : Int
  strengths : Array[String]
  gaps : Array[String]
} derive(Eq, ToJson, FromJson)

///|
pub(all) struct BookQualityRepairBridgeItem {
  book_id : String
  book_type : String
  workspace_root : String
  semantic_score : Int
  semantic_grade : String
  repair_owner : String
  next_repair_task : String
  review_result_path : String
  book_review_path : String
  standing_goal_id : String
  status : String
  generated_at_ms : UInt64
} derive(Eq, ToJson, FromJson)

///|
pub(all) struct BookQualityRepairBridgeLedger {
  items : Array[BookQualityRepairBridgeItem]
} derive(Eq, ToJson, FromJson)
