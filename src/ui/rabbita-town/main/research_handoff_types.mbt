///|
priv struct ResearchHandoffRequest {
  handoff_url : String
  handoff_contract : String
  handoff_id : String
}

///|
priv struct ResearchHandoffParticipant {
  book_id : String
  title : String
  focus_area : String
  current_question : String
  contribution : String
  next_artifact : String
} derive(FromJson)

///|
priv struct ResearchHandoffScenario {
  id : String
  title : String
  communication_pattern_id : String?
  building_book_id : String
  topic : String
  skill_description : String
  protocol_channel : String
  reduction_kind : String
  output_channel : String
  review_gate : String
  review_owner : String
  review_reason : String
  quality_rules : Array[String]
  participants : Array[ResearchHandoffParticipant]
} derive(FromJson)

///|
priv struct ResearchHandoff {
  contract_version : String
  handoff_id : String
  producer : String
  producer_run_id : String
  scenario : ResearchHandoffScenario
} derive(FromJson)

///|
priv struct ResearchHandoffInspectionReply {
  contract_version : String
  ok : Bool
  requested_url : String
  upstream_status : Int
  handoff : Json?
  error : String
} derive(FromJson)

///|
priv struct ResearchHandoffExecutionReply {
  contract_version : String
  ok : Bool
  action : String
  requested_url : String
  handoff_id : String
  execution_status : String
  review_status : String
  callback_status : String
  callback_http_status : Int
  package : Json?
  error : String
} derive(FromJson)

///|
priv enum ResearchHandoffState {
  NoResearchHandoff
  LoadingResearchHandoff(ResearchHandoffRequest)
  ReadyResearchHandoff(ResearchHandoffRequest, ResearchHandoff)
  ExecutingResearchHandoff(ResearchHandoffRequest, ResearchHandoff, String)
  SettledResearchHandoff(
    ResearchHandoffRequest,
    ResearchHandoff,
    ResearchHandoffExecutionReply
  )
  BlockedResearchHandoff(String)
}
