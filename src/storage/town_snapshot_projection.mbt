///|
/// Browser/transport view of a durable `TownSnapshot`.
///
/// `event_count` remains the authoritative total from the durable snapshot;
/// `town.events.length()` is only the retained recent tail. The additional
/// retention object makes every omission explicit while remaining an additive
/// field for readers that only understand the existing `town`/`event_count`
/// shape.
pub struct TownSnapshotProjection {
  town : @core.TownState
  event_count : Int
  retention : @core.TownStateProjectionEvidence
} derive(Debug, Eq, ToJson, FromJson)

///|
/// Produces a bounded read view without changing the supplied durable snapshot.
pub fn project_town_snapshot(
  snapshot : TownSnapshot,
  limits? : @core.TownStateProjectionLimits = @core.TownStateProjectionLimits::new(),
) -> TownSnapshotProjection {
  let projection = snapshot.town.bounded_read_projection(limits)
  {
    town: projection.state,
    event_count: snapshot.event_count,
    retention: projection.evidence,
  }
}
