///|
pub(all) struct ParticipantWork {
  book_id : String
  packet_id : String
  proposal_id : String
  run_id : String
  status : String
  detail : String
  output_ref : String
  output_digest : String
  output_text : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct WorkDecision {
  decision_id : String
  reviewer_id : String
  reviewer_name : String
  prompt : String
  decision : String
  rationale : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct OneoffWork {
  contract_version : String
  draft_id : String
  revision : String
  status : String
  detail : String
  participants : Array[ParticipantWork]
  result_digest : String
  result_text : String
  review_status : String
  decisions : Array[WorkDecision]
  review_version : Int
  review_history_text : String
  operator_id : String
  package_digest : String
  book_status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn empty_work(id : String, revision : String) -> OneoffWork {
  {
    contract_version: "moontown.collaboration-oneoff.v1",
    draft_id: id,
    revision,
    status: "not_started",
    detail: "Prepare verifies frozen inputs. Only Run participants once starts work.",
    participants: [],
    result_digest: "",
    result_text: "",
    review_status: "not_ready",
    decisions: [],
    review_version: 0,
    review_history_text: "",
    operator_id: "",
    package_digest: "",
    book_status: "",
  }
}
