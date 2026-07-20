///|
pub fn civic_communication_handoff_contract_version() -> String {
  "moontown.civic.communication.handoff.v1"
}

///|
pub fn civic_communication_receipt_contract_version() -> String {
  "moontown.civic.communication.receipt.v1"
}

///|
pub(all) struct CivicCommunicationScenarioHandoff {
  contract_version : String
  handoff_id : String
  producer : String
  producer_run_id : String
  scenario : CivicCommunicationScenario
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct CivicCommunicationExecutionReceipt {
  contract_version : String
  handoff_id : String
  producer : String
  producer_run_id : String
  consumer : String
  scenario_id : String
  round_id : String
  round_number : Int
  status : String
  reducer_kind : String
  participant_count : Int
  reviewable_output_count : Int
  review_status : String
  building_book_id : String
  artifact_refs : Array[String]
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn validate_civic_communication_handoff(
  handoff : CivicCommunicationScenarioHandoff,
) -> Array[String] {
  let errors : Array[String] = []
  if handoff.contract_version != civic_communication_handoff_contract_version() {
    errors.push(
      "unsupported handoff contract `\{handoff.contract_version}`; expected `\{civic_communication_handoff_contract_version()}`",
    )
  }
  if handoff.handoff_id.trim().is_empty() {
    errors.push("handoff_id must not be blank")
  }
  if handoff.producer.trim().is_empty() {
    errors.push("producer must not be blank")
  }
  if handoff.producer_run_id.trim().is_empty() {
    errors.push("producer_run_id must not be blank")
  }
  if handoff.scenario.id.trim().is_empty() {
    errors.push("scenario.id must not be blank")
  }
  errors
}
