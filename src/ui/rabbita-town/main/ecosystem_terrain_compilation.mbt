///|
/// Exact coarse terrain class for one raster tile. The key keeps provenance
/// and semantic distinctions that share a renderer color separate.
priv struct EcosystemTerrainCellClass {
  key : String
  kind : @energy_valley_contract.TerrainKind
  walkable : Bool
  custom : Bool
} derive(Eq)

///|
priv struct EcosystemTerrainRectangle {
  x : Int
  y : Int
  width : Int
  depth : Int
  cell_class : EcosystemTerrainCellClass
}

///|
fn ecosystem_terrain_custom_site_lookup(
  snapshot : EcosystemWorldSnapshot,
) -> Map[String, Bool] {
  let result : Map[String, Bool] = Map([])
  for place in snapshot.places {
    if place.kind is EcosystemCustomBuilding || place.style == "park" {
      for y in place.footprint.y..<(place.footprint.y + place.footprint.depth) {
        for x in place.footprint.x..<(place.footprint.x + place.footprint.width) {
          result[golden_valley_tile_key(x, y)] = true
        }
      }
    }
  }
  result
}

///|
fn ecosystem_terrain_cell_class(
  world : ExactEnergyValleyWorld,
  road_lookup : Map[String, EcosystemRoadCell],
  park_lookup : Map[String, Unit],
  custom_sites : Map[String, Bool],
  x : Int,
  y : Int,
) -> EcosystemTerrainCellClass {
  let key = golden_valley_tile_key(x, y)
  match road_lookup.get(key) {
    Some(road) =>
      {
        key: if road.bridge {
          "bridge-paving"
        } else {
          "road-paving"
        },
        kind: @energy_valley_contract.Paving,
        walkable: true,
        custom: road.custom,
      }
    None =>
      if park_lookup.contains(key) {
        {
          key: "park-meadow",
          kind: @energy_valley_contract.Meadow,
          walkable: true,
          custom: true,
        }
      } else if custom_sites.contains(key) {
        {
          key: "custom-site-paving",
          kind: @energy_valley_contract.Paving,
          walkable: true,
          custom: true,
        }
      } else {
        match world.tiles[y][x].terrain {
          "water" =>
            {
              key: "water",
              kind: @energy_valley_contract.Water,
              walkable: false,
              custom: false,
            }
          "wetland" =>
            {
              key: "wetland",
              kind: @energy_valley_contract.Wetland,
              walkable: false,
              custom: false,
            }
          "forest" =>
            {
              key: "woodland",
              kind: @energy_valley_contract.Woodland,
              walkable: true,
              custom: false,
            }
          "urban" | "plaza" =>
            {
              key: "paving",
              kind: @energy_valley_contract.Paving,
              walkable: true,
              custom: false,
            }
          "restricted" =>
            {
              key: "restricted",
              kind: @energy_valley_contract.Restricted,
              walkable: false,
              custom: false,
            }
          "grass" | "meadow" | "field" =>
            {
              key: "meadow",
              kind: @energy_valley_contract.Meadow,
              walkable: true,
              custom: false,
            }
          other =>
            {
              key: "custom-\{other}",
              kind: @energy_valley_contract.Custom(other),
              walkable: true,
              custom: false,
            }
        }
      }
  }
}

///|
fn ecosystem_terrain_rectangles(
  snapshot : EcosystemWorldSnapshot,
  seed : Int,
) -> Array[EcosystemTerrainRectangle] {
  let world = golden_valley_world(seed)
  let roads = ecosystem_parcel_road_lookup(snapshot)
  let parks = ecosystem_parcel_park_lookup(snapshot)
  let custom_sites = ecosystem_terrain_custom_site_lookup(snapshot)
  let classes = Array::makei(snapshot.rows, y => {
    Array::makei(snapshot.cols, x => {
      ecosystem_terrain_cell_class(world, roads, parks, custom_sites, x, y)
    })
  })
  let covered = Array::makei(snapshot.rows, _ => {
    Array::make(snapshot.cols, false)
  })
  let result : Array[EcosystemTerrainRectangle] = []
  for y in 0..<snapshot.rows {
    for x in 0..<snapshot.cols {
      if covered[y][x] {
        continue
      }
      let cell_class = classes[y][x]
      let mut width = 0
      while x + width < snapshot.cols &&
            !covered[y][x + width] &&
            classes[y][x + width] == cell_class {
        width += 1
      }
      let mut depth = 1
      while y + depth < snapshot.rows {
        let mut row_matches = true
        for candidate_x in x..<(x + width) {
          if covered[y + depth][candidate_x] ||
            classes[y + depth][candidate_x] != cell_class {
            row_matches = false
            break
          }
        }
        if !row_matches {
          break
        }
        depth += 1
      }
      for covered_y in y..<(y + depth) {
        for covered_x in x..<(x + width) {
          covered[covered_y][covered_x] = true
        }
      }
      result.push({ x, y, width, depth, cell_class })
    }
  }
  result
}

///|
fn ecosystem_terrain_rectangle_polygon(
  rectangle : EcosystemTerrainRectangle,
) -> @energy_valley_contract.Polygon {
  let left = rectangle.x.to_double()
  let top = rectangle.y.to_double()
  let right = (rectangle.x + rectangle.width).to_double()
  let bottom = (rectangle.y + rectangle.depth).to_double()
  @energy_valley_contract.polygon([
    @energy_valley_contract.world_point(left, top),
    @energy_valley_contract.world_point(right, top),
    @energy_valley_contract.world_point(right, bottom),
    @energy_valley_contract.world_point(left, bottom),
  ])
}

///|
fn ecosystem_contract_terrain_regions(
  snapshot : EcosystemWorldSnapshot,
  seed : Int,
) -> Array[@energy_valley_contract.TerrainRegion] {
  let result : Array[@energy_valley_contract.TerrainRegion] = []
  for rectangle in ecosystem_terrain_rectangles(snapshot, seed) {
    let provenance = if rectangle.cell_class.custom {
      @energy_valley_contract.provenance(
        "moontown-world-delta",
        "v1",
        @energy_valley_contract.UserDelta,
        @energy_valley_contract.Bounded,
      )
    } else {
      @energy_valley_contract.provenance(
        "wenyu-reference-terrain",
        "v3",
        @energy_valley_contract.WenyuReference,
        @energy_valley_contract.Fixed,
      )
    }
    result.push(
      @energy_valley_contract.terrain_region(
        ecosystem_contract_scoped_id(
          "terrain-region",
          "\{rectangle.cell_class.key}-\{rectangle.x}-\{rectangle.y}-\{rectangle.width}-\{rectangle.depth}",
        ),
        rectangle.cell_class.kind,
        ecosystem_terrain_rectangle_polygon(rectangle),
        rectangle.cell_class.walkable,
        provenance,
      ),
    )
  }
  result
}

///|
let ecosystem_contract_terrain_kind_lookup_cache : Map[
  String,
  Map[String, @energy_valley_contract.TerrainKind],
] = Map([])

///|
let ecosystem_contract_terrain_walkable_lookup_cache : Map[
  String,
  Map[String, Bool],
] = Map([])

///|
fn ecosystem_contract_prepare_terrain_lookup(
  world : @energy_valley_contract.CompiledTownWorld,
) -> Unit {
  let identity = world.blueprint_digest
  if ecosystem_contract_terrain_kind_lookup_cache.contains(identity) &&
    ecosystem_contract_terrain_walkable_lookup_cache.contains(identity) {
    return
  }
  // Both maps are one coherent compiler artifact. Clear them together before
  // rebuilding so an edited world never retains a full raster lookup for
  // every historical blueprint, and a partially cleared cache cannot pair
  // fresh terrain kinds with stale walkability.
  ecosystem_contract_terrain_kind_lookup_cache.clear()
  ecosystem_contract_terrain_walkable_lookup_cache.clear()
  let kinds : Map[String, @energy_valley_contract.TerrainKind] = Map([])
  let walkable : Map[String, Bool] = Map([])
  for region in world.terrain_regions {
    let left = region.boundary.vertices[0].x.to_int()
    let top = region.boundary.vertices[0].y.to_int()
    let right = region.boundary.vertices[2].x.to_int()
    let bottom = region.boundary.vertices[2].y.to_int()
    for y in top..<bottom {
      for x in left..<right {
        let key = golden_valley_tile_key(x, y)
        kinds[key] = region.kind
        walkable[key] = region.walkable
      }
    }
  }
  ecosystem_contract_terrain_kind_lookup_cache[identity] = kinds
  ecosystem_contract_terrain_walkable_lookup_cache[identity] = walkable
}

///|
fn ecosystem_contract_terrain_kind_at(
  world : @energy_valley_contract.CompiledTownWorld,
  x : Int,
  y : Int,
) -> @energy_valley_contract.TerrainKind? {
  ecosystem_contract_prepare_terrain_lookup(world)
  ecosystem_contract_terrain_kind_lookup_cache[world.blueprint_digest].get(
    golden_valley_tile_key(x, y),
  )
}

///|
fn ecosystem_contract_terrain_walkable_at(
  world : @energy_valley_contract.CompiledTownWorld,
  x : Int,
  y : Int,
) -> Bool? {
  ecosystem_contract_prepare_terrain_lookup(world)
  ecosystem_contract_terrain_walkable_lookup_cache[world.blueprint_digest].get(
    golden_valley_tile_key(x, y),
  )
}
