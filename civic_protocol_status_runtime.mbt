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

///|
async fn inspect_wenyu_building_protocol(
  protocol : @civic.BuildingProtocolDefinition,
  ledger_base_dir? : String = default_protocol_ledger_base_dir(),
) -> @civic.BuildingProtocolSnapshot {
  let inbox_count = count_protocol_jsonl_records(
    protocol.building_id,
    "inbox",
    ledger_base_dir~,
  )
  let contribution_count = count_protocol_jsonl_records(
    protocol.building_id,
    "contributions",
    ledger_base_dir~,
  )
  let reduction_count = count_protocol_jsonl_records(
    protocol.building_id,
    "reductions",
    ledger_base_dir~,
  )
  let outbox_count = count_protocol_jsonl_records(
    protocol.building_id,
    "outbox",
    ledger_base_dir~,
  )
  let review_count = count_protocol_jsonl_records(
    protocol.building_id,
    "reviews",
    ledger_base_dir~,
  )
  let latest_reduction_summary = latest_protocol_reduction_summary(
    protocol.building_id,
    ledger_base_dir~,
  )
  let latest_distribution_summary = latest_protocol_distribution_summary(
    protocol.building_id,
    ledger_base_dir~,
  )
  let status = protocol_status_label(
    inbox_count~,
    contribution_count~,
    reduction_count~,
    outbox_count~,
    review_count~,
  )
  {
    building_id: protocol.building_id,
    title: protocol.title,
    book_id: protocol.book_id,
    protocol_mode: protocol.protocol_mode,
    persistence_mode: protocol.persistence_mode,
    social_responsibility: protocol.social_responsibility,
    status,
    ready: status == "reduced" || status == "review",
    inbox_count,
    contribution_count,
    reduction_count,
    outbox_count,
    review_count,
    latest_reduction_summary,
    latest_distribution_summary,
    skill_packs: protocol.skill_packs,
  }
}

///|
fn building_protocol_portfolio(
  protocols : Array[@civic.BuildingProtocolSnapshot],
  status_path : String,
  registry_path : String,
) -> @civic.BuildingProtocolPortfolio {
  {
    total: protocols.length(),
    ready_count: protocols.filter(fn(item) { item.ready }).length(),
    active_count: protocols
    .filter(fn(item) {
      item.inbox_count > 0 ||
      item.contribution_count > 0 ||
      item.reduction_count > 0 ||
      item.outbox_count > 0
    })
    .length(),
    review_count: protocols.filter(fn(item) { item.review_count > 0 }).length(),
    blocked_count: protocols
    .filter(fn(item) { item.status == "blocked" })
    .length(),
    status_path,
    registry_path,
    protocols,
  }
}

///|
fn protocol_status_label(
  inbox_count~ : Int,
  contribution_count~ : Int,
  reduction_count~ : Int,
  outbox_count~ : Int,
  review_count~ : Int,
) -> String {
  if review_count > 0 {
    "review"
  } else if reduction_count > 0 && outbox_count > 0 {
    "reduced"
  } else if reduction_count > 0 {
    "reducing"
  } else if contribution_count > 0 {
    "aggregating"
  } else if inbox_count > 0 {
    "inbox"
  } else {
    "defined"
  }
}

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
    builder.write_string(
      "|\{protocol.title}|\{protocol.protocol_mode}|\{protocol.status}|\{protocol.inbox_count}|\{protocol.contribution_count}|\{protocol.reduction_count}|\{protocol.outbox_count}|\{protocol.review_count}|\{protocol_one_line(protocol.latest_reduction_summary)}|\n",
    )
  }
  builder.to_string()
}
