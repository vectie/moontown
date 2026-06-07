///|
pub struct BookQualityScore {
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
pub struct BookQualityAudit {
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
pub struct BookQualityReviewPacket {
  book_id : String
  book_type : String
  workspace_root : String
  structural_score : Int
  review_skill_path : String
  context_pages : Array[String]
  prompt : String
  output_contract : String
} derive(Eq, ToJson, FromJson)

///|
pub struct BookQualityReviewRun {
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
pub struct BookQualityReviewRunLedger {
  runs : Array[BookQualityReviewRun]
} derive(Eq, ToJson, FromJson)

///|
fn book_quality_research_type() -> String {
  "research-book"
}

///|
fn book_quality_course_type() -> String {
  "course-book"
}

///|
fn book_quality_planbook_type() -> String {
  "planbook"
}

///|
fn book_quality_cookbook_type() -> String {
  "cookbook"
}

///|
fn book_quality_civic_type() -> String {
  "civic-protocol-support"
}

///|
fn book_quality_operational_type() -> String {
  "operational-book"
}

///|
fn book_quality_general_type() -> String {
  "general-book"
}

///|
fn book_quality_reviewable_types() -> Array[String] {
  [
    book_quality_research_type(),
    book_quality_course_type(),
    book_quality_planbook_type(),
    book_quality_cookbook_type(),
    book_quality_civic_type(),
    book_quality_operational_type(),
  ]
}

///|
struct BookQualityRepairBridgeItem {
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
struct BookQualityRepairBridgeLedger {
  items : Array[BookQualityRepairBridgeItem]
} derive(Eq, ToJson, FromJson)

///|
pub fn default_book_quality_audit_path() -> String {
  ".moontown/book-quality/audit.json"
}

///|
pub fn default_book_quality_review_dir() -> String {
  ".moontown/book-quality/ai-review-packets"
}

///|
pub fn default_book_quality_review_result_dir() -> String {
  ".moontown/book-quality/ai-review-results"
}

///|
pub fn default_book_quality_review_run_path() -> String {
  ".moontown/book-quality/ai-review-runs.json"
}

///|
fn default_book_quality_repair_bridge_path() -> String {
  ".moontown/book-quality/repair-bridge.json"
}
