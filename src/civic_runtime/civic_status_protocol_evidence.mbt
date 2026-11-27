///|
priv struct CivicServiceProtocolEvidence {
  status : String
  ready : Bool
  inbox_count : Int32
  contribution_count : Int32
  reduction_count : Int32
  outbox_count : Int32
  review_count : Int32
  latest_summary : String
  history : Array[ProtocolHistoryEntry]
  history_state : String
}

///|
async fn inspect_civic_service_protocol(
  service : @civic.CivicServiceDefinition,
) -> CivicServiceProtocolEvidence {
  let protocol = @civic.wenyu_building_protocol_for_service(service)
  let snapshot = inspect_wenyu_building_protocol(protocol)
  let history = civic_protocol_history(protocol.building_id)
  {
    status: snapshot.status,
    ready: snapshot.ready,
    inbox_count: snapshot.inbox_count,
    contribution_count: snapshot.contribution_count,
    reduction_count: snapshot.reduction_count,
    outbox_count: snapshot.outbox_count,
    review_count: snapshot.review_count,
    latest_summary: snapshot.latest_reduction_summary,
    history,
    history_state: civic_protocol_history_state(snapshot.status, history),
  }
}
