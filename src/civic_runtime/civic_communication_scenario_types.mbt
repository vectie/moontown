///|
pub type CivicSalonReductionMode = @civic.CivicSalonReductionMode

///|
pub type CivicCommunicationReductionMode = @civic.CivicCommunicationReductionMode

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
pub type CivicCommunicationParticipantBook = @civic.CivicCommunicationParticipantBook

///|
pub type CivicSalonIdea = @civic.CivicSalonIdea

///|
pub type CivicCommunicationIdea = @civic.CivicCommunicationIdea

///|
pub type CivicSalonMetric = @civic.CivicSalonMetric

///|
pub type CivicCommunicationMetric = @civic.CivicCommunicationMetric

///|
pub type CivicSalonHomeReturn = @civic.CivicSalonHomeReturn

///|
pub type CivicCommunicationHomeReturn = @civic.CivicCommunicationHomeReturn

///|
pub type CivicSalonScenario = @civic.CivicSalonScenario

///|
pub type CivicCommunicationScenario = @civic.CivicCommunicationScenario
