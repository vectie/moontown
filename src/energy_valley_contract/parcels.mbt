///|
pub(all) struct Polygon {
  vertices : ReadOnlyArray[WorldPoint]
} derive(Debug, Eq)

///|
pub fn polygon(vertices : ArrayView[WorldPoint]) -> Polygon {
  { vertices: freeze(vertices) }
}

///|
pub fn Polygon::is_well_formed(self : Polygon) -> Bool {
  self.vertices.length() >= 3
}

///|
pub(all) enum LandUse {
  Civic
  Research
  Residential
  MixedUse
  Park
  Waterfront
  Transit
  Utility
  Custom(String)
} derive(Debug, Eq)

///|
/// One buildable fragment inside a stable road-derived land block. Fragments
/// allow water, retained roads, and distinct park/research uses to coexist
/// without splitting the authored top-level block identity.
pub(all) struct BuildableRegion {
  id : StableId
  boundary : Polygon
  land_use : LandUse
  provenance : Provenance
} derive(Debug, Eq)

///|
pub fn buildable_region(
  id : StableId,
  boundary : Polygon,
  land_use : LandUse,
  provenance : Provenance,
) -> BuildableRegion {
  { id, boundary, land_use, provenance }
}

///|
pub(all) struct LandBlock {
  id : StableId
  boundary : Polygon
  land_use : LandUse
  parcel_ids : ReadOnlyArray[StableId]
  frontage_segment_ids : ReadOnlyArray[StableId]
  preservation : PreservationLevel
  provenance : Provenance
  buildable_regions : ReadOnlyArray[BuildableRegion]
  parcelable : Bool
} derive(Debug, Eq)

///|
pub fn land_block(
  id : StableId,
  boundary : Polygon,
  land_use : LandUse,
  parcel_ids : ArrayView[StableId],
  frontage_segment_ids : ArrayView[StableId],
  preservation : PreservationLevel,
  provenance : Provenance,
  buildable_regions? : ArrayView[BuildableRegion] = [],
  parcelable? : Bool = true,
) -> LandBlock {
  {
    id,
    boundary,
    land_use,
    parcel_ids: freeze(parcel_ids),
    frontage_segment_ids: freeze(frontage_segment_ids),
    preservation,
    provenance,
    buildable_regions: freeze(buildable_regions),
    parcelable,
  }
}

///|
pub fn LandBlock::effective_buildable_regions(
  self : LandBlock,
) -> ReadOnlyArray[BuildableRegion] {
  if !self.parcelable {
    []
  } else if self.buildable_regions.is_empty() {
    [
      {
        id: self.id,
        boundary: self.boundary,
        land_use: self.land_use,
        provenance: self.provenance,
      },
    ]
  } else {
    self.buildable_regions
  }
}

///|
pub(all) struct Parcel {
  id : StableId
  block_id : StableId
  boundary : Polygon
  land_use : LandUse
  frontage_segment_ids : ReadOnlyArray[StableId]
  allowed_programs : ReadOnlyArray[String]
  preservation : PreservationLevel
  provenance : Provenance
} derive(Debug, Eq)

///|
pub fn parcel(
  id : StableId,
  block_id : StableId,
  boundary : Polygon,
  land_use : LandUse,
  frontage_segment_ids : ArrayView[StableId],
  allowed_programs : ArrayView[String],
  preservation : PreservationLevel,
  provenance : Provenance,
) -> Parcel {
  {
    id,
    block_id,
    boundary,
    land_use,
    frontage_segment_ids: freeze(frontage_segment_ids),
    allowed_programs: freeze(allowed_programs),
    preservation,
    provenance,
  }
}
