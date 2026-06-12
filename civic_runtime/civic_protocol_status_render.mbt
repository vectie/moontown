///|
fn render_wenyu_building_protocol_portfolio(
  portfolio : @civic.BuildingProtocolPortfolio,
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("# Wenyu Building Protocol Status\n\n")
  builder.write_string(
    "Total: \{portfolio.total}; active: \{portfolio.active_count}; ready: \{portfolio.ready_count}; review: \{portfolio.review_count}; blocked: \{portfolio.blocked_count}.\n\n",
  )
  builder.write_string(
    "| Building | Protocol | Status | Inbox | Contributions | Reductions | Outbox | Reviews | Latest reduction |\n",
  )
  builder.write_string("|---|---|---:|---:|---:|---:|---:|---:|---|\n")
  for protocol in portfolio.protocols {
    builder.write_string(@civic.building_protocol_markdown_row(protocol))
  }
  builder.to_string()
}
