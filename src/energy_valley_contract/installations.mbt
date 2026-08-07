///|
/// Renderer-neutral public-realm object kinds. Buildings and stations remain
/// `Place` values; these objects describe the smaller or linear features that
/// make the space around them legible and interactive.
pub(all) enum InstallationKind {
  MetroAlignment
  Boardwalk
  Tree
  Light
  Bench
  TransitEntrance
  Signage
  Custom(String)
} derive(Debug, Eq)

///|
/// Geometry is explicit so Map Lab and renderers never need to infer whether
/// an installation is a point fixture, a linear alignment, or an area.
pub(all) enum InstallationGeometry {
  AtPoint(WorldPoint)
  AlongPath(ReadOnlyArray[WorldPoint])
  WithinArea(Polygon)
} derive(Debug, Eq)

///|
pub fn installation_point(position : WorldPoint) -> InstallationGeometry {
  AtPoint(position)
}

///|
pub fn installation_path(
  points : ArrayView[WorldPoint],
) -> InstallationGeometry {
  AlongPath(freeze(points))
}

///|
pub fn installation_area(boundary : Polygon) -> InstallationGeometry {
  WithinArea(boundary)
}

///|
/// A semantic public-realm object owned by `CompiledTownWorld`.
pub(all) struct Installation {
  id : StableId
  label : String
  kind : InstallationKind
  geometry : InstallationGeometry
  owner_place_id : StableId?
  road_segment_ids : ReadOnlyArray[StableId]
  attention_target_id : StableId?
  interactive : Bool
  tags : ReadOnlyArray[String]
  provenance : Provenance
} derive(Debug, Eq)

///|
pub fn installation(
  id : StableId,
  label : String,
  kind : InstallationKind,
  geometry : InstallationGeometry,
  provenance : Provenance,
  owner_place_id? : StableId? = None,
  road_segment_ids? : ArrayView[StableId] = [],
  attention_target_id? : StableId? = None,
  interactive? : Bool = false,
  tags? : ArrayView[String] = [],
) -> Installation {
  {
    id,
    label,
    kind,
    geometry,
    owner_place_id,
    road_segment_ids: freeze(road_segment_ids),
    attention_target_id,
    interactive,
    tags: freeze(tags),
    provenance,
  }
}

///|
/// A stable anchor for labels, selection, and fallback rendering.
pub fn Installation::representative_position(
  self : Installation,
) -> WorldPoint? {
  match self.geometry {
    AtPoint(position) => Some(position)
    AlongPath(points) => points.get(0)
    WithinArea(boundary) => boundary.vertices.get(0)
  }
}
