///|
/// The immutable semantic frame most recently accepted by Canvas. Pointer
/// interaction resolves against this record, not against a newly compiled
/// Model that may already be one update ahead of what the user can see.
priv struct GoldenValleyAcceptedCanvasFrame {
  snapshot : @energy_valley_contract.TownSnapshot
  runtime_agent_interaction_enabled : Bool
}

///|
let golden_valley_canvas_frame_cache : Map[
  String,
  GoldenValleyAcceptedCanvasFrame,
] = Map([])

///|
fn town_snapshot_has_live_runtime_canvas_actor(
  snapshot : @energy_valley_contract.TownSnapshot,
) -> Bool {
  town_snapshot_canvas_actor_records(snapshot, 0.0, true, None).any(record => {
    record.actor_id.scope() == "runtime-agent"
  })
}

///|
fn golden_valley_accept_canvas_frame_with_runtime_eligibility(
  snapshot : @energy_valley_contract.TownSnapshot,
  runtime_agent_interaction_enabled : Bool,
) -> Unit {
  golden_valley_canvas_frame_cache.clear()
  golden_valley_canvas_frame_cache["accepted"] = {
    snapshot,
    runtime_agent_interaction_enabled,
  }
}

///|
fn golden_valley_accept_canvas_frame(
  snapshot : @energy_valley_contract.TownSnapshot,
) -> Unit {
  golden_valley_accept_canvas_frame_with_runtime_eligibility(
    snapshot,
    town_snapshot_has_live_runtime_canvas_actor(snapshot),
  )
}

///|
fn golden_valley_canvas_frame() -> @energy_valley_contract.TownSnapshot? {
  golden_valley_canvas_frame_cache.get("accepted").map(frame => frame.snapshot)
}

///|
fn golden_valley_accepted_canvas_frame() -> GoldenValleyAcceptedCanvasFrame? {
  golden_valley_canvas_frame_cache.get("accepted")
}

///|
fn town_snapshot_canvas_building_at_tile(
  snapshot : @energy_valley_contract.TownSnapshot,
  x : Int,
  y : Int,
) -> TownCanvasBuilding? {
  let point = @energy_valley_contract.world_point(
    x.to_double() + 0.5,
    y.to_double() + 0.5,
  )
  for building in town_snapshot_canvas_buildings(snapshot) {
    match snapshot.world.find_place(building.place_id) {
      Some(place) if place.footprint.contains_point(point) =>
        return Some(building)
      _ => ()
    }
  }
  None
}

///|
fn golden_valley_canvas_frame_building_at_tile(
  x : Int,
  y : Int,
) -> TownCanvasBuilding? {
  match golden_valley_canvas_frame() {
    Some(snapshot) => town_snapshot_canvas_building_at_tile(snapshot, x, y)
    None => None
  }
}
