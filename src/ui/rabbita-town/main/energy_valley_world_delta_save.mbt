///|
/// JSON-facing mirror of the pure contract's versioned WorldDelta. Stable IDs
/// are stored as strings because the contract intentionally keeps StableId's
/// representation opaque. Loading always canonicalizes them again before the
/// delta is validated or compiled.
priv struct EnergyValleySave {
  budget : Int
  buildings : Array[GoldenValleyBuilding]
  roads : Array[String]
  parks : Array[String]
  /// Optional for saves written before custom buildings had durable IDs.
  next_authored_building_sequence : Int?
} derive(ToJson, FromJson)

///|
priv struct SavedWorldDeltaBuilding {
  id : String
  building : GoldenValleyBuilding
} derive(ToJson, FromJson)

///|
priv struct SavedWorldDeltaBuildingMovement {
  id : String
  x : Int
  y : Int
  width : Int
  depth : Int
  entrance_x : Int?
  entrance_y : Int?
} derive(ToJson, FromJson)

///|
priv struct SavedWorldDeltaDeletion {
  id : String
} derive(ToJson, FromJson)

///|
priv struct SavedWorldDeltaGridPoint {
  x : Int
  y : Int
} derive(ToJson, FromJson, Debug, Eq)

///|
priv struct SavedWorldDeltaRoad {
  id : String
  path : Array[SavedWorldDeltaGridPoint]
} derive(ToJson, FromJson, Debug, Eq)

///|
priv struct SavedWorldDeltaPark {
  id : String
  x : Int
  y : Int
} derive(ToJson, FromJson)

///|
priv enum SavedWorldDeltaOperation {
  AddBuilding(SavedWorldDeltaBuilding)
  MoveBuilding(SavedWorldDeltaBuildingMovement)
  DeleteBuilding(SavedWorldDeltaDeletion)
  AddRoad(SavedWorldDeltaRoad)
  MoveRoad(SavedWorldDeltaRoad)
  DeleteRoad(SavedWorldDeltaDeletion)
  AddPark(SavedWorldDeltaPark)
  MovePark(SavedWorldDeltaPark)
  DeletePark(SavedWorldDeltaDeletion)
} derive(ToJson, FromJson)

///|
priv struct EnergyValleyWorldDeltaLedger {
  schema_version : String
  base_blueprint_id : String
  base_blueprint_digest : String
  revision : Int
  budget : Int
  operations : Array[SavedWorldDeltaOperation]
  /// Cached deterministic hash of the serialized typed operation payload.
  /// Optional so already-published v3 ledgers remain decodable.
  content_digest : Int?
  next_authored_building_sequence : Int
} derive(ToJson, FromJson)

///|
fn energy_valley_world_delta_schema() -> String {
  "moontown.energy-valley.world-delta.v3"
}

///|
fn energy_valley_saved_operations_digest(
  operations : Array[SavedWorldDeltaOperation],
) -> Int {
  ecosystem_stable_hash(ToJson::to_json(operations).stringify())
}

///|
fn energy_valley_saved_road_id(point : SavedWorldDeltaGridPoint) -> String {
  "authored-road-component-\{point.x}-\{point.y}"
}

///|
fn energy_valley_saved_park_id(x : Int, y : Int) -> String {
  "authored-park-\{x}-\{y}"
}

///|
fn energy_valley_parse_saved_tile(value : String) -> (Int, Int)? {
  match value.split_once(":") {
    Some((x, y)) => {
      let column = @string.parse_int(x.to_owned()) catch { _ => return None }
      let row = @string.parse_int(y.to_owned()) catch { _ => return None }
      Some((column, row))
    }
    None => None
  }
}

///|
fn energy_valley_append_saved_road_walk(
  point : SavedWorldDeltaGridPoint,
  cells : Map[String, SavedWorldDeltaGridPoint],
  visited : Map[String, Bool],
  path : Array[SavedWorldDeltaGridPoint],
) -> Unit {
  let key = golden_valley_tile_key(point.x, point.y)
  if visited.contains(key) {
    return
  }
  visited[key] = true
  path.push(point)
  for delta in [(0, -1), (1, 0), (0, 1), (-1, 0)] {
    let neighbor_key = golden_valley_tile_key(
      point.x + delta.0,
      point.y + delta.1,
    )
    match cells.get(neighbor_key) {
      Some(neighbor) if !visited.contains(neighbor_key) => {
        energy_valley_append_saved_road_walk(neighbor, cells, visited, path)
        // DFS backtracking preserves a cardinally adjacent path through
        // branching road paint without inventing geometry.
        path.push(point)
      }
      _ => ()
    }
  }
}

///|
fn energy_valley_saved_road_components(
  encoded_roads : ArrayView[String],
) -> Array[SavedWorldDeltaRoad] {
  let cells : Map[String, SavedWorldDeltaGridPoint] = Map([])
  let ordered : Array[SavedWorldDeltaGridPoint] = []
  for encoded in encoded_roads {
    match energy_valley_parse_saved_tile(encoded) {
      Some((x, y)) => {
        let key = golden_valley_tile_key(x, y)
        if !cells.contains(key) {
          let point : SavedWorldDeltaGridPoint = { x, y }
          cells[key] = point
          ordered.push(point)
        }
      }
      None => ()
    }
  }
  ordered.sort_by((left, right) => {
    let by_y = left.y.compare(right.y)
    if by_y == 0 {
      left.x.compare(right.x)
    } else {
      by_y
    }
  })
  let visited : Map[String, Bool] = Map([])
  let result : Array[SavedWorldDeltaRoad] = []
  for point in ordered {
    if visited.contains(golden_valley_tile_key(point.x, point.y)) {
      continue
    }
    let path : Array[SavedWorldDeltaGridPoint] = []
    energy_valley_append_saved_road_walk(point, cells, visited, path)
    result.push({ id: energy_valley_saved_road_id(point), path })
  }
  result
}

///|
fn energy_valley_world_delta_from_projection(
  save : EnergyValleySave,
  revision : Int,
  base_blueprint_digest : String,
) -> EnergyValleyWorldDeltaLedger {
  let operations : Array[SavedWorldDeltaOperation] = []
  for building in save.buildings {
    let id = golden_valley_nonempty_authored_id(building).unwrap_or(
      "unmigrated-building-\{building.x}-\{building.y}",
    )
    operations.push(AddBuilding({ id, building }))
  }
  for road in energy_valley_saved_road_components(save.roads) {
    operations.push(AddRoad(road))
  }
  for encoded in save.parks {
    match energy_valley_parse_saved_tile(encoded) {
      Some((x, y)) =>
        operations.push(
          AddPark({ id: energy_valley_saved_park_id(x, y), x, y }),
        )
      None => ()
    }
  }
  let result : EnergyValleyWorldDeltaLedger = {
    schema_version: energy_valley_world_delta_schema(),
    base_blueprint_id: "blueprint/wenyu-energy-valley",
    base_blueprint_digest,
    revision: revision.max(1),
    budget: save.budget,
    operations,
    content_digest: Some(energy_valley_saved_operations_digest(operations)),
    next_authored_building_sequence: save.next_authored_building_sequence
    .unwrap_or(1)
    .max(1),
  }
  result
}

///|
fn energy_valley_world_delta_projection(
  delta : EnergyValleyWorldDeltaLedger,
) -> EnergyValleySave {
  let projected = energy_valley_project_contract_world_delta(
    energy_valley_contract_world_delta(delta),
  )
  {
    budget: delta.budget.max(0),
    buildings: projected.buildings,
    roads: projected.roads,
    parks: projected.parks,
    next_authored_building_sequence: Some(
      delta.next_authored_building_sequence.max(1),
    ),
  }
}

///|
fn decode_energy_valley_world_delta_save(
  text : String,
) -> EnergyValleyWorldDeltaLedger? {
  let parsed = @json.parse(text) catch { _ => return None }
  let decoded : EnergyValleyWorldDeltaLedger = @json.from_json(parsed) catch {
    _ => return None
  }
  if decoded.schema_version != energy_valley_world_delta_schema() ||
    decoded.revision < 1 ||
    decoded.base_blueprint_id.is_empty() ||
    decoded.base_blueprint_digest.is_empty() ||
    decoded.content_digest
    .map(digest => {
      digest != energy_valley_saved_operations_digest(decoded.operations)
    })
    .unwrap_or(false) {
    None
  } else {
    Some(decoded)
  }
}

///|
let energy_valley_base_contract_world_cache : Map[
  Int,
  @energy_valley_contract.CompiledTownWorld,
] = Map([])

///|
fn energy_valley_base_contract_world_for_seed(
  seed : Int,
) -> @energy_valley_contract.CompiledTownWorld {
  match energy_valley_base_contract_world_cache.get(seed) {
    Some(world) => return world
    None => ()
  }
  let world = ecosystem_contract_world_from_snapshot(
    ecosystem_world_snapshot(golden_valley_world(seed), [], [], []),
    seed,
  )
  energy_valley_base_contract_world_cache[seed] = world
  world
}

///|
fn energy_valley_base_blueprint_digest_for_seed(seed : Int) -> String {
  energy_valley_base_contract_world_for_seed(seed).blueprint_digest
}

///|
fn energy_valley_base_blueprint_digest(_model : Model) -> String {
  energy_valley_base_blueprint_digest_for_seed(active_energy_valley_seed())
}

///|
fn energy_valley_world_delta_provenance() -> @energy_valley_contract.Provenance {
  @energy_valley_contract.provenance(
    "moontown-local-world-delta",
    "v3",
    @energy_valley_contract.UserDelta,
    @energy_valley_contract.Bounded,
  )
}

///|
fn energy_valley_world_delta_polygon(
  x : Int,
  y : Int,
  width : Int,
  depth : Int,
) -> @energy_valley_contract.Polygon {
  @energy_valley_contract.polygon([
    @energy_valley_contract.world_point(x.to_double(), y.to_double()),
    @energy_valley_contract.world_point(
      (x + width.max(1)).to_double(),
      y.to_double(),
    ),
    @energy_valley_contract.world_point(
      (x + width.max(1)).to_double(),
      (y + depth.max(1)).to_double(),
    ),
    @energy_valley_contract.world_point(
      x.to_double(),
      (y + depth.max(1)).to_double(),
    ),
  ])
}

///|
fn energy_valley_world_delta_roof(
  style : String,
) -> @energy_valley_contract.RoofKind {
  match style {
    "garden" => @energy_valley_contract.Garden
    "home" | "custom-home" | "row" | "courtyard" =>
      @energy_valley_contract.Gabled
    "tower" | "custom-tower" | "radar" => @energy_valley_contract.Glass
    "market" => @energy_valley_contract.Sculptural
    _ => @energy_valley_contract.Flat
  }
}

///|
fn energy_valley_saved_entrance(
  x : Int?,
  y : Int?,
) -> @energy_valley_contract.GridPosition? {
  match (x, y) {
    (Some(column), Some(row)) =>
      Some(@energy_valley_contract.grid_position(column, row))
    _ => None
  }
}

///|
fn energy_valley_contract_world_delta(
  saved : EnergyValleyWorldDeltaLedger,
) -> @energy_valley_contract.WorldDelta {
  let operations : Array[@energy_valley_contract.WorldDeltaOperation] = []
  let provenance = energy_valley_world_delta_provenance()
  for operation in saved.operations {
    match operation {
      AddBuilding(value) => {
        let building = value.building
        operations.push(
          @energy_valley_contract.AddBuilding(
            @energy_valley_contract.building_addition(
              ecosystem_contract_scoped_id("delta-building", value.id),
              building.name,
              @energy_valley_contract.grid_position(building.x, building.y),
              energy_valley_world_delta_polygon(
                building.x,
                building.y,
                building.width,
                building.depth,
              ),
              @energy_valley_contract.building_profile(
                building.style,
                building.floors.max(1),
                building.floors.max(1).to_double() * 4.2,
                energy_valley_world_delta_roof(building.style),
                ecosystem_stable_hash(value.id),
              ),
              provenance,
              module_key=building.module_key,
              entrance_grid=energy_valley_saved_entrance(
                building.entrance_x,
                building.entrance_y,
              ),
            ),
          ),
        )
      }
      MoveBuilding(value) =>
        operations.push(
          @energy_valley_contract.MoveBuilding(
            @energy_valley_contract.building_movement(
              ecosystem_contract_scoped_id("delta-building", value.id),
              @energy_valley_contract.grid_position(value.x, value.y),
              energy_valley_world_delta_polygon(
                value.x,
                value.y,
                value.width,
                value.depth,
              ),
              provenance,
              entrance_grid=energy_valley_saved_entrance(
                value.entrance_x,
                value.entrance_y,
              ),
            ),
          ),
        )
      DeleteBuilding(value) =>
        operations.push(
          @energy_valley_contract.DeleteBuilding(
            @energy_valley_contract.building_deletion(
              ecosystem_contract_scoped_id("delta-building", value.id),
              provenance,
            ),
          ),
        )
      AddRoad(value) => {
        let path : Array[@energy_valley_contract.GridPosition] = []
        for point in value.path {
          path.push(@energy_valley_contract.grid_position(point.x, point.y))
        }
        operations.push(
          @energy_valley_contract.AddRoad(
            @energy_valley_contract.road_addition(
              ecosystem_contract_scoped_id("delta-road", value.id),
              path,
              @energy_valley_contract.Local,
              8.0,
              [
                @energy_valley_contract.Pedestrian,
                @energy_valley_contract.Bicycle,
                @energy_valley_contract.ServiceVehicle,
              ],
              provenance,
            ),
          ),
        )
      }
      MoveRoad(value) => {
        let path : Array[@energy_valley_contract.GridPosition] = []
        for point in value.path {
          path.push(@energy_valley_contract.grid_position(point.x, point.y))
        }
        operations.push(
          @energy_valley_contract.MoveRoad(
            @energy_valley_contract.road_movement(
              ecosystem_contract_scoped_id("delta-road", value.id),
              path,
              provenance,
            ),
          ),
        )
      }
      DeleteRoad(value) =>
        operations.push(
          @energy_valley_contract.DeleteRoad(
            @energy_valley_contract.road_deletion(
              ecosystem_contract_scoped_id("delta-road", value.id),
              provenance,
            ),
          ),
        )
      AddPark(value) =>
        operations.push(
          @energy_valley_contract.AddPark(
            @energy_valley_contract.park_addition(
              ecosystem_contract_scoped_id("delta-park", value.id),
              "共建林地",
              @energy_valley_contract.grid_position(value.x, value.y),
              energy_valley_world_delta_polygon(value.x, value.y, 1, 1),
              provenance,
            ),
          ),
        )
      MovePark(value) =>
        operations.push(
          @energy_valley_contract.MovePark(
            @energy_valley_contract.park_movement(
              ecosystem_contract_scoped_id("delta-park", value.id),
              @energy_valley_contract.grid_position(value.x, value.y),
              energy_valley_world_delta_polygon(value.x, value.y, 1, 1),
              provenance,
            ),
          ),
        )
      DeletePark(value) =>
        operations.push(
          @energy_valley_contract.DeletePark(
            @energy_valley_contract.park_deletion(
              ecosystem_contract_scoped_id("delta-park", value.id),
              provenance,
            ),
          ),
        )
    }
  }
  @energy_valley_contract.world_delta(
    saved.schema_version,
    ecosystem_contract_id(saved.base_blueprint_id),
    saved.base_blueprint_digest,
    saved.revision,
    operations,
  ).normalized()
}

///|
fn energy_valley_contract_world_delta_for_model(
  model : Model,
  _seed : Int,
) -> @energy_valley_contract.WorldDelta {
  energy_valley_contract_world_delta(model.energy_world_delta)
}

///|
priv struct EnergyValleyWorldDeltaProjection {
  buildings : Array[GoldenValleyBuilding]
  roads : Array[String]
  parks : Array[String]
}

///|
fn energy_valley_world_delta_polygon_size(
  polygon : @energy_valley_contract.Polygon,
) -> (Int, Int) {
  if polygon.vertices.is_empty() {
    return (1, 1)
  }
  let mut minimum_x = polygon.vertices[0].x
  let mut maximum_x = minimum_x
  let mut minimum_y = polygon.vertices[0].y
  let mut maximum_y = minimum_y
  for vertex in polygon.vertices {
    minimum_x = minimum_x.min(vertex.x)
    maximum_x = maximum_x.max(vertex.x)
    minimum_y = minimum_y.min(vertex.y)
    maximum_y = maximum_y.max(vertex.y)
  }
  (
    (maximum_x - minimum_x).ceil().to_int().max(1),
    (maximum_y - minimum_y).ceil().to_int().max(1),
  )
}

///|
fn energy_valley_project_contract_world_delta(
  delta : @energy_valley_contract.WorldDelta,
) -> EnergyValleyWorldDeltaProjection {
  let building_order : Array[String] = []
  let buildings_by_id : Map[String, GoldenValleyBuilding] = Map([])
  let road_order : Array[String] = []
  let roads_by_id : Map[
    String,
    ReadOnlyArray[@energy_valley_contract.GridPosition],
  ] = Map([])
  let park_order : Array[String] = []
  let parks_by_id : Map[String, @energy_valley_contract.GridPosition] = Map([])
  for operation in delta.operations {
    match operation {
      @energy_valley_contract.AddBuilding(value) => {
        let key = value.id.to_string()
        let (width, depth) = energy_valley_world_delta_polygon_size(
          value.footprint,
        )
        if !building_order.contains(key) {
          building_order.push(key)
        }
        buildings_by_id[key] = {
          authored_id: Some(value.id.local_key()),
          module_key: value.module_key,
          name: value.name,
          style: value.profile.archetype,
          x: value.grid_anchor.column,
          y: value.grid_anchor.row,
          width,
          depth,
          entrance_x: value.entrance_grid.map(point => point.column),
          entrance_y: value.entrance_grid.map(point => point.row),
          floors: value.profile.floors,
        }
      }
      @energy_valley_contract.MoveBuilding(value) => {
        let key = value.id.to_string()
        match buildings_by_id.get(key) {
          Some(current) => {
            let (width, depth) = energy_valley_world_delta_polygon_size(
              value.footprint,
            )
            let shift_x = value.grid_anchor.column - current.x
            let shift_y = value.grid_anchor.row - current.y
            let entrance_x = match value.entrance_grid {
              Some(point) => Some(point.column)
              None => current.entrance_x.map(x => x + shift_x)
            }
            let entrance_y = match value.entrance_grid {
              Some(point) => Some(point.row)
              None => current.entrance_y.map(y => y + shift_y)
            }
            buildings_by_id[key] = {
              ..current,
              x: value.grid_anchor.column,
              y: value.grid_anchor.row,
              width,
              depth,
              entrance_x,
              entrance_y,
            }
          }
          None => ()
        }
      }
      @energy_valley_contract.DeleteBuilding(value) =>
        buildings_by_id.remove(value.id.to_string())
      @energy_valley_contract.AddRoad(value) => {
        let key = value.id.to_string()
        if !road_order.contains(key) {
          road_order.push(key)
        }
        roads_by_id[key] = value.grid_path
      }
      @energy_valley_contract.MoveRoad(value) => {
        let key = value.id.to_string()
        if roads_by_id.contains(key) {
          roads_by_id[key] = value.grid_path
        }
      }
      @energy_valley_contract.DeleteRoad(value) =>
        roads_by_id.remove(value.id.to_string())
      @energy_valley_contract.AddPark(value) => {
        let key = value.id.to_string()
        if !park_order.contains(key) {
          park_order.push(key)
        }
        parks_by_id[key] = value.grid_anchor
      }
      @energy_valley_contract.MovePark(value) => {
        let key = value.id.to_string()
        if parks_by_id.contains(key) {
          parks_by_id[key] = value.grid_anchor
        }
      }
      @energy_valley_contract.DeletePark(value) =>
        parks_by_id.remove(value.id.to_string())
    }
  }
  let buildings : Array[GoldenValleyBuilding] = []
  for id in building_order {
    match buildings_by_id.get(id) {
      Some(building) => buildings.push(building)
      None => ()
    }
  }
  let roads : Array[String] = []
  for id in road_order {
    match roads_by_id.get(id) {
      Some(path) =>
        for point in path {
          let encoded = golden_valley_tile_key(point.column, point.row)
          if !roads.contains(encoded) {
            roads.push(encoded)
          }
        }
      None => ()
    }
  }
  let parks : Array[String] = []
  for id in park_order {
    match parks_by_id.get(id) {
      Some(point) => {
        let encoded = golden_valley_tile_key(point.column, point.row)
        if !parks.contains(encoded) {
          parks.push(encoded)
        }
      }
      None => ()
    }
  }
  { buildings, roads, parks }
}

///|
fn energy_valley_empty_world_delta_for_seed(
  seed : Int,
) -> EnergyValleyWorldDeltaLedger {
  {
    schema_version: energy_valley_world_delta_schema(),
    base_blueprint_id: "blueprint/wenyu-energy-valley",
    base_blueprint_digest: energy_valley_base_blueprint_digest_for_seed(seed),
    revision: 1,
    budget: 2400,
    operations: [],
    content_digest: Some(energy_valley_saved_operations_digest([])),
    next_authored_building_sequence: 1,
  }
}

///|
fn energy_valley_world_delta_targets_seed(
  ledger : EnergyValleyWorldDeltaLedger,
  seed : Int,
) -> Bool {
  ledger.base_blueprint_id == "blueprint/wenyu-energy-valley" &&
  ledger.base_blueprint_digest ==
  energy_valley_base_blueprint_digest_for_seed(seed)
}

///|
fn energy_valley_world_delta_valid_for_seed(
  ledger : EnergyValleyWorldDeltaLedger,
  seed : Int,
) -> Bool {
  let base = energy_valley_base_contract_world_for_seed(seed)
  let delta = energy_valley_contract_world_delta(ledger)
  delta.targets(base) &&
  !@energy_valley_contract.has_errors(
    @energy_valley_contract.validate_world_delta(delta, base_world=Some(base)),
  )
}

///|
fn energy_valley_model_delta_projection(
  model : Model,
) -> EnergyValleyWorldDeltaProjection {
  energy_valley_project_contract_world_delta(
    energy_valley_contract_world_delta(model.energy_world_delta),
  )
}

///|
fn energy_valley_model_buildings(model : Model) -> Array[GoldenValleyBuilding] {
  energy_valley_model_delta_projection(model).buildings
}

///|
fn energy_valley_model_roads(model : Model) -> Array[String] {
  energy_valley_model_delta_projection(model).roads
}

///|
fn energy_valley_model_parks(model : Model) -> Array[String] {
  energy_valley_model_delta_projection(model).parks
}

///|
fn energy_valley_model_budget(model : Model) -> Int {
  model.energy_world_delta.budget.max(0)
}

///|
fn energy_valley_model_next_authored_building_sequence(model : Model) -> Int {
  model.energy_world_delta.next_authored_building_sequence.max(1)
}

///|
fn energy_valley_model_append_delta_operations(
  model : Model,
  operations : Array[SavedWorldDeltaOperation],
  budget : Int,
  next_authored_building_sequence : Int,
) -> Model {
  ignore(next_authored_building_sequence)
  let mut next = model
  let mut first_spend = budget - energy_valley_model_budget(model)
  let building_aliases : Map[String, String] = Map([])
  for operation in operations {
    match operation {
      AddBuilding(value) => {
        let (updated, identified) = town_life_world_add_building(
          next,
          value.building,
          first_spend,
        )
        next = updated
        building_aliases[value.id] = golden_valley_nonempty_authored_id(
          identified,
        ).unwrap()
        first_spend = 0
      }
      MoveBuilding(value) => {
        let resolved_id = building_aliases.get(value.id).unwrap_or(value.id)
        let buildings = energy_valley_model_buildings(next)
        let current = match
          buildings.search_by(building => {
            golden_valley_nonempty_authored_id(building) == Some(resolved_id)
          }) {
          Some(index) => Some(buildings[index])
          None =>
            if buildings.length() == 1 {
              Some(buildings[0])
            } else {
              None
            }
        }
        match current {
          Some(building) => {
            let physical_id = golden_valley_nonempty_authored_id(building).unwrap_or(
              resolved_id,
            )
            next = town_life_world_move_entity(
              next,
              WorldBuilding,
              physical_id,
              WorldBuildingPayload({
                ..building,
                x: value.x,
                y: value.y,
                width: value.width,
                depth: value.depth,
                entrance_x: value.entrance_x,
                entrance_y: value.entrance_y,
              }),
            )
          }
          None => ()
        }
      }
      DeleteBuilding(value) =>
        next = town_life_world_delete_entity(
          next,
          WorldBuilding,
          building_aliases.get(value.id).unwrap_or(value.id),
          (budget - energy_valley_model_budget(next)).max(0),
        )
      AddRoad(value) | MoveRoad(value) =>
        for point in value.path {
          let entity_id = "road-cell-\{point.x}-\{point.y}"
          if town_life_world_current_incarnation(next, WorldRoadCell, entity_id)
            is None {
            next = town_life_world_add_road_cell(next, point, first_spend)
            first_spend = 0
          }
        }
      DeleteRoad(_) => ()
      AddPark(value) => {
        next = town_life_world_add_park(next, value.x, value.y, first_spend)
        first_spend = 0
      }
      MovePark(value) =>
        next = town_life_world_move_entity(
          next,
          WorldPark,
          value.id,
          WorldParkPayload(value),
        )
      DeletePark(value) =>
        next = town_life_world_delete_entity(next, WorldPark, value.id, 0)
    }
  }
  next
}

///|
fn energy_valley_model_add_building_delta(
  model : Model,
  building : GoldenValleyBuilding,
  budget : Int,
  next_authored_building_sequence : Int,
) -> Model {
  energy_valley_model_add_building_delta_with_identity(
    model, building, budget, next_authored_building_sequence,
  ).0
}

///|
fn energy_valley_model_add_building_delta_with_identity(
  model : Model,
  building : GoldenValleyBuilding,
  budget : Int,
  next_authored_building_sequence : Int,
) -> (Model, GoldenValleyBuilding) {
  ignore(next_authored_building_sequence)
  town_life_world_add_building(
    model,
    building,
    budget - energy_valley_model_budget(model),
  )
}

///|
fn energy_valley_model_delete_building_delta(
  model : Model,
  building : GoldenValleyBuilding,
  budget : Int,
) -> Model {
  match golden_valley_nonempty_authored_id(building) {
    Some(id) =>
      town_life_world_delete_entity(
        model,
        WorldBuilding,
        id,
        budget - energy_valley_model_budget(model),
      )
    None => model
  }
}

///|
fn energy_valley_model_add_park_delta(
  model : Model,
  x : Int,
  y : Int,
  budget : Int,
) -> Model {
  town_life_world_add_park(
    model,
    x,
    y,
    budget - energy_valley_model_budget(model),
  )
}

///|
fn energy_valley_model_delete_park_delta(
  model : Model,
  x : Int,
  y : Int,
  budget : Int,
) -> Model {
  ignore(budget)
  town_life_world_delete_entity(
    model,
    WorldPark,
    energy_valley_saved_park_id(x, y),
    0,
  )
}

///|
fn energy_valley_active_saved_roads(
  ledger : EnergyValleyWorldDeltaLedger,
) -> Map[String, SavedWorldDeltaRoad] {
  let roads : Map[String, SavedWorldDeltaRoad] = Map([])
  for operation in ledger.operations {
    match operation {
      AddRoad(value) => roads[value.id] = value
      MoveRoad(value) => if roads.contains(value.id) { roads[value.id] = value }
      DeleteRoad(value) => roads.remove(value.id)
      AddBuilding(_)
      | MoveBuilding(_)
      | DeleteBuilding(_)
      | AddPark(_)
      | MovePark(_)
      | DeletePark(_) => ()
    }
  }
  roads
}

///|
fn energy_valley_model_replace_roads_delta(
  model : Model,
  encoded_roads : Array[String],
  budget : Int,
) -> Model {
  let current = energy_valley_model_roads(model)
  let mut next = model
  let added = encoded_roads.filter(key => !current.contains(key))
  let mut remaining_delta = budget - energy_valley_model_budget(model)
  for key in added {
    match energy_valley_parse_saved_tile(key) {
      Some((x, y)) => {
        // Normal interaction adds one cell. If a compatibility caller adds a
        // batch, its total debit stays attached to the first immutable cell
        // event and the canonical budget remains exact.
        next = town_life_world_add_road_cell(next, { x, y }, remaining_delta)
        remaining_delta = 0
      }
      None => ()
    }
  }
  for key in current {
    if !encoded_roads.contains(key) {
      match energy_valley_parse_saved_tile(key) {
        Some((x, y)) =>
          next = town_life_world_delete_entity(
            next,
            WorldRoadCell,
            "road-cell-\{x}-\{y}",
            0,
          )
        None => ()
      }
    }
  }
  next
}

///|
fn energy_valley_validated_world_delta_projection(
  model : Model,
  seed : Int,
) -> EnergyValleyWorldDeltaProjection {
  let base = energy_valley_base_contract_world_for_seed(seed)
  let delta = energy_valley_contract_world_delta_for_model(model, seed)
  let issues = @energy_valley_contract.validate_world_delta(
    delta,
    base_world=Some(base),
  )
  if @energy_valley_contract.has_errors(issues) {
    { buildings: [], roads: [], parks: [] }
  } else {
    energy_valley_project_contract_world_delta(delta)
  }
}
