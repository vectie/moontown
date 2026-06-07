///|
pub async fn write_wenyu_building_protocol_status(
  status_path? : String = default_wenyu_protocol_status_path(),
  registry_path? : String = default_wenyu_protocol_registry_path(),
) -> String {
  let portfolio = inspect_wenyu_building_protocols(status_path~, registry_path~)
  write_text_file(status_path, portfolio.to_json().stringify(indent=2))
  write_text_file(
    protocol_status_markdown_path(status_path),
    render_wenyu_building_protocol_portfolio(portfolio),
  )
  "Wrote Wenyu building protocol status for \{portfolio.total} building(s) to \{status_path}."
}

///|
pub async fn render_wenyu_building_protocol_status(
  status_path? : String = default_wenyu_protocol_status_path(),
  registry_path? : String = default_wenyu_protocol_registry_path(),
) -> String {
  render_wenyu_building_protocol_portfolio(
    inspect_wenyu_building_protocols(status_path~, registry_path~),
  )
}

///|
pub async fn inspect_wenyu_building_protocols(
  status_path? : String = default_wenyu_protocol_status_path(),
  registry_path? : String = default_wenyu_protocol_registry_path(),
) -> @civic.BuildingProtocolPortfolio {
  let snapshots : Array[@civic.BuildingProtocolSnapshot] = []
  let ledger_base_dir = protocol_ledger_base_dir_for_status_path(status_path)
  for protocol in @civic.wenyu_building_protocols() {
    snapshots.push(inspect_wenyu_building_protocol(protocol, ledger_base_dir~))
  }
  building_protocol_portfolio(snapshots, status_path, registry_path)
}
