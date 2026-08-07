///|
/// Stable, renderer-neutral-enough diagnostic projected for Map Lab. It is
/// package-local while the compiler contract is proven, but contains no Canvas
/// or DOM state and can move into the contract unchanged later.
priv struct EcosystemPlacementRejection {
  id : String
  entity_kind : String
  source_id : String
  x : Double
  y : Double
  width : Double
  depth : Double
  reason_code : String
  reason : String
  provenance : String
} derive(Debug, Eq)

///|
fn ecosystem_compiler_append_rejection(
  result : Array[EcosystemPlacementRejection],
  entity_kind : String,
  source_id : String,
  footprint : EcosystemFootprint,
  reason_code : String,
  reason : String,
  provenance : String,
) -> Unit {
  result.push({
    id: ecosystem_scoped_id(
      "placement-rejection",
      "\{reason_code}-\{source_id}",
    ),
    entity_kind,
    source_id,
    x: footprint.x.to_double(),
    y: footprint.y.to_double(),
    width: footprint.width.to_double(),
    depth: footprint.depth.to_double(),
    reason_code,
    reason,
    provenance,
  })
}

///|
fn ecosystem_compiler_footprint_inside_bounds(
  footprint : EcosystemFootprint,
  cols : Int,
  rows : Int,
) -> Bool {
  footprint.x >= 0 &&
  footprint.y >= 0 &&
  footprint.width > 0 &&
  footprint.depth > 0 &&
  footprint.x + footprint.width <= cols &&
  footprint.y + footprint.depth <= rows
}

///|
fn ecosystem_compiler_place_provenance(place : EcosystemPlace) -> String {
  if place.kind is EcosystemCustomBuilding {
    "user-delta"
  } else {
    "wenyu-reference"
  }
}

///|
fn ecosystem_compiler_rejected_placements(
  model : Model,
  seed : Int,
) -> Array[EcosystemPlacementRejection] {
  let snapshot = ecosystem_cached_world_snapshot(model, seed)
  let exact_world = golden_valley_world(seed)
  let roads = ecosystem_parcel_road_lookup(snapshot)
  let result : Array[EcosystemPlacementRejection] = []
  let planning_blocks = ecosystem_parcel_planning_blocks(snapshot, seed)
  if reference_road_graph_snapshot_ready() && planning_blocks.length() != 75 {
    ecosystem_compiler_append_rejection(
      result,
      "compiler",
      "wenyu-road-enclosures",
      { x: 0, y: 0, width: snapshot.cols, depth: snapshot.rows },
      "road-block-count-mismatch",
      "Authoritative Wenyu road rows did not compile to exactly 75 enclosed blocks.",
      "wenyu-reference",
    )
  }
  for block in planning_blocks {
    if block.fragments.is_empty() {
      ecosystem_compiler_append_rejection(
        result,
        "land-block",
        "wenyu-\{block.ordinal}-\{block.canonical_anchor.x}-\{block.canonical_anchor.y}",
        {
          x: block.canonical_anchor.x,
          y: block.canonical_anchor.y,
          width: 1,
          depth: 1,
        },
        "no-buildable-region",
        "Road-enclosed block contains no road- and water-free buildable fragment.",
        "wenyu-reference",
      )
    }
  }
  for place in snapshot.places {
    if place.kind != EcosystemCivicBuilding &&
      place.kind != EcosystemAmbientBuilding &&
      place.kind != EcosystemCustomBuilding {
      continue
    }
    let provenance = ecosystem_compiler_place_provenance(place)
    if !ecosystem_compiler_footprint_inside_bounds(
        place.footprint,
        snapshot.cols,
        snapshot.rows,
      ) {
      ecosystem_compiler_append_rejection(
        result,
        "building",
        place.id,
        place.footprint,
        "outside-world-bounds",
        "Building footprint extends beyond the compiled town bounds.",
        provenance,
      )
      continue
    }
    let mut road_overlap = false
    let mut water_overlap = false
    for y in place.footprint.y..<(place.footprint.y + place.footprint.depth) {
      for x in place.footprint.x..<(place.footprint.x + place.footprint.width) {
        if roads.contains(golden_valley_tile_key(x, y)) {
          road_overlap = true
        }
        let terrain = exact_world.tiles[y][x].terrain
        if terrain == "water" || terrain == "wetland" {
          water_overlap = true
        }
      }
    }
    if road_overlap {
      ecosystem_compiler_append_rejection(
        result,
        "building",
        place.id,
        place.footprint,
        "road-overlap",
        "Building footprint overlaps the authoritative typed road graph.",
        provenance,
      )
    }
    if water_overlap {
      ecosystem_compiler_append_rejection(
        result,
        "building",
        place.id,
        place.footprint,
        "water-overlap",
        "Building footprint overlaps authored water or wetland.",
        provenance,
      )
    }
  }
  result.sort_by((left, right) => left.id.compare(right.id))
  result
}
