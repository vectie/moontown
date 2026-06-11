///|
pub(all) struct PlanbookCriterionStatus {
  id : String
  plan_id : String
  title : String
  owner : String
  satisfied : Bool
  evidence : String
  next_action : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct PlanbookAutonomyStatus {
  generated_at_ms : UInt64
  book_id : String
  workspace_root : String
  status : String
  open_count : Int
  satisfied_count : Int
  criteria : Array[PlanbookCriterionStatus]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct PlanbookRepairTask {
  id : String
  criterion_id : String
  title : String
  status : String
  owner : String
  workspace_root : String
  packet_path : String
  proposal_id : String?
  run_id : String?
  summary : String
  validation_command : String
  generated_at_ms : UInt64
} derive(Debug, Eq, ToJson, FromJson)
