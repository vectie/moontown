///|
/// One water-free, road-free rectangle inside an authored Wenyu land block.
/// Rectangles are a lossless raster decomposition; the top-level block keeps
/// the stable road-enclosed identity while these fragments carry exact local
/// land use into the parcel compiler.
priv struct EcosystemPlanningFragment {
  id_key : String
  x : Int
  y : Int
  width : Int
  depth : Int
  land_use : @energy_valley_contract.LandUse
  custom : Bool
}

///|
/// A top-level block is one of the 75 four-neighbor components enclosed by the
/// authoritative Wenyu road rows. Its ordinal and canonical anchor never
/// change when water, parks, roads, or buildings are added as local deltas.
priv struct EcosystemPlanningBlock {
  ordinal : Int
  canonical_anchor : EcosystemGridPoint
  cells : Array[EcosystemGridPoint]
  boundary : @energy_valley_contract.Polygon
  land_regions : Array[EcosystemPlanningLandRegion]
  fragments : Array[EcosystemPlanningFragment]
  land_use : @energy_valley_contract.LandUse
  target_parcels : Int
}

///|
/// A connected buildable island inside one stable road-enclosed block. The
/// accepted RoadNetwork and compiled typed water/wetland are both hard
/// boundaries here. Raw label pixels can contain candidate seams later
/// consumed by bridge/road repair; only accepted compiler output determines
/// these regions. Multiple islands intentionally retain their shared top-level
/// identity: Wenyu roads define the legal block, while water defines its usable
/// subregions.
priv struct EcosystemPlanningLandRegion {
  canonical_anchor : EcosystemGridPoint
  cells : Array[EcosystemGridPoint]
  boundary : @energy_valley_contract.Polygon
}

///|
priv struct EcosystemReferenceComponent {
  canonical_anchor : EcosystemGridPoint
  cells : Array[EcosystemGridPoint]
}

///|
priv struct EcosystemEligibleParcelTile {
  land_use : @energy_valley_contract.LandUse
  custom : Bool
} derive(Eq)

///|
priv struct EcosystemBoundaryEdge {
  from_x : Int
  from_y : Int
  to_x : Int
  to_y : Int
  mut used : Bool
}

///|
fn ecosystem_wenyu_reference_road_code_is_road(code : String) -> Bool {
  code == "M" || code == "R" || code == "b"
}

///|
fn ecosystem_wenyu_reference_road_mask(
  snapshot : EcosystemWorldSnapshot,
  seed : Int,
) -> Array[Array[Bool]] {
  let result = Array::makei(snapshot.rows, _ => {
    Array::make(snapshot.cols, false)
  })
  if reference_road_graph_snapshot_ready() {
    for y in 0..<snapshot.rows {
      for x in 0..<snapshot.cols {
        result[y][x] = ecosystem_wenyu_reference_road_code_is_road(
          reference_road_graph_code_at(x, y),
        )
      }
    }
    return result
  }
  // The browser loads the canonical rows before MoonBit starts. This fallback
  // keeps isolated tests and explicit degraded starts deterministic by undoing
  // the renderer's seed shift on the already typed, non-local road cells.
  let shift_x = energy_valley_road_pattern_shift_x(seed)
  let shift_y = energy_valley_road_pattern_shift_y(seed)
  for road in snapshot.roads {
    if road.custom {
      continue
    }
    let canonical_x = road.x - shift_x
    let canonical_y = road.y - shift_y
    if canonical_x >= 0 &&
      canonical_x < snapshot.cols &&
      canonical_y >= 0 &&
      canonical_y < snapshot.rows {
      result[canonical_y][canonical_x] = true
    }
  }
  result
}

///|
fn ecosystem_wenyu_component_anchor(
  cells : ArrayView[EcosystemGridPoint],
) -> EcosystemGridPoint {
  let mut anchor_x = exact_energy_valley_cols()
  let mut anchor_y = exact_energy_valley_rows()
  for cell in cells {
    if cell.y < anchor_y || (cell.y == anchor_y && cell.x < anchor_x) {
      anchor_x = cell.x
      anchor_y = cell.y
    }
  }
  ecosystem_point(anchor_x, anchor_y)
}

///|
fn ecosystem_wenyu_reference_components(
  snapshot : EcosystemWorldSnapshot,
  seed : Int,
) -> Array[EcosystemReferenceComponent] {
  let roads = ecosystem_wenyu_reference_road_mask(snapshot, seed)
  let visited = Array::makei(snapshot.rows, _ => {
    Array::make(snapshot.cols, false)
  })
  let result : Array[EcosystemReferenceComponent] = []
  for start_y in 0..<snapshot.rows {
    for start_x in 0..<snapshot.cols {
      if roads[start_y][start_x] || visited[start_y][start_x] {
        continue
      }
      let queue : Array[Int] = [start_y * snapshot.cols + start_x]
      let cells : Array[EcosystemGridPoint] = []
      visited[start_y][start_x] = true
      let mut head = 0
      let mut touches_boundary = false
      while head < queue.length() {
        let encoded = queue[head]
        head += 1
        let x = encoded % snapshot.cols
        let y = encoded / snapshot.cols
        cells.push(ecosystem_point(x, y))
        if x == 0 || y == 0 || x == snapshot.cols - 1 || y == snapshot.rows - 1 {
          touches_boundary = true
        }
        for delta in [(0, -1), (1, 0), (0, 1), (-1, 0)] {
          let next_x = x + delta.0
          let next_y = y + delta.1
          if next_x >= 0 &&
            next_x < snapshot.cols &&
            next_y >= 0 &&
            next_y < snapshot.rows &&
            !roads[next_y][next_x] &&
            !visited[next_y][next_x] {
            visited[next_y][next_x] = true
            queue.push(next_y * snapshot.cols + next_x)
          }
        }
      }
      if !touches_boundary {
        result.push({
          canonical_anchor: ecosystem_wenyu_component_anchor(cells),
          cells,
        })
      }
    }
  }
  result.sort_by((left, right) => {
    let by_y = left.canonical_anchor.y.compare(right.canonical_anchor.y)
    if by_y != 0 {
      by_y
    } else {
      left.canonical_anchor.x.compare(right.canonical_anchor.x)
    }
  })
  result
}

///|
fn ecosystem_wenyu_shifted_component_cells(
  component : EcosystemReferenceComponent,
  seed : Int,
  cols : Int,
  rows : Int,
) -> Array[EcosystemGridPoint] {
  let shift_x = energy_valley_road_pattern_shift_x(seed)
  let shift_y = energy_valley_road_pattern_shift_y(seed)
  let result : Array[EcosystemGridPoint] = []
  for cell in component.cells {
    let x = cell.x + shift_x
    let y = cell.y + shift_y
    if x >= 0 && x < cols && y >= 0 && y < rows {
      result.push(ecosystem_point(x, y))
    }
  }
  // A future seed grammar must never erase a canonical block identity. The
  // current ±3 shift leaves all 75 blocks non-empty; this branch is a safe,
  // deterministic guard against a wider shift being introduced accidentally.
  if result.is_empty() {
    component.cells.copy()
  } else {
    result
  }
}

///|
fn ecosystem_wenyu_water_separated_land_regions(
  world : ExactEnergyValleyWorld,
  cells : ArrayView[EcosystemGridPoint],
  roads : Map[String, EcosystemRoadCell],
) -> Array[EcosystemPlanningLandRegion] {
  let eligible : Map[String, Bool] = Map([])
  for cell in cells {
    let key = golden_valley_tile_key(cell.x, cell.y)
    let terrain = world.tiles[cell.y][cell.x].terrain
    if !roads.contains(key) && terrain != "water" && terrain != "wetland" {
      eligible[key] = true
    }
  }
  let sorted_cells = cells.to_owned()
  sorted_cells.sort_by((left, right) => {
    let by_y = left.y.compare(right.y)
    if by_y != 0 {
      by_y
    } else {
      left.x.compare(right.x)
    }
  })
  let visited : Map[String, Bool] = Map([])
  let result : Array[EcosystemPlanningLandRegion] = []
  for start in sorted_cells {
    let start_key = golden_valley_tile_key(start.x, start.y)
    if !eligible.contains(start_key) || visited.contains(start_key) {
      continue
    }
    let queue : Array[EcosystemGridPoint] = [start]
    let region_cells : Array[EcosystemGridPoint] = []
    visited[start_key] = true
    let mut head = 0
    while head < queue.length() {
      let cell = queue[head]
      head += 1
      region_cells.push(cell)
      for delta in [(0, -1), (1, 0), (0, 1), (-1, 0)] {
        let next = ecosystem_point(cell.x + delta.0, cell.y + delta.1)
        let next_key = golden_valley_tile_key(next.x, next.y)
        if eligible.contains(next_key) && !visited.contains(next_key) {
          visited[next_key] = true
          queue.push(next)
        }
      }
    }
    let anchor = ecosystem_wenyu_component_anchor(region_cells)
    result.push({
      canonical_anchor: anchor,
      cells: region_cells,
      boundary: ecosystem_wenyu_boundary_polygon(region_cells),
    })
  }
  result.sort_by((left, right) => {
    let by_y = left.canonical_anchor.y.compare(right.canonical_anchor.y)
    if by_y != 0 {
      by_y
    } else {
      left.canonical_anchor.x.compare(right.canonical_anchor.x)
    }
  })
  result
}

///|
fn ecosystem_wenyu_append_boundary_edge(
  result : Array[EcosystemBoundaryEdge],
  from_x : Int,
  from_y : Int,
  to_x : Int,
  to_y : Int,
) -> Unit {
  result.push({ from_x, from_y, to_x, to_y, used: false })
}

///|
fn ecosystem_wenyu_boundary_edges(
  cells : ArrayView[EcosystemGridPoint],
) -> Array[EcosystemBoundaryEdge] {
  let occupied : Map[String, Bool] = Map([])
  for cell in cells {
    occupied[golden_valley_tile_key(cell.x, cell.y)] = true
  }
  let result : Array[EcosystemBoundaryEdge] = []
  for cell in cells {
    let x = cell.x
    let y = cell.y
    if !occupied.contains(golden_valley_tile_key(x, y - 1)) {
      ecosystem_wenyu_append_boundary_edge(result, x, y, x + 1, y)
    }
    if !occupied.contains(golden_valley_tile_key(x + 1, y)) {
      ecosystem_wenyu_append_boundary_edge(result, x + 1, y, x + 1, y + 1)
    }
    if !occupied.contains(golden_valley_tile_key(x, y + 1)) {
      ecosystem_wenyu_append_boundary_edge(result, x + 1, y + 1, x, y + 1)
    }
    if !occupied.contains(golden_valley_tile_key(x - 1, y)) {
      ecosystem_wenyu_append_boundary_edge(result, x, y + 1, x, y)
    }
  }
  result.sort_by((left, right) => {
    let by_y = left.from_y.compare(right.from_y)
    if by_y != 0 {
      by_y
    } else {
      let by_x = left.from_x.compare(right.from_x)
      if by_x != 0 {
        by_x
      } else {
        let by_to_y = left.to_y.compare(right.to_y)
        if by_to_y != 0 {
          by_to_y
        } else {
          left.to_x.compare(right.to_x)
        }
      }
    }
  })
  result
}

///|
fn ecosystem_wenyu_boundary_polygon(
  cells : ArrayView[EcosystemGridPoint],
) -> @energy_valley_contract.Polygon {
  let edges = ecosystem_wenyu_boundary_edges(cells)
  if edges.is_empty() {
    return @energy_valley_contract.polygon([])
  }
  let outgoing : Map[String, Array[Int]] = Map([])
  for index, edge in edges {
    let key = golden_valley_tile_key(edge.from_x, edge.from_y)
    match outgoing.get(key) {
      Some(indices) => indices.push(index)
      None => outgoing[key] = [index]
    }
  }
  let mut best = @energy_valley_contract.polygon([])
  let mut best_area = 0.0
  for start_index in 0..<edges.length() {
    if edges[start_index].used {
      continue
    }
    let start = edges[start_index]
    let stack : Array[EcosystemGridPoint] = [
      ecosystem_point(start.from_x, start.from_y),
    ]
    let circuit : Array[EcosystemGridPoint] = []
    while !stack.is_empty() {
      let current = stack[stack.length() - 1]
      let mut next_index = -1
      match outgoing.get(golden_valley_tile_key(current.x, current.y)) {
        Some(candidates) =>
          for candidate in candidates {
            if !edges[candidate].used {
              next_index = candidate
              break
            }
          }
        None => ()
      }
      if next_index >= 0 {
        edges[next_index].used = true
        let edge = edges[next_index]
        stack.push(ecosystem_point(edge.to_x, edge.to_y))
      } else {
        circuit.push(stack.pop().unwrap())
      }
    }
    let vertices : Array[@energy_valley_contract.WorldPoint] = []
    for offset in 0..<circuit.length() {
      let point = circuit[circuit.length() - 1 - offset]
      if offset == circuit.length() - 1 && point == circuit[0] {
        continue
      }
      vertices.push(
        @energy_valley_contract.world_point(
          point.x.to_double(),
          point.y.to_double(),
        ),
      )
    }
    let candidate = @energy_valley_contract.polygon(vertices)
    let area = candidate.area()
    if area > best_area {
      best = candidate
      best_area = area
    }
  }
  if best_area > 0.0 {
    best
  } else {
    let anchor = ecosystem_wenyu_component_anchor(cells)
    @energy_valley_contract.polygon([
      @energy_valley_contract.world_point(
        anchor.x.to_double(),
        anchor.y.to_double(),
      ),
      @energy_valley_contract.world_point(
        (anchor.x + 1).to_double(),
        anchor.y.to_double(),
      ),
      @energy_valley_contract.world_point(
        (anchor.x + 1).to_double(),
        (anchor.y + 1).to_double(),
      ),
      @energy_valley_contract.world_point(
        anchor.x.to_double(),
        (anchor.y + 1).to_double(),
      ),
    ])
  }
}

///|
fn ecosystem_wenyu_tile_land_use(
  world : ExactEnergyValleyWorld,
  park_lookup : Map[String, Unit],
  x : Int,
  y : Int,
) -> @energy_valley_contract.LandUse {
  if park_lookup.contains(golden_valley_tile_key(x, y)) {
    return @energy_valley_contract.Park
  }
  let tile = world.tiles[y][x]
  if tile.district.contains("civic") {
    @energy_valley_contract.Civic
  } else if tile.district.contains("community") {
    @energy_valley_contract.Residential
  } else if tile.district.contains("research") ||
    tile.district.contains("innovation") ||
    tile.district.contains("learning") {
    @energy_valley_contract.Research
  } else {
    match tile.base_terrain {
      "campus" => @energy_valley_contract.Research
      "urban-dense" => @energy_valley_contract.MixedUse
      "urban" => @energy_valley_contract.Residential
      "grass"
      | "grass-light"
      | "grass-flower-pink"
      | "grass-flower-yellow"
      | "forest"
      | "farm"
      | "field"
      | "wetland" => @energy_valley_contract.Park
      "river" | "lake" => @energy_valley_contract.Waterfront
      _ => @energy_valley_contract.MixedUse
    }
  }
}

///|
fn ecosystem_wenyu_local_delta_tiles(
  snapshot : EcosystemWorldSnapshot,
) -> Map[String, Bool] {
  let result : Map[String, Bool] = Map([])
  for road in snapshot.roads {
    if road.custom {
      result[golden_valley_tile_key(road.x, road.y)] = true
    }
  }
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
fn ecosystem_wenyu_planning_fragments(
  snapshot : EcosystemWorldSnapshot,
  world : ExactEnergyValleyWorld,
  land_regions : ArrayView[EcosystemPlanningLandRegion],
  parks : Map[String, Unit],
  local_delta : Map[String, Bool],
) -> Array[EcosystemPlanningFragment] {
  let eligible : Map[String, EcosystemEligibleParcelTile] = Map([])
  let region_ordinals : Map[String, Int] = Map([])
  let sorted_cells : Array[EcosystemGridPoint] = []
  for ordinal, region in land_regions {
    for cell in region.cells {
      let key = golden_valley_tile_key(cell.x, cell.y)
      eligible[key] = {
        land_use: ecosystem_wenyu_tile_land_use(world, parks, cell.x, cell.y),
        custom: local_delta.contains(key),
      }
      region_ordinals[key] = ordinal
      sorted_cells.push(cell)
    }
  }
  let covered : Map[String, Bool] = Map([])
  sorted_cells.sort_by((left, right) => {
    let by_y = left.y.compare(right.y)
    if by_y != 0 {
      by_y
    } else {
      left.x.compare(right.x)
    }
  })
  let result : Array[EcosystemPlanningFragment] = []
  for cell in sorted_cells {
    let origin_key = golden_valley_tile_key(cell.x, cell.y)
    if covered.contains(origin_key) {
      continue
    }
    let tile_class = match eligible.get(origin_key) {
      Some(value) => value
      None => continue
    }
    let region_ordinal = region_ordinals.get(origin_key).unwrap()
    let mut width = 0
    while cell.x + width < snapshot.cols {
      let key = golden_valley_tile_key(cell.x + width, cell.y)
      if covered.contains(key) ||
        eligible.get(key) != Some(tile_class) ||
        region_ordinals.get(key) != Some(region_ordinal) {
        break
      }
      width += 1
    }
    let mut depth = 1
    while cell.y + depth < snapshot.rows {
      let mut row_matches = true
      for x in cell.x..<(cell.x + width) {
        let key = golden_valley_tile_key(x, cell.y + depth)
        if covered.contains(key) ||
          eligible.get(key) != Some(tile_class) ||
          region_ordinals.get(key) != Some(region_ordinal) {
          row_matches = false
          break
        }
      }
      if !row_matches {
        break
      }
      depth += 1
    }
    for y in cell.y..<(cell.y + depth) {
      for x in cell.x..<(cell.x + width) {
        let key = golden_valley_tile_key(x, y)
        covered[key] = true
      }
    }
    result.push({
      id_key: "\{cell.x}-\{cell.y}-\{width}-\{depth}",
      x: cell.x,
      y: cell.y,
      width,
      depth,
      land_use: tile_class.land_use,
      custom: tile_class.custom,
    })
  }
  result
}

///|
fn ecosystem_wenyu_land_use_index(
  land_use : @energy_valley_contract.LandUse,
) -> Int {
  match land_use {
    @energy_valley_contract.Civic => 0
    @energy_valley_contract.MixedUse => 1
    @energy_valley_contract.Park => 2
    @energy_valley_contract.Research => 3
    @energy_valley_contract.Residential => 4
    @energy_valley_contract.Transit => 5
    @energy_valley_contract.Utility => 6
    @energy_valley_contract.Waterfront => 7
    @energy_valley_contract.Custom(_) => 8
  }
}

///|
fn ecosystem_wenyu_land_use_for_index(
  index : Int,
) -> @energy_valley_contract.LandUse {
  match index {
    0 => @energy_valley_contract.Civic
    1 => @energy_valley_contract.MixedUse
    2 => @energy_valley_contract.Park
    3 => @energy_valley_contract.Research
    4 => @energy_valley_contract.Residential
    5 => @energy_valley_contract.Transit
    6 => @energy_valley_contract.Utility
    7 => @energy_valley_contract.Waterfront
    _ => @energy_valley_contract.MixedUse
  }
}

///|
fn ecosystem_wenyu_dominant_land_use(
  fragments : ArrayView[EcosystemPlanningFragment],
) -> @energy_valley_contract.LandUse {
  let areas = Array::make(9, 0)
  for fragment in fragments {
    areas[ecosystem_wenyu_land_use_index(fragment.land_use)] += fragment.width *
      fragment.depth
  }
  let mut best_index = 0
  for index in 1..<areas.length() {
    if areas[index] > areas[best_index] {
      best_index = index
    }
  }
  ecosystem_wenyu_land_use_for_index(best_index)
}

///|
fn ecosystem_parcel_planning_blocks(
  snapshot : EcosystemWorldSnapshot,
  seed : Int,
) -> Array[EcosystemPlanningBlock] {
  let world = golden_valley_world(seed)
  let components = ecosystem_wenyu_reference_components(snapshot, seed)
  let roads = ecosystem_parcel_road_lookup(snapshot)
  let parks = ecosystem_parcel_park_lookup(snapshot)
  let local_delta = ecosystem_wenyu_local_delta_tiles(snapshot)
  let result : Array[EcosystemPlanningBlock] = []
  for ordinal, component in components {
    let cells = ecosystem_wenyu_shifted_component_cells(
      component,
      seed,
      snapshot.cols,
      snapshot.rows,
    )
    let land_regions = ecosystem_wenyu_water_separated_land_regions(
      world, cells, roads,
    )
    let fragments = ecosystem_wenyu_planning_fragments(
      snapshot, world, land_regions, parks, local_delta,
    )
    let land_use = if fragments.is_empty() {
      ecosystem_wenyu_tile_land_use(world, parks, cells[0].x, cells[0].y)
    } else {
      ecosystem_wenyu_dominant_land_use(fragments)
    }
    result.push({
      ordinal: ordinal + 1,
      canonical_anchor: component.canonical_anchor,
      cells,
      boundary: ecosystem_wenyu_boundary_polygon(cells),
      land_regions,
      fragments,
      land_use,
      target_parcels: fragments.length(),
    })
  }
  result
}
