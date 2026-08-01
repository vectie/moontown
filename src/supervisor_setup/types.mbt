///|
pub fn supervisor_profile_schema() -> String {
  "moontown.supervisor-profile.v1"
}

///|
pub fn supervisor_store_schema() -> String {
  "moontown.supervisor-setup-store.v1"
}

///|
pub(all) enum SupervisorAuthorityCeiling {
  SuggestOnly
  DelegateBoundedWork
  RequestBookkeeperReview
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum SupervisorLifecycle {
  SupervisorDraft
  SupervisorReady
  SupervisorPendingRuntime
  SupervisorActive
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SupervisorIdentity {
  display_name : String
  avatar_url : String?
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SupervisorBindings {
  workspace_id : String
  building_id : String
  book_ids : Array[String]
  max_active_workers : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SupervisorConsent {
  terms_version : String
  profile_activation : Bool
  runtime_delegation : Bool
  bookkeeper_review : Bool
  confirmed_at_ms : UInt64?
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SupervisorProfile {
  schema : String
  profile_id : String
  owner_user_id : String
  identity : SupervisorIdentity
  role : String
  mission : String
  tone : String
  capabilities : Array[String]
  bindings : SupervisorBindings
  authority_ceiling : SupervisorAuthorityCeiling
  revision : Int
  lifecycle : SupervisorLifecycle
  consent : SupervisorConsent
  content_digest : String
  created_at_ms : UInt64
  updated_at_ms : UInt64
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SupervisorProfileDraft {
  command_id : String
  expected_version : Int
  expected_cursor : Int
  profile_id : String
  display_name : String
  avatar_url : String?
  role : String
  mission : String
  tone : String
  capabilities : Array[String]
  workspace_id : String
  building_id : String
  book_ids : Array[String]
  max_active_workers : Int
  authority_ceiling : SupervisorAuthorityCeiling
  consent : SupervisorConsent
} derive(Debug, Eq)

///|
pub(all) struct SupervisorActivationDraft {
  command_id : String
  expected_version : Int
  expected_cursor : Int
  runtime_expected_cursor : Int?
} derive(Debug, Eq)

///|
pub(all) struct SupervisorProfileActivationPayload {
  contract_id : String
  supervisor_id : String
  profile_id : String
  profile_version : Int
  profile_digest : String
  source_product : String
  runtime_profile : Json
  runtime_binding : Json
  activated_at : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SupervisorActivationHandoff {
  schema : String
  handoff_id : String
  owner_user_id : String
  target_runtime : String
  payload_schema : String
  payload : SupervisorProfileActivationPayload
  command_id : String
  request_digest : String
  expected_cursor : Int?
  status : String
  revision : Int
  claimed_by : String?
  runtime_command : Json?
  runtime_receipt : Json?
  created_at_ms : UInt64
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SupervisorWorkerTask {
  task_id : String
  conversation_id : String
  title : String
  cwd : String
  model : String
  web_search : Bool
  metadata : Json
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SupervisorWorkerBudget {
  max_cost_micro_usd : Int64
  max_runtime_ms : Int64
  max_tokens : Int64
  max_artifacts : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SupervisorWorkerBounds {
  claim_ceiling : String
  budget : SupervisorWorkerBudget
  artifact_prefixes : Array[String]
  expires_at : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SupervisorExecutionHandoff {
  schema : String
  handoff_id : String
  command_id : String
  request_digest : String
  owner_user_id : String
  supervisor_profile_id : String
  parent_run_id : String
  target_run_id : String?
  action : String
  instruction : String
  target_runtime : String
  command_kind : String
  worker_task : SupervisorWorkerTask?
  worker_bounds : SupervisorWorkerBounds?
  worker_bounds_source : String
  transport_request_digest : String?
  transport_endpoint : String?
  transport_request : Json?
  runtime_command : Json?
  expected_cursor : Int?
  status : String
  revision : Int
  claimed_by : String?
  runtime_receipt : Json?
  created_at_ms : UInt64
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct BookkeeperExactReviewRequest {
  schema : String
  request_id : String
  owner_user_id : String
  run_id : String
  state : String
  product_outcome_submission : Json
  source_outcome_digest : String
  review_intent : Json
  revision : Int
  claimed_by : String?
  resume_state : String?
  bookkeeper_receipt : Json?
  created_at_ms : UInt64
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SupervisorRuntimeObservation {
  schema : String
  observation_id : String
  request_digest : String
  supervisor_profile_id : String
  parent_run_id : String
  runtime_cursor : Int
  status_projection : Json
  event_replay : Json
  received_from : String
  received_at_ms : UInt64
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SupervisorAuditEvent {
  event_id : String
  command_id : String
  actor_user_id : String
  action : String
  object_id : String
  from_revision : Int
  to_revision : Int
  cursor : Int
  recorded_at_ms : UInt64
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SupervisorIdempotencyRecord {
  command_id : String
  actor_user_id : String
  operation : String
  request_digest : String
  response : Json
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SupervisorSetupStore {
  schema : String
  cursor : Int
  profiles : Array[SupervisorProfile]
  activation_handoffs : Array[SupervisorActivationHandoff]
  execution_handoffs : Array[SupervisorExecutionHandoff]
  runtime_observations : Array[SupervisorRuntimeObservation]
  review_requests : Array[BookkeeperExactReviewRequest]
  audit_events : Array[SupervisorAuditEvent]
  idempotency : Array[SupervisorIdempotencyRecord]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct SupervisorSetupApplication {
  state_root : String
}
