///|
pub(all) enum TerrainKind {
  Meadow
  Woodland
  Water
  Wetland
  Paving
  Restricted
  Custom(String)
} derive(Debug, Eq)

///|
pub(all) struct TerrainRegion {
  id : StableId
  kind : TerrainKind
  boundary : Polygon
  walkable : Bool
  provenance : Provenance
} derive(Debug, Eq)

///|
pub fn terrain_region(
  id : StableId,
  kind : TerrainKind,
  boundary : Polygon,
  walkable : Bool,
  provenance : Provenance,
) -> TerrainRegion {
  { id, kind, boundary, walkable, provenance }
}
