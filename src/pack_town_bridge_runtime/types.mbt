///|
pub(all) struct PackBridgeRuntimeState {
  contract_id : String
  mut projections : @pack_town_bridge.PackProjectionRegistry
  mut capabilities : Array[PackBridgeCapability]
  lifecycles : Array[@pack_town_bridge.PackLifecycleRecord]
  candidates : Array[@pack_town_bridge.PackCandidateReceipt]
  candidate_envelopes : Array[@pack_town_bridge.TownPackCandidate]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct PackBridgeCapability {
  pack_id : String
  product_id : String
  version : String
  display_name : String
  intake_operation_ids : Array[String]
  operation_ids : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ProjectionIngestResult {
  accepted : Bool
  lifecycle : @pack_town_bridge.PackLifecycleRecord
  projection : @pack_town_bridge.PackTownProjection?
  issues : Array[@pack_town_bridge.PackTownBridgeIssue]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct CandidateSubmissionResult {
  accepted : Bool
  route : @pack_town_bridge.CandidateRoute
  receipt : @pack_town_bridge.PackCandidateReceipt
} derive(Debug, Eq, ToJson, FromJson)
