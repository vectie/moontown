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
  @civic.building_protocol_snapshot(
    protocol,
    inbox_count~,
    contribution_count~,
    reduction_count~,
    outbox_count~,
    review_count~,
    latest_reduction_summary~,
    latest_distribution_summary~,
  )
}
