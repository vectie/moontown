///|
pub fn building_protocol_portfolio(
  protocols : Array[BuildingProtocolSnapshot],
  status_path : String,
  registry_path : String,
) -> BuildingProtocolPortfolio {
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
  protocols : Array[BuildingProtocolSnapshot],
  predicate : (BuildingProtocolSnapshot) -> Bool,
) -> Int {
  protocols.filter(predicate).length()
}

///|
pub fn building_protocol_is_ready(protocol : BuildingProtocolSnapshot) -> Bool {
  protocol.ready
}

///|
pub fn building_protocol_is_active(protocol : BuildingProtocolSnapshot) -> Bool {
  protocol.inbox_count > 0 ||
  protocol.contribution_count > 0 ||
  protocol.reduction_count > 0 ||
  protocol.outbox_count > 0
}

///|
pub fn building_protocol_needs_review(
  protocol : BuildingProtocolSnapshot,
) -> Bool {
  protocol.review_count > 0
}

///|
pub fn building_protocol_is_blocked(
  protocol : BuildingProtocolSnapshot,
) -> Bool {
  protocol.status == "blocked"
}

///|
pub fn building_protocol_markdown_row(
  protocol : BuildingProtocolSnapshot,
) -> String {
  "|\{protocol.title}|\{protocol.protocol_mode}|\{protocol.status}|\{protocol.inbox_count}|\{protocol.contribution_count}|\{protocol.reduction_count}|\{protocol.outbox_count}|\{protocol.review_count}|\{protocol_one_line(protocol.latest_reduction_summary)}|\n"
}

///|
fn protocol_one_line(text : String) -> String {
  text.replace(old="\n", new=" ").trim().to_owned()
}
