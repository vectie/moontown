///|
/// One pack-owned domain object projected into MoonTown for discovery,
/// filtering, inspection, and action selection. `domain_payload` preserves the
/// pack vocabulary; MoonTown does not reinterpret it as a universal case type.
pub(all) struct PackTownSubject {
  subject_ref : String
  schema_id : String
  title : String
  summary : String
  lifecycle_state : String
  attention : String
  place_refs : Array[String]
  related_refs : Array[String]
  workflow_refs : Array[String]
  run_refs : Array[String]
  evidence_refs : Array[String]
  operation_ids : Array[String]
  domain_payload : Json
} derive(Debug, Eq, ToJson, FromJson)

///|
/// A read-only, replaceable projection published by one activated domain pack.
/// Mutation remains behind the exact declared operations in the pack manifest.
pub(all) struct PackTownProjection {
  contract_id : String
  pack_id : String
  product_id : String
  version : String
  generated_at : String
  subjects : Array[PackTownSubject]
} derive(Debug, Eq, ToJson, FromJson)

///|
/// A bottom-up MoonTown proposal offered to one pack-owned intake operation.
/// Conformance establishes a route only; it never invokes the operation or
/// grants the operation's authority.
pub(all) struct TownPackCandidate {
  contract_id : String
  candidate_ref : String
  origin_ref : String
  target_pack_id : String
  intake_operation_id : String
  submitted_by : String
  submitted_at : String
  title : String
  rationale : String
  claim_ceiling : String
  evidence_refs : Array[String]
  domain_payload : Json
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct PackTownBridgeIssue {
  path : String
  message : String
} derive(Debug, Eq, ToJson, FromJson)

///|
/// Exact pack capability metadata resolved for a conformant candidate. The
/// caller must still use MoonGate and MoonFlow before execution.
pub(all) struct CandidateRoute {
  pack_id : String
  product_id : String
  version : String
  operation_id : String
  authority : @pack.AuthorityClass
  review_required : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
/// Latest valid projection from every activated pack. Reconciliation replaces
/// only the publishing pack and never owns pack records or evidence.
pub(all) struct PackProjectionRegistry {
  projections : Array[PackTownProjection]
} derive(Debug, Eq, ToJson, FromJson)

///|
/// Durable, replay-safe lifecycle state for one installed pack version.
/// `stage` uses the wire values documented by `pack_lifecycle_stages`.
pub(all) struct PackLifecycleRecord {
  contract_id : String
  pack_id : String
  version : String
  stage : String
  sequence : Int
  updated_at : String
  last_projection_at : String?
  issue : String?
  evidence_refs : Array[String]
  applied_event_ids : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
/// An append-only fact reduced into `PackLifecycleRecord`. Event IDs make
/// retries idempotent; the reducer rejects skipped or reversed transitions.
pub(all) struct PackLifecycleEvent {
  contract_id : String
  event_id : String
  pack_id : String
  version : String
  kind : String
  occurred_at : String
  evidence_refs : Array[String]
  issue : String?
} derive(Debug, Eq, ToJson, FromJson)

///|
/// Durable state for a bottom-up candidate after route resolution. Acceptance
/// means the owning pack accepted a draft into its workflow; it never means
/// that a downstream external or physical action was authorized.
pub(all) struct PackCandidateReceipt {
  contract_id : String
  candidate_ref : String
  pack_id : String
  operation_id : String
  status : String
  sequence : Int
  updated_at : String
  evidence_refs : Array[String]
  issue : String?
} derive(Debug, Eq, ToJson, FromJson)

///|
/// Pack-owned evidence that settles a candidate previously delivered through
/// the workspace mailbox. MoonTown validates the bound pack, operation, and
/// candidate identity before applying the decision.
pub(all) struct PackCandidateAcknowledgement {
  contract_id : String
  candidate_ref : String
  pack_id : String
  operation_id : String
  decision : String
  occurred_at : String
  evidence_refs : Array[String]
  issue : String?
} derive(Debug, Eq, ToJson, FromJson)
