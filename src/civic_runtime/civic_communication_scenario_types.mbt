///|
pub type CivicCommunicationReductionMode = @civic.CivicCommunicationReductionMode

///|
struct CivicCommunicationReductionResult {
  ideas : Array[CivicCommunicationIdea]
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
pub type CivicCommunicationParticipantBook = @civic.CivicCommunicationParticipantBook

///|
pub type CivicCommunicationIdea = @civic.CivicCommunicationIdea

///|
pub type CivicCommunicationMetric = @civic.CivicCommunicationMetric

///|
pub type CivicCommunicationHomeReturn = @civic.CivicCommunicationHomeReturn

///|
pub type CivicCommunicationScenario = @civic.CivicCommunicationScenario
