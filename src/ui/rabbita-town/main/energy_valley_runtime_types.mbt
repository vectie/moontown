///|
priv struct EnergyValleyRuntimeResultLink {
  label : String
  url : String
  kind : String
} derive(FromJson)

///|
priv struct EnergyValleyRuntimeParticipant {
  runId : String
  parentRunId : String?
  family : String
  status : String
  artifacts : Array[String]
} derive(FromJson)

///|
priv struct EnergyValleyRuntimeCollaboration {
  mode : String
  participants : Array[EnergyValleyRuntimeParticipant]
} derive(FromJson)

///|
priv struct EnergyValleyRuntimeProgress {
  checkedSources : Int?
  newSources : Int?
  acceptedFacts : Int?
  rejectedFacts : Int?
  pagesChanged : Int?
  bookChanged : Bool?
} derive(FromJson)

///|
priv struct EnergyValleyRuntimeWorkItem {
  id : String
  title : String
  status : String
  buildingModuleKey : String
  agentId : String?
  agentName : String?
  role : String?
  runId : String?
  bookId : String?
  summary : String?
  updatedAt : String?
  requestId : String?
  standingGoalId : String?
  correlationId : String?
  artifacts : Array[String]
  resultLinks : Array[EnergyValleyRuntimeResultLink]?
  collaboration : EnergyValleyRuntimeCollaboration?
  progress : EnergyValleyRuntimeProgress?
  activityKind : String?
  activityLabel : String?
  originBuildingModuleKey : String?
  destinationBuildingModuleKey : String?
  source : String
} derive(FromJson)

///|
priv struct EnergyValleyRuntimeAgent {
  id : String
  name : String
  role : String
  avatarRef : String?
  status : String
  buildingModuleKey : String?
  workItemId : String?
  runId : String?
  bookId : String?
  activityKind : String?
  activityLabel : String?
  originBuildingModuleKey : String?
  destinationBuildingModuleKey : String?
} derive(FromJson)

///|
priv struct EnergyValleyRuntimeProjection {
  schema : String
  mode : String
  observedAt : String
  knowledgeCatalogDigest : String?
  tick : Int?
  tasks : Array[EnergyValleyRuntimeWorkItem]
  history : Array[EnergyValleyRuntimeWorkItem]?
  agents : Array[EnergyValleyRuntimeAgent]
  message : String?
} derive(FromJson)

///|
priv enum EnergyValleyRuntimePhase {
  Loading
  Live
  Stale
  Unavailable
  Error
} derive(Eq)

///|
/// One immutable start point for a specific Agent + work + route journey.
/// Runtime refreshes may replace projection content without restarting this
/// clock; a changed journey key receives a new tick and wall-clock origin.
priv struct EnergyValleyRuntimePresenceClock {
  journey_key : String
  started_at_tick : Int
  started_at_ms : Double
} derive(Debug, Eq)

///|
priv struct EnergyValleyRuntimeState {
  phase : EnergyValleyRuntimePhase
  projection : EnergyValleyRuntimeProjection?
  version : Int
  fresh_at_ms : Double
  presence_started_at_tick : Int
  presence_clocks : Array[EnergyValleyRuntimePresenceClock]
  error : String
}
