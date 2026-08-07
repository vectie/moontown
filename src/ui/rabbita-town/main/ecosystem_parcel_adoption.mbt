///|
/// Typed road lookup shared by block fragmentation and frontage compilation.
fn ecosystem_parcel_road_lookup(
  snapshot : EcosystemWorldSnapshot,
) -> Map[String, EcosystemRoadCell] {
  let result : Map[String, EcosystemRoadCell] = Map([])
  for road in snapshot.roads {
    result[golden_valley_tile_key(road.x, road.y)] = road
  }
  result
}

///|
/// Player parks remain exact semantic delta cells inside their stable authored
/// road block. Their local land use is carried by BuildableRegion.
fn ecosystem_parcel_park_lookup(
  snapshot : EcosystemWorldSnapshot,
) -> Map[String, Unit] {
  let result : Map[String, Unit] = Map([])
  for place in snapshot.places {
    if place.style == "park" &&
      place.footprint.width == 1 &&
      place.footprint.depth == 1 {
      result[golden_valley_tile_key(place.footprint.x, place.footprint.y)] = ()
    }
  }
  result
}

///|
fn ecosystem_parcel_segment_id(
  x : Int,
  y : Int,
  neighbor_x : Int,
  neighbor_y : Int,
) -> @energy_valley_contract.StableId {
  if neighbor_x < x || neighbor_y < y {
    ecosystem_contract_scoped_id(
      "road-segment",
      "\{neighbor_x}-\{neighbor_y}-\{x}-\{y}",
    )
  } else {
    ecosystem_contract_scoped_id(
      "road-segment",
      "\{x}-\{y}-\{neighbor_x}-\{neighbor_y}",
    )
  }
}

///|
fn ecosystem_parcel_append_incident_segments(
  result : Array[@energy_valley_contract.StableId],
  seen : Map[@energy_valley_contract.StableId, Unit],
  road_lookup : Map[String, EcosystemRoadCell],
  road_network : @energy_valley_contract.RoadNetwork,
  x : Int,
  y : Int,
) -> Unit {
  if !road_lookup.contains(golden_valley_tile_key(x, y)) {
    return
  }
  for neighbor in [(x - 1, y), (x, y - 1), (x + 1, y), (x, y + 1)] {
    if !road_lookup.contains(golden_valley_tile_key(neighbor.0, neighbor.1)) {
      continue
    }
    let id = ecosystem_parcel_segment_id(x, y, neighbor.0, neighbor.1)
    if !seen.contains(id) && road_network.find_segment(id) is Some(_) {
      seen[id] = ()
      result.push(id)
    }
  }
}

///|
fn ecosystem_parcel_frontage_segments(
  road_lookup : Map[String, EcosystemRoadCell],
  road_network : @energy_valley_contract.RoadNetwork,
  block : EcosystemPlanningBlock,
) -> Array[@energy_valley_contract.StableId] {
  let result : Array[@energy_valley_contract.StableId] = []
  let seen : Map[@energy_valley_contract.StableId, Unit] = Map([])
  for cell in block.cells {
    for delta in [(0, -1), (1, 0), (0, 1), (-1, 0)] {
      ecosystem_parcel_append_incident_segments(
        result,
        seen,
        road_lookup,
        road_network,
        cell.x + delta.0,
        cell.y + delta.1,
      )
    }
  }
  result.sort_by((left, right) => left.to_string().compare(right.to_string()))
  result
}

///|
fn ecosystem_parcel_block_polygon(
  block : EcosystemPlanningBlock,
) -> @energy_valley_contract.Polygon {
  block.boundary
}

///|
fn ecosystem_parcel_fragment_polygon(
  fragment : EcosystemPlanningFragment,
) -> @energy_valley_contract.Polygon {
  let left = fragment.x.to_double()
  let top = fragment.y.to_double()
  let right = (fragment.x + fragment.width).to_double()
  let bottom = (fragment.y + fragment.depth).to_double()
  @energy_valley_contract.polygon([
    @energy_valley_contract.world_point(left, top),
    @energy_valley_contract.world_point(right, top),
    @energy_valley_contract.world_point(right, bottom),
    @energy_valley_contract.world_point(left, bottom),
  ])
}

///|
fn ecosystem_parcel_program_catalog() -> Array[
  @energy_valley_contract.ParcelProgram,
] {
  let result : Array[@energy_valley_contract.ParcelProgram] = []
  fn add(
    result : Array[@energy_valley_contract.ParcelProgram],
    key : String,
    label : String,
    land_use : @energy_valley_contract.LandUse,
    frontage : Bool,
    weight : Int,
  ) -> Unit {
    result.push(
      @energy_valley_contract.parcel_program(
        ecosystem_contract_scoped_id("parcel-program", key),
        label,
        [land_use],
        minimum_area_sqm=1.0,
        requires_frontage=frontage,
        weight~,
      ),
    )
  }
  add(
    result,
    "civic-hall",
    "Civic hall",
    @energy_valley_contract.Civic,
    true,
    70,
  )
  add(
    result,
    "civic-court",
    "Civic court",
    @energy_valley_contract.Civic,
    false,
    30,
  )
  add(
    result,
    "research-lab",
    "Research lab",
    @energy_valley_contract.Research,
    true,
    65,
  )
  add(
    result,
    "research-garden",
    "Research garden",
    @energy_valley_contract.Research,
    false,
    35,
  )
  add(
    result,
    "street-homes",
    "Street homes",
    @energy_valley_contract.Residential,
    true,
    60,
  )
  add(
    result,
    "residential-court",
    "Residential court",
    @energy_valley_contract.Residential,
    false,
    40,
  )
  add(
    result,
    "valley-market",
    "Valley market",
    @energy_valley_contract.MixedUse,
    true,
    65,
  )
  add(
    result,
    "mixed-court",
    "Mixed-use court",
    @energy_valley_contract.MixedUse,
    false,
    35,
  )
  add(
    result,
    "park-pavilion",
    "Park pavilion",
    @energy_valley_contract.Park,
    true,
    35,
  )
  add(
    result,
    "park-commons",
    "Park commons",
    @energy_valley_contract.Park,
    false,
    65,
  )
  add(
    result,
    "waterfront-pavilion",
    "Waterfront pavilion",
    @energy_valley_contract.Waterfront,
    true,
    55,
  )
  add(
    result,
    "waterfront-walk",
    "Waterfront walk",
    @energy_valley_contract.Waterfront,
    false,
    45,
  )
  add(
    result,
    "transit-hall",
    "Transit hall",
    @energy_valley_contract.Transit,
    true,
    70,
  )
  add(
    result,
    "transit-court",
    "Transit court",
    @energy_valley_contract.Transit,
    false,
    30,
  )
  add(
    result,
    "utility-yard",
    "Utility yard",
    @energy_valley_contract.Utility,
    true,
    55,
  )
  add(
    result,
    "utility-garden",
    "Utility garden",
    @energy_valley_contract.Utility,
    false,
    45,
  )
  result
}

///|
fn ecosystem_parcel_block_seeds(
  snapshot : EcosystemWorldSnapshot,
  road_network : @energy_valley_contract.RoadNetwork,
  seed : Int,
) -> Array[@energy_valley_contract.LandBlockSeed] {
  let result : Array[@energy_valley_contract.LandBlockSeed] = []
  let source = @energy_valley_contract.provenance(
    "wenyu-reference-road-enclosures",
    "v2",
    @energy_valley_contract.WenyuReference,
    @energy_valley_contract.Fixed,
  )
  let road_lookup = ecosystem_parcel_road_lookup(snapshot)
  for block in ecosystem_parcel_planning_blocks(snapshot, seed) {
    let block_key = "wenyu-\{block.ordinal}-\{block.canonical_anchor.x}-\{block.canonical_anchor.y}"
    let parcelable = !block.fragments.is_empty()
    let buildable_regions : Array[@energy_valley_contract.BuildableRegion] = []
    for fragment in block.fragments {
      let provenance = if fragment.custom {
        @energy_valley_contract.provenance(
          "moontown-world-delta",
          "v1",
          @energy_valley_contract.UserDelta,
          @energy_valley_contract.Bounded,
        )
      } else {
        source
      }
      buildable_regions.push(
        @energy_valley_contract.buildable_region(
          ecosystem_contract_scoped_id(
            "buildable-region",
            "\{block_key}-\{fragment.id_key}",
          ),
          ecosystem_parcel_fragment_polygon(fragment),
          fragment.land_use,
          provenance,
        ),
      )
    }
    result.push(
      @energy_valley_contract.land_block_seed(
        ecosystem_contract_scoped_id("land-block", block_key),
        ecosystem_parcel_block_polygon(block),
        block.land_use,
        ecosystem_parcel_frontage_segments(road_lookup, road_network, block),
        @energy_valley_contract.Fixed,
        source,
        @energy_valley_contract.parcel_grammar(
          block.target_parcels,
          split_axis=@energy_valley_contract.LongestAxis,
          variation=@energy_valley_contract.Bounded,
          minimum_area_sqm=1.0,
        ),
        buildable_regions~,
        parcelable~,
      ),
    )
  }
  result
}

///|
/// Package-level migration seam called by `ecosystem_contract_world_from_snapshot`
/// after it has built the exact typed road network. No renderer-local place
/// rectangle participates in block generation.
fn ecosystem_contract_parcel_plan(
  snapshot : EcosystemWorldSnapshot,
  road_network : @energy_valley_contract.RoadNetwork,
  seed : Int,
) -> @energy_valley_contract.ParcelPlan {
  match
    @energy_valley_contract.compile_parcel_plan(
      "wenyu-parcel-adoption-v2",
      seed,
      road_network,
      ecosystem_parcel_block_seeds(snapshot, road_network, seed),
      ecosystem_parcel_program_catalog(),
    ) {
    Ok(plan) => plan
    Err(error) => abort("parcel adoption invariant failed: \{Repr(error)}")
  }
}
