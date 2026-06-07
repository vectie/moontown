///|
fn building_protocol_markdown_row(
  protocol : @civic.BuildingProtocolSnapshot,
) -> String {
  "|\{protocol.title}|\{protocol.protocol_mode}|\{protocol.status}|\{protocol.inbox_count}|\{protocol.contribution_count}|\{protocol.reduction_count}|\{protocol.outbox_count}|\{protocol.review_count}|\{protocol_one_line(protocol.latest_reduction_summary)}|\n"
}
