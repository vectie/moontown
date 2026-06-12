///|
pub fn building_protocol_snapshot(
  protocol : BuildingProtocolDefinition,
  inbox_count~ : Int,
  contribution_count~ : Int,
  reduction_count~ : Int,
  outbox_count~ : Int,
  review_count~ : Int,
  latest_reduction_summary~ : String,
  latest_distribution_summary~ : String,
) -> BuildingProtocolSnapshot {
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
    ready: protocol_status_is_ready(status),
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
