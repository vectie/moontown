///|
priv struct MoonFlowReceiverRequest {
  run_id : String
  handoff_token : String
}

///|
priv struct MoonFlowReceiverBinding {
  handoff_token : String
  handoff_digest : String
  request_id : String
  attempt_id : String
  idempotency_key : String
  intake_path : String
  status_path : String
  receipt_path : String
  return_path : String
} derive(ToJson, FromJson)

///|
priv struct MoonFlowReceiverRun {
  run_id : String
  book_id : String
  work_item_id : String
  declaration_id : String
  product_id : String
  operation : String
  issued_projection_sequence : Int
  issued_work_item_status : String
  issued_run_outcome : String
} derive(ToJson, FromJson)

///|
priv struct MoonFlowReceiverAuthority {
  requested_authority : String
  status : String
  granted : Bool
} derive(ToJson, FromJson)

///|
priv struct MoonFlowReceiverContracts {
  capability_status : String
  input_contracts : Array[String]
  output_contracts : Array[String]
  required_claim : String
  claim_ceiling : String
} derive(ToJson, FromJson)

///|
priv struct MoonFlowReceiverInputs {
  digest : String
  artifacts : Array[String]
} derive(ToJson, FromJson)

///|
priv struct MoonFlowReceiverReview {
  required : Bool
  status : String
  acceptance_criteria : Array[String]
} derive(ToJson, FromJson)

///|
priv struct MoonFlowReceiverEntrypoint {
  kind : String
  pack_id : String
  entrypoint_id : String
  path : String
  fallback_path : String
} derive(ToJson, FromJson)

///|
priv struct MoonFlowReceiverPayload {
  action_kind : String
  run : MoonFlowReceiverRun
  authority : MoonFlowReceiverAuthority
  contracts : MoonFlowReceiverContracts
  inputs : MoonFlowReceiverInputs
  evidence : Json
  review : MoonFlowReceiverReview
  app_entrypoint : MoonFlowReceiverEntrypoint
} derive(ToJson, FromJson)

///|
priv struct MoonFlowReceiverIntake {
  contract_id : String
  contract_version : String
  handoff_id : String
  handoff_ref : String
  binding : MoonFlowReceiverBinding
  payload : MoonFlowReceiverPayload
} derive(ToJson, FromJson)

///|
priv struct MoonFlowReceiverStatus {
  contract_id : String
  contract_version : String
  run_id : String
  handoff_token : String
  handoff_digest : String
  status : String
  stage : String
  work_item_status : String
  run_outcome : String
  projection_sequence : Int
  receipt_ref : String
  receipt_digest : String
  receipt_recorded_at : String
  intake_path : String
  status_path : String
  receipt_path : String
  return_path : String
} derive(FromJson)

///|
priv struct MoonFlowReceiverInspectionReply {
  contract_version : String
  ok : Bool
  requested_run_id : String
  requested_handoff_token : String
  intake : Json?
  status : Json?
  error : String
} derive(FromJson)

///|
priv struct MoonFlowReceiverSettlementReply {
  contract_version : String
  ok : Bool
  action : String
  product_execution : Json?
  receiver_status : Json?
  error : String
} derive(FromJson)

///|
priv enum MoonFlowReceiverState {
  NoMoonFlowReceiver
  LoadingMoonFlowReceiver(MoonFlowReceiverRequest)
  ReadyMoonFlowReceiver(
    MoonFlowReceiverRequest,
    MoonFlowReceiverIntake,
    MoonFlowReceiverStatus
  )
  ExecutingMoonFlowReceiver(
    MoonFlowReceiverRequest,
    MoonFlowReceiverIntake,
    MoonFlowReceiverStatus,
    String
  )
  SettledMoonFlowReceiver(
    MoonFlowReceiverRequest,
    MoonFlowReceiverIntake,
    MoonFlowReceiverStatus,
    MoonFlowReceiverSettlementReply?
  )
  BlockedMoonFlowReceiver(String)
}
