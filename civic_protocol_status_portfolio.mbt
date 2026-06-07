///|
fn building_protocol_portfolio(
  protocols : Array[@civic.BuildingProtocolSnapshot],
  status_path : String,
  registry_path : String,
) -> @civic.BuildingProtocolPortfolio {
  {
    total: protocols.length(),
    ready_count: count_building_protocols_by(protocols, fn(item) {
      building_protocol_is_ready(item)
    }),
    active_count: count_building_protocols_by(protocols, fn(item) {
      building_protocol_is_active(item)
    }),
    review_count: count_building_protocols_by(protocols, fn(item) {
      building_protocol_needs_review(item)
    }),
    blocked_count: count_building_protocols_by(protocols, fn(item) {
      building_protocol_is_blocked(item)
    }),
    status_path,
    registry_path,
    protocols,
  }
}

///|
fn count_building_protocols_by(
  protocols : Array[@civic.BuildingProtocolSnapshot],
  predicate : (@civic.BuildingProtocolSnapshot) -> Bool,
) -> Int {
  protocols.filter(predicate).length()
}

///|
fn building_protocol_is_ready(
  protocol : @civic.BuildingProtocolSnapshot,
) -> Bool {
  protocol.ready
}

///|
fn building_protocol_is_active(
  protocol : @civic.BuildingProtocolSnapshot,
) -> Bool {
  protocol.inbox_count > 0 ||
  protocol.contribution_count > 0 ||
  protocol.reduction_count > 0 ||
  protocol.outbox_count > 0
}

///|
fn building_protocol_needs_review(
  protocol : @civic.BuildingProtocolSnapshot,
) -> Bool {
  protocol.review_count > 0
}

///|
fn building_protocol_is_blocked(
  protocol : @civic.BuildingProtocolSnapshot,
) -> Bool {
  protocol.status == "blocked"
}
