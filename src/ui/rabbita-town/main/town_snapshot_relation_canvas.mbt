///|
/// One renderer-ready relation derived exclusively from the accepted snapshot.
priv struct TownSnapshotCanvasRelation {
  relation_id : @energy_valley_contract.StableId
  source_place_id : @energy_valley_contract.StableId
  target_place_id : @energy_valley_contract.StableId
  source_position : @energy_valley_contract.WorldPoint
  target_position : @energy_valley_contract.WorldPoint
  accent : String
}

///|
fn town_snapshot_place_center(
  place : @energy_valley_contract.Place,
) -> @energy_valley_contract.WorldPoint? {
  if place.footprint.vertices.is_empty() {
    return None
  }
  let mut x = 0.0
  let mut y = 0.0
  for point in place.footprint.vertices {
    x += point.x
    y += point.y
  }
  let count = place.footprint.vertices.length().to_double()
  Some(@energy_valley_contract.world_point(x / count, y / count))
}

///|
fn town_snapshot_relation_accent(
  kind : @energy_valley_contract.PlaceRelationKind,
) -> String {
  match kind {
    @energy_valley_contract.Collaboration => "#38bdf8"
    @energy_valley_contract.Dependency => "#f59e0b"
    @energy_valley_contract.KnowledgeFlow => "#a78bfa"
    @energy_valley_contract.Custom(_) => "#94a3b8"
  }
}

///|
fn town_snapshot_canvas_relations_from(
  snapshot : @energy_valley_contract.TownSnapshot,
  source_place_id : @energy_valley_contract.StableId,
) -> Array[TownSnapshotCanvasRelation] {
  let result : Array[TownSnapshotCanvasRelation] = []
  guard snapshot.world.find_place(source_place_id) is Some(source) else {
    return result
  }
  guard town_snapshot_place_center(source) is Some(source_position) else {
    return result
  }
  for relation in snapshot.world.relations_from(source_place_id) {
    match snapshot.world.find_place(relation.target_place_id) {
      Some(target) =>
        match town_snapshot_place_center(target) {
          Some(target_position) =>
            result.push({
              relation_id: relation.id,
              source_place_id,
              target_place_id: target.id,
              source_position,
              target_position,
              accent: town_snapshot_relation_accent(relation.kind),
            })
          None => ()
        }
      None => ()
    }
  }
  result
}

///|
fn golden_draw_selected_town_snapshot_relations(
  context : @dom.CanvasRenderingContext2D,
  snapshot : @energy_valley_contract.TownSnapshot,
  selected_place_id : @energy_valley_contract.StableId?,
  viewport_width : Int,
  viewport_height : Int,
) -> Unit {
  guard selected_place_id is Some(source_place_id) else { return }
  for relation in town_snapshot_canvas_relations_from(snapshot, source_place_id) {
    golden_draw_ecosystem_relation(
      context,
      golden_screen_x(
        relation.source_position.x,
        relation.source_position.y,
        viewport_width,
      ),
      golden_screen_y(
        relation.source_position.x,
        relation.source_position.y,
        viewport_height,
      ),
      golden_screen_x(
        relation.target_position.x,
        relation.target_position.y,
        viewport_width,
      ),
      golden_screen_y(
        relation.target_position.x,
        relation.target_position.y,
        viewport_height,
      ),
      relation.accent,
      golden_prefers_reduced_motion(),
      golden_animation_seconds(),
    )
  }
}
