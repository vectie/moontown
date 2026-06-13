///|
pub type CivicSalonReductionMode = @civic.CivicSalonReductionMode

///|
struct CivicSalonReductionResult {
  ideas : Array[CivicSalonIdea]
  status : @core.TaskExecutionStatus
  summary : String
  packet_id : String?
  packet_path : String?
  proposal_id : String?
  run_id : String?
  workspace_root : String
  reducer_kind : String
} derive(Eq)

///|
pub type CivicSalonParticipantBook = @civic.CivicSalonParticipantBook

///|
pub type CivicSalonIdea = @civic.CivicSalonIdea

///|
pub type CivicSalonMetric = @civic.CivicSalonMetric

///|
pub type CivicSalonHomeReturn = @civic.CivicSalonHomeReturn

///|
pub type CivicSalonScenario = @civic.CivicSalonScenario
