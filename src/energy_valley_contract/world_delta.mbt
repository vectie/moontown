///|
pub(all) enum WorldDeltaEntityKind {
  DeltaBuilding
  DeltaRoad
  DeltaPark
} derive(Debug, Eq)

///|
/// Complete data required to add a player building before the world compiler
/// derives portals, interaction slots, and renderer-specific geometry.
pub(all) struct BuildingAddition {
  id : StableId
  name : String
  /// Optional runtime/module identity retained by collected or imported
  /// knowledge buildings. It is presentation-neutral authored metadata.
  module_key : String?
  parcel_id : StableId?
  grid_anchor : GridPosition
  /// Authored entrance evidence, when the source supplied one. The compiler
  /// may still derive a portal when this is absent.
  entrance_grid : GridPosition?
  footprint : Polygon
  profile : BuildingProfile
  provenance : Provenance
} derive(Debug, Eq)

///|
pub fn building_addition(
  id : StableId,
  name : String,
  grid_anchor : GridPosition,
  footprint : Polygon,
  profile : BuildingProfile,
  provenance : Provenance,
  parcel_id? : StableId? = None,
  module_key? : String? = None,
  entrance_grid? : GridPosition? = None,
) -> BuildingAddition {
  {
    id,
    name,
    module_key,
    parcel_id,
    grid_anchor,
    entrance_grid,
    footprint,
    profile,
    provenance,
  }
}

///|
pub(all) struct BuildingMovement {
  id : StableId
  grid_anchor : GridPosition
  entrance_grid : GridPosition?
  footprint : Polygon
  provenance : Provenance
} derive(Debug, Eq)

///|
pub fn building_movement(
  id : StableId,
  grid_anchor : GridPosition,
  footprint : Polygon,
  provenance : Provenance,
  entrance_grid? : GridPosition? = None,
) -> BuildingMovement {
  { id, grid_anchor, entrance_grid, footprint, provenance }
}

///|
pub(all) struct BuildingDeletion {
  id : StableId
  provenance : Provenance
} derive(Debug, Eq)

///|
pub fn building_deletion(
  id : StableId,
  provenance : Provenance,
) -> BuildingDeletion {
  { id, provenance }
}

///|
/// A grid-level road edit. Compilation resolves it into road nodes, segments,
/// world-space centerlines, and connectivity.
pub(all) struct RoadAddition {
  id : StableId
  grid_path : ReadOnlyArray[GridPosition]
  road_class : RoadClass
  width_meters : Double
  mobility : ReadOnlyArray[MobilityMode]
  provenance : Provenance
} derive(Debug, Eq)

///|
pub fn road_addition(
  id : StableId,
  grid_path : ArrayView[GridPosition],
  road_class : RoadClass,
  width_meters : Double,
  mobility : ArrayView[MobilityMode],
  provenance : Provenance,
) -> RoadAddition {
  {
    id,
    grid_path: freeze(grid_path),
    road_class,
    width_meters,
    mobility: freeze(mobility),
    provenance,
  }
}

///|
pub(all) struct RoadMovement {
  id : StableId
  grid_path : ReadOnlyArray[GridPosition]
  provenance : Provenance
} derive(Debug, Eq)

///|
pub fn road_movement(
  id : StableId,
  grid_path : ArrayView[GridPosition],
  provenance : Provenance,
) -> RoadMovement {
  { id, grid_path: freeze(grid_path), provenance }
}

///|
pub(all) struct RoadDeletion {
  id : StableId
  provenance : Provenance
} derive(Debug, Eq)

///|
pub fn road_deletion(id : StableId, provenance : Provenance) -> RoadDeletion {
  { id, provenance }
}

///|
pub(all) struct ParkAddition {
  id : StableId
  label : String
  parcel_id : StableId?
  grid_anchor : GridPosition
  boundary : Polygon
  provenance : Provenance
} derive(Debug, Eq)

///|
pub fn park_addition(
  id : StableId,
  label : String,
  grid_anchor : GridPosition,
  boundary : Polygon,
  provenance : Provenance,
  parcel_id? : StableId? = None,
) -> ParkAddition {
  { id, label, parcel_id, grid_anchor, boundary, provenance }
}

///|
pub(all) struct ParkMovement {
  id : StableId
  grid_anchor : GridPosition
  boundary : Polygon
  provenance : Provenance
} derive(Debug, Eq)

///|
pub fn park_movement(
  id : StableId,
  grid_anchor : GridPosition,
  boundary : Polygon,
  provenance : Provenance,
) -> ParkMovement {
  { id, grid_anchor, boundary, provenance }
}

///|
pub(all) struct ParkDeletion {
  id : StableId
  provenance : Provenance
} derive(Debug, Eq)

///|
pub fn park_deletion(id : StableId, provenance : Provenance) -> ParkDeletion {
  { id, provenance }
}

///|
pub(all) enum WorldDeltaOperation {
  AddBuilding(BuildingAddition)
  MoveBuilding(BuildingMovement)
  DeleteBuilding(BuildingDeletion)
  AddRoad(RoadAddition)
  MoveRoad(RoadMovement)
  DeleteRoad(RoadDeletion)
  AddPark(ParkAddition)
  MovePark(ParkMovement)
  DeletePark(ParkDeletion)
} derive(Debug, Eq)

///|
pub fn WorldDeltaOperation::entity_id(self : WorldDeltaOperation) -> StableId {
  match self {
    AddBuilding(value) => value.id
    MoveBuilding(value) => value.id
    DeleteBuilding(value) => value.id
    AddRoad(value) => value.id
    MoveRoad(value) => value.id
    DeleteRoad(value) => value.id
    AddPark(value) => value.id
    MovePark(value) => value.id
    DeletePark(value) => value.id
  }
}

///|
pub fn WorldDeltaOperation::entity_kind(
  self : WorldDeltaOperation,
) -> WorldDeltaEntityKind {
  match self {
    AddBuilding(_) | MoveBuilding(_) | DeleteBuilding(_) => DeltaBuilding
    AddRoad(_) | MoveRoad(_) | DeleteRoad(_) => DeltaRoad
    AddPark(_) | MovePark(_) | DeletePark(_) => DeltaPark
  }
}

///|
pub fn WorldDeltaOperation::provenance(
  self : WorldDeltaOperation,
) -> Provenance {
  match self {
    AddBuilding(value) => value.provenance
    MoveBuilding(value) => value.provenance
    DeleteBuilding(value) => value.provenance
    AddRoad(value) => value.provenance
    MoveRoad(value) => value.provenance
    DeleteRoad(value) => value.provenance
    AddPark(value) => value.provenance
    MovePark(value) => value.provenance
    DeletePark(value) => value.provenance
  }
}

///|
/// Versioned, blueprint-bound user edits. `revision` is monotonic within one
/// saved town; it is not a simulation tick.
pub(all) struct WorldDelta {
  schema_version : String
  base_blueprint_id : StableId
  base_blueprint_digest : String
  revision : Int
  operations : ReadOnlyArray[WorldDeltaOperation]
} derive(Debug, Eq)

///|
pub fn world_delta(
  schema_version : String,
  base_blueprint_id : StableId,
  base_blueprint_digest : String,
  revision : Int,
  operations : ArrayView[WorldDeltaOperation],
) -> WorldDelta {
  {
    schema_version,
    base_blueprint_id,
    base_blueprint_digest,
    revision,
    operations: freeze(operations),
  }
}

///|
pub fn WorldDelta::targets(
  self : WorldDelta,
  world : CompiledTownWorld,
) -> Bool {
  self.base_blueprint_id == world.blueprint_id &&
  self.base_blueprint_digest == world.blueprint_digest
}

///|
pub fn WorldDelta::operations_for(
  self : WorldDelta,
  entity_id : StableId,
) -> ReadOnlyArray[WorldDeltaOperation] {
  self.operations.filter(operation => operation.entity_id() == entity_id)
}

///|
pub fn WorldDelta::latest_operation_for(
  self : WorldDelta,
  entity_id : StableId,
) -> WorldDeltaOperation? {
  for index = self.operations.length() - 1; index >= 0; index = index - 1 {
    let operation = self.operations[index]
    if operation.entity_id() == entity_id {
      return Some(operation)
    }
  }
  None
}

///|
/// Removes repeated adjacent grid points while preserving the authored route.
pub fn normalize_grid_path(
  path : ArrayView[GridPosition],
) -> ReadOnlyArray[GridPosition] {
  let normalized : Array[GridPosition] = []
  for point in path {
    if normalized.last() != Some(point) {
      normalized.push(point)
    }
  }
  freeze(normalized)
}

///|
/// Removes repeated adjacent vertices and a duplicated closing vertex. Polygon
/// closure remains implicit throughout the contract.
pub fn normalize_polygon(value : Polygon) -> Polygon {
  let normalized : Array[WorldPoint] = []
  for vertex in value.vertices {
    if normalized.last() != Some(vertex) {
      normalized.push(vertex)
    }
  }
  if normalized.length() > 1 && normalized.last() == normalized.get(0) {
    ignore(normalized.pop())
  }
  polygon(normalized)
}

///|
fn normalize_delta_operation(
  value : WorldDeltaOperation,
) -> WorldDeltaOperation {
  match value {
    AddBuilding(addition) =>
      AddBuilding({
        ..addition,
        footprint: normalize_polygon(addition.footprint),
      })
    MoveBuilding(movement) =>
      MoveBuilding({
        ..movement,
        footprint: normalize_polygon(movement.footprint),
      })
    AddRoad(addition) =>
      AddRoad({ ..addition, grid_path: normalize_grid_path(addition.grid_path) })
    MoveRoad(movement) =>
      MoveRoad({
        ..movement,
        grid_path: normalize_grid_path(movement.grid_path),
      })
    AddPark(addition) =>
      AddPark({ ..addition, boundary: normalize_polygon(addition.boundary) })
    MovePark(movement) =>
      MovePark({ ..movement, boundary: normalize_polygon(movement.boundary) })
    DeleteBuilding(_) | DeleteRoad(_) | DeletePark(_) => value
  }
}

///|
/// Produces a canonical, lossless persistence form: geometries are normalized
/// and exact adjacent duplicate operations are removed. It intentionally does
/// not collapse add/move/delete history because that would discard provenance.
pub fn WorldDelta::normalized(self : WorldDelta) -> WorldDelta {
  let operations : Array[WorldDeltaOperation] = []
  for value in self.operations {
    let normalized = normalize_delta_operation(value)
    if operations.last() != Some(normalized) {
      operations.push(normalized)
    }
  }
  { ..self, operations: freeze(operations) }
}
