///|
/// The Wenyu raster is a high-resolution semantic layer. Gameplay parcels use
/// a coarser three-by-three planning cell so buildings remain legible when the
/// complete 256 × 144 valley is visible.
fn energy_valley_semantic_cells_per_planning_cell() -> Int {
  3
}

///|
priv struct EnergyValleyParcelPlacement {
  x : Int
  y : Int
  width : Int
  depth : Int
  score : Int
}

///|
fn energy_valley_parcel_buildable_kind(kind : String) -> Bool {
  kind == "urban-dense" || kind == "urban" || kind == "campus"
}

///|
fn energy_valley_prepare_semantic_ground(
  tiles : Array[Array[ExactEnergyValleyTile]],
) -> Unit {
  for row in tiles {
    for tile in row {
      if energy_valley_parcel_buildable_kind(tile.base_terrain) {
        // Raw urban/campus labels are source evidence, not final paving. The
        // parcel pass restores coherent urban or campus ground where a real
        // gameplay lot is accepted.
        tile.terrain = "meadow"
      }
    }
  }
}

///|
fn energy_valley_planning_kind(
  tiles : Array[Array[ExactEnergyValleyTile]],
  planning_x : Int,
  planning_y : Int,
) -> String? {
  let scale = energy_valley_semantic_cells_per_planning_cell()
  let start_x = planning_x * scale
  let start_y = planning_y * scale
  let mut dense = 0
  let mut urban = 0
  let mut campus = 0
  let mut sampled = 0
  for y in start_y..<(start_y + scale) {
    for x in start_x..<(start_x + scale) {
      if y >= exact_energy_valley_rows() || x >= exact_energy_valley_cols() {
        continue
      }
      sampled += 1
      match tiles[y][x].base_terrain {
        "urban-dense" => dense += 1
        "urban" => urban += 1
        "campus" => campus += 1
        _ => ()
      }
    }
  }
  let buildable = dense + urban + campus
  if sampled == 0 || buildable * 3 < sampled {
    None
  } else if campus > dense && campus > urban {
    Some("campus")
  } else if dense >= urban {
    Some("urban-dense")
  } else {
    Some("urban")
  }
}

///|
fn energy_valley_structure_cell_blocked(tile : ExactEnergyValleyTile) -> Bool {
  exact_energy_valley_is_transport_or_water(tile.terrain) ||
  tile.building_id is Some(_)
}

///|
fn energy_valley_structure_candidate_score(
  tiles : Array[Array[ExactEnergyValleyTile]],
  x : Int,
  y : Int,
  width : Int,
  depth : Int,
  parcel_kind : String,
) -> Int? {
  if x < 1 ||
    y < 1 ||
    x + width >= exact_energy_valley_cols() - 1 ||
    y + depth >= exact_energy_valley_rows() - 1 {
    return None
  }
  let mut score = 0
  let mut matching_ground = 0
  for yy in y..<(y + depth) {
    for xx in x..<(x + width) {
      let tile = tiles[yy][xx]
      if energy_valley_structure_cell_blocked(tile) {
        return None
      }
      if energy_valley_parcel_buildable_kind(tile.base_terrain) {
        matching_ground += 1
        score += if tile.base_terrain == parcel_kind { 5 } else { 3 }
      }
      if !reference_building_code_at(xx, yy).is_empty() {
        score += 7
      }
    }
  }
  if matching_ground * 3 < width * depth {
    return None
  }
  for xx in (x - 1)..<=(x + width) {
    if tiles[y - 1][xx].terrain == "road" ||
      tiles[y - 1][xx].terrain == "bridge" {
      score += 8
    }
    if tiles[y + depth][xx].terrain == "road" ||
      tiles[y + depth][xx].terrain == "bridge" {
      score += 8
    }
  }
  for yy in y..<(y + depth) {
    if tiles[yy][x - 1].terrain == "road" ||
      tiles[yy][x - 1].terrain == "bridge" {
      score += 8
    }
    if tiles[yy][x + width].terrain == "road" ||
      tiles[yy][x + width].terrain == "bridge" {
      score += 8
    }
  }
  Some(score)
}

///|
fn energy_valley_best_structure_placement(
  tiles : Array[Array[ExactEnergyValleyTile]],
  parcel_x : Int,
  parcel_y : Int,
  parcel_width : Int,
  parcel_depth : Int,
  target_width : Int,
  target_depth : Int,
  parcel_kind : String,
) -> EnergyValleyParcelPlacement? {
  let mut best : EnergyValleyParcelPlacement? = None
  for orientation in 0..<2 {
    let width = if orientation == 0 { target_width } else { target_depth }
    let depth = if orientation == 0 { target_depth } else { target_width }
    if width > parcel_width || depth > parcel_depth {
      continue
    }
    for y in parcel_y..<=(parcel_y + parcel_depth - depth) {
      for x in parcel_x..<=(parcel_x + parcel_width - width) {
        match
          energy_valley_structure_candidate_score(
            tiles, x, y, width, depth, parcel_kind,
          ) {
          None => ()
          Some(score) =>
            match best {
              Some(current) =>
                if score > current.score {
                  best = Some({ x, y, width, depth, score })
                }
              None => best = Some({ x, y, width, depth, score })
            }
        }
      }
    }
  }
  best
}

///|
fn energy_valley_parcel_target_footprint(
  seed : Int,
  planning_x : Int,
  planning_y : Int,
  kind : String,
) -> (Int, Int) {
  if kind == "campus" {
    (
      6 + energy_valley_variation(seed, planning_x, planning_y, 571, 2),
      6 + energy_valley_variation(seed, planning_x, planning_y, 577, 2),
    )
  } else if kind == "urban-dense" {
    (5, 4 + energy_valley_variation(seed, planning_x, planning_y, 587, 2))
  } else {
    (5, 4 + energy_valley_variation(seed, planning_x, planning_y, 593, 2))
  }
}

///|
fn energy_valley_mark_parcel_ground(
  tiles : Array[Array[ExactEnergyValleyTile]],
  parcel_x : Int,
  parcel_y : Int,
  parcel_width : Int,
  parcel_depth : Int,
  kind : String,
) -> Unit {
  let terrain = if kind == "campus" { "plaza" } else { "urban" }
  for y in parcel_y..<(parcel_y + parcel_depth) {
    for x in parcel_x..<(parcel_x + parcel_width) {
      let tile = tiles[y][x]
      if !exact_energy_valley_is_transport_or_water(tile.terrain) &&
        tile.building_id is None {
        tile.terrain = terrain
      }
    }
  }
}

///|
fn energy_valley_mark_structure_footprint(
  tiles : Array[Array[ExactEnergyValleyTile]],
  placement : EnergyValleyParcelPlacement,
  kind : String,
  floors : Int,
) -> Unit {
  let id = "ambient-\{placement.x}-\{placement.y}"
  let terrain = if kind == "campus" || kind == "civic" || kind == "industrial" {
    "plaza"
  } else {
    "urban"
  }
  for y in placement.y..<(placement.y + placement.depth) {
    for x in placement.x..<(placement.x + placement.width) {
      let tile = tiles[y][x]
      tile.terrain = terrain
      tile.generated_terrain = if terrain == "plaza" {
        "campus"
      } else {
        "urban"
      }
      tile.building_id = Some(id)
      tile.structure = None
      tile.structure_floors = None
      tile.structure_width = None
      tile.structure_depth = None
    }
  }
  let anchor = tiles[placement.y][placement.x]
  anchor.structure = Some(kind)
  anchor.structure_floors = Some(floors)
  anchor.structure_width = Some(placement.width)
  anchor.structure_depth = Some(placement.depth)
}

///|
fn energy_valley_grow_legacy_parcel_structures(
  tiles : Array[Array[ExactEnergyValleyTile]],
  seed : Int,
) -> Unit {
  let scale = energy_valley_semantic_cells_per_planning_cell()
  let planning_cols = (exact_energy_valley_cols() + scale - 1) / scale
  let planning_rows = (exact_energy_valley_rows() + scale - 1) / scale
  for planning_y in 0..<planning_rows {
    for planning_x in 0..<planning_cols {
      let planning_kind = match
        energy_valley_planning_kind(tiles, planning_x, planning_y) {
        Some(value) => value
        None => continue
      }
      let bucket_size = if planning_kind == "campus" { 3 } else { 2 }
      if energy_valley_mod(planning_x, bucket_size) != 0 ||
        energy_valley_mod(planning_y, bucket_size) != 0 {
        continue
      }
      let parcel_x = planning_x * scale
      let parcel_y = planning_y * scale
      let mut parcel_width = bucket_size * scale
      let mut parcel_depth = bucket_size * scale
      if parcel_x + parcel_width > exact_energy_valley_cols() {
        parcel_width = exact_energy_valley_cols() - parcel_x
      }
      if parcel_y + parcel_depth > exact_energy_valley_rows() {
        parcel_depth = exact_energy_valley_rows() - parcel_y
      }
      let source_structure = wenyu_reference_structure_for_parcel(
        seed, parcel_x, parcel_y, parcel_width, parcel_depth, planning_kind,
      )
      let structure = match source_structure {
        Some(value) => Some(value)
        None =>
          exact_energy_valley_procedural_structure(
            seed, planning_x, planning_y, planning_kind,
          )
      }
      let (kind, floors) = match structure {
        Some(value) => value
        None => continue
      }
      let (target_width, target_depth) = energy_valley_parcel_target_footprint(
        seed, planning_x, planning_y, planning_kind,
      )
      match
        energy_valley_best_structure_placement(
          tiles, parcel_x, parcel_y, parcel_width, parcel_depth, target_width, target_depth,
          planning_kind,
        ) {
        Some(placement) => {
          energy_valley_mark_parcel_ground(
            tiles, parcel_x, parcel_y, parcel_width, parcel_depth, planning_kind,
          )
          energy_valley_mark_structure_footprint(tiles, placement, kind, floors)
        }
        None => ()
      }
    }
  }
}

///|
/// Exact source-building evidence after the final road graph, civic footprints,
/// and water have carved it into one legal block and dry region.
priv struct EnergyValleyReferenceFragment {
  block_ordinal : Int
  region_ordinal : Int
  code : String
  area : Int
  sum_x : Int
  sum_y : Int
  min_x : Int
  min_y : Int
  max_x : Int
  max_y : Int
}

///|
fn energy_valley_shifted_reference_building_code_at(
  seed : Int,
  x : Int,
  y : Int,
) -> String {
  reference_building_code_at(
    x - energy_valley_road_pattern_shift_x(seed),
    y - energy_valley_road_pattern_shift_y(seed),
  )
}

///|
fn energy_valley_reference_fragment_cell(
  tiles : Array[Array[ExactEnergyValleyTile]],
  layout : EnergyValleyRoadBlockLayout,
  seed : Int,
  x : Int,
  y : Int,
) -> ((Int, Int), String)? {
  if !energy_valley_layout_cell_in_bounds(x, y) {
    return None
  }
  let code = energy_valley_shifted_reference_building_code_at(seed, x, y)
  if wenyu_reference_building_kind_from_code(code) is None {
    return None
  }
  let tile = tiles[y][x]
  if energy_valley_structure_cell_blocked(tile) ||
    tile.base_terrain == "wetland" ||
    !energy_valley_parcel_buildable_kind(tile.base_terrain) {
    return None
  }
  match energy_valley_road_block_layout_at(layout, x, y) {
    Some(identity) => Some((identity, code))
    None => None
  }
}

///|
fn energy_valley_reference_fragments(
  tiles : Array[Array[ExactEnergyValleyTile]],
  layout : EnergyValleyRoadBlockLayout,
  seed : Int,
) -> Array[EnergyValleyReferenceFragment] {
  let visited = energy_valley_bool_grid(false)
  let fragments : Array[EnergyValleyReferenceFragment] = []
  let cols = exact_energy_valley_cols()
  for start_y in 0..<exact_energy_valley_rows() {
    for start_x in 0..<cols {
      if visited[start_y][start_x] {
        continue
      }
      let source = match
        energy_valley_reference_fragment_cell(
          tiles, layout, seed, start_x, start_y,
        ) {
        Some(value) => value
        None => {
          visited[start_y][start_x] = true
          continue
        }
      }
      let identity = source.0
      let code = source.1
      let queue : Array[Int] = [start_y * cols + start_x]
      visited[start_y][start_x] = true
      let mut head = 0
      let mut area = 0
      let mut sum_x = 0
      let mut sum_y = 0
      let mut min_x = start_x
      let mut min_y = start_y
      let mut max_x = start_x
      let mut max_y = start_y
      while head < queue.length() {
        let encoded = queue[head]
        head += 1
        let x = encoded % cols
        let y = encoded / cols
        area += 1
        sum_x += x
        sum_y += y
        min_x = min_x.min(x)
        min_y = min_y.min(y)
        max_x = max_x.max(x)
        max_y = max_y.max(y)
        for delta in [(0, -1), (1, 0), (0, 1), (-1, 0)] {
          let next_x = x + delta.0
          let next_y = y + delta.1
          if !energy_valley_layout_cell_in_bounds(next_x, next_y) ||
            visited[next_y][next_x] {
            continue
          }
          match
            energy_valley_reference_fragment_cell(
              tiles, layout, seed, next_x, next_y,
            ) {
            Some((next_identity, next_code)) =>
              if next_identity == identity && next_code == code {
                visited[next_y][next_x] = true
                queue.push(next_y * cols + next_x)
              }
            None => ()
          }
        }
      }
      fragments.push({
        block_ordinal: identity.0,
        region_ordinal: identity.1,
        code,
        area,
        sum_x,
        sum_y,
        min_x,
        min_y,
        max_x,
        max_y,
      })
    }
  }
  fragments
}

///|
fn energy_valley_largest_reference_fragment_per_block(
  fragments : Array[EnergyValleyReferenceFragment],
  block_count : Int,
) -> Array[EnergyValleyReferenceFragment] {
  let best_by_block : Array[EnergyValleyReferenceFragment?] = Array::make(
    block_count + 1,
    None,
  )
  for fragment in fragments {
    let replace = match best_by_block[fragment.block_ordinal] {
      None => true
      Some(current) =>
        fragment.area > current.area ||
        (
          fragment.area == current.area &&
          (
            fragment.min_y < current.min_y ||
            (fragment.min_y == current.min_y && fragment.min_x < current.min_x)
          )
        )
    }
    if replace {
      best_by_block[fragment.block_ordinal] = Some(fragment)
    }
  }
  let result : Array[EnergyValleyReferenceFragment] = []
  for ordinal in 1..<=block_count {
    match best_by_block[ordinal] {
      Some(fragment) => result.push(fragment)
      None => ()
    }
  }
  result
}

///|
fn energy_valley_block_structure_candidate_score(
  tiles : Array[Array[ExactEnergyValleyTile]],
  layout : EnergyValleyRoadBlockLayout,
  seed : Int,
  fragment : EnergyValleyReferenceFragment,
  x : Int,
  y : Int,
  width : Int,
  depth : Int,
) -> Int? {
  let identity = (fragment.block_ordinal, fragment.region_ordinal)
  if energy_valley_road_block_layout_for_footprint(layout, x, y, width, depth) !=
    Some(identity) {
    return None
  }
  let clearance = 2
  for yy in (y - clearance)..<(y + depth + clearance) {
    for xx in (x - clearance)..<(x + width + clearance) {
      if energy_valley_layout_cell_in_bounds(xx, yy) &&
        tiles[yy][xx].building_id is Some(_) {
        return None
      }
    }
  }
  let mut buildable = 0
  let mut source_match = 0
  for yy in y..<(y + depth) {
    for xx in x..<(x + width) {
      let tile = tiles[yy][xx]
      if energy_valley_structure_cell_blocked(tile) ||
        tile.base_terrain == "wetland" {
        return None
      }
      if energy_valley_parcel_buildable_kind(tile.base_terrain) {
        buildable += 1
      }
      if energy_valley_shifted_reference_building_code_at(seed, xx, yy) ==
        fragment.code {
        source_match += 1
      }
    }
  }
  if buildable * 2 < width * depth {
    return None
  }
  let mut road_frontage = 0
  for xx in (x - 1)..<=(x + width) {
    for yy in [y - 1, y + depth] {
      if !energy_valley_layout_cell_in_bounds(xx, yy) {
        return None
      }
      let tile = tiles[yy][xx]
      if tile.terrain == "road" || tile.terrain == "bridge" {
        road_frontage += 1
      } else if tile.terrain == "water" ||
        tile.base_terrain == "wetland" ||
        tile.building_id is Some(_) ||
        energy_valley_road_block_layout_at(layout, xx, yy) != Some(identity) {
        return None
      }
    }
  }
  for yy in y..<(y + depth) {
    for xx in [x - 1, x + width] {
      if !energy_valley_layout_cell_in_bounds(xx, yy) {
        return None
      }
      let tile = tiles[yy][xx]
      if tile.terrain == "road" || tile.terrain == "bridge" {
        road_frontage += 1
      } else if tile.terrain == "water" ||
        tile.base_terrain == "wetland" ||
        tile.building_id is Some(_) ||
        energy_valley_road_block_layout_at(layout, xx, yy) != Some(identity) {
        return None
      }
    }
  }
  if road_frontage == 0 {
    return None
  }
  let fragment_center_x2 = (fragment.sum_x * 2 + fragment.area) / fragment.area
  let fragment_center_y2 = (fragment.sum_y * 2 + fragment.area) / fragment.area
  let candidate_center_x2 = x * 2 + width
  let candidate_center_y2 = y * 2 + depth
  let distance = abs_int(candidate_center_x2 - fragment_center_x2) +
    abs_int(candidate_center_y2 - fragment_center_y2)
  Some(road_frontage * 40 + source_match * 16 + buildable * 3 - distance * 5)
}

///|
fn energy_valley_best_block_structure_placement(
  tiles : Array[Array[ExactEnergyValleyTile]],
  layout : EnergyValleyRoadBlockLayout,
  seed : Int,
  fragment : EnergyValleyReferenceFragment,
) -> EnergyValleyParcelPlacement? {
  let sizes = [(5, 4), (4, 5), (3, 3)]
  let anchor_x = fragment.sum_x / fragment.area
  let anchor_y = fragment.sum_y / fragment.area
  let search_radius = 14
  for size in sizes {
    let width = size.0
    let depth = size.1
    let mut best : EnergyValleyParcelPlacement? = None
    let start_x = (anchor_x - search_radius).max(1)
    let start_y = (anchor_y - search_radius).max(1)
    let end_x = (anchor_x + search_radius).min(
      exact_energy_valley_cols() - width - 2,
    )
    let end_y = (anchor_y + search_radius).min(
      exact_energy_valley_rows() - depth - 2,
    )
    for y in start_y..<=end_y {
      for x in start_x..<=end_x {
        match
          energy_valley_block_structure_candidate_score(
            tiles, layout, seed, fragment, x, y, width, depth,
          ) {
          None => ()
          Some(score) =>
            match best {
              Some(current) =>
                if score > current.score {
                  best = Some({ x, y, width, depth, score })
                }
              None => best = Some({ x, y, width, depth, score })
            }
        }
      }
    }
    if best is Some(_) {
      return best
    }
  }
  None
}

///|
fn energy_valley_mark_block_structure_ground(
  tiles : Array[Array[ExactEnergyValleyTile]],
  layout : EnergyValleyRoadBlockLayout,
  placement : EnergyValleyParcelPlacement,
  fragment : EnergyValleyReferenceFragment,
  kind : String,
) -> Unit {
  let terrain = if kind == "campus" || kind == "civic" || kind == "industrial" {
    "plaza"
  } else {
    "urban"
  }
  let identity = (fragment.block_ordinal, fragment.region_ordinal)
  for y in (placement.y - 1)..<=(placement.y + placement.depth) {
    for x in (placement.x - 1)..<=(placement.x + placement.width) {
      if energy_valley_road_block_layout_at(layout, x, y) == Some(identity) {
        let tile = tiles[y][x]
        if !exact_energy_valley_is_transport_or_water(tile.terrain) &&
          tile.base_terrain != "wetland" &&
          tile.building_id is None {
          tile.terrain = terrain
          tile.generated_terrain = if terrain == "plaza" {
            "campus"
          } else {
            "urban"
          }
        }
      }
    }
  }
}

///|
fn energy_valley_mark_block_structure_footprint(
  tiles : Array[Array[ExactEnergyValleyTile]],
  placement : EnergyValleyParcelPlacement,
  fragment : EnergyValleyReferenceFragment,
  kind : String,
  floors : Int,
) -> Unit {
  let id = "ambient-wenyu-\{fragment.block_ordinal}-\{kind}"
  let terrain = if kind == "campus" || kind == "civic" || kind == "industrial" {
    "plaza"
  } else {
    "urban"
  }
  for y in placement.y..<(placement.y + placement.depth) {
    for x in placement.x..<(placement.x + placement.width) {
      let tile = tiles[y][x]
      tile.terrain = terrain
      tile.generated_terrain = if terrain == "plaza" {
        "campus"
      } else {
        "urban"
      }
      tile.building_id = Some(id)
      tile.structure = None
      tile.structure_floors = None
      tile.structure_width = None
      tile.structure_depth = None
    }
  }
  let anchor = tiles[placement.y][placement.x]
  anchor.structure = Some(kind)
  anchor.structure_floors = Some(floors)
  anchor.structure_width = Some(placement.width)
  anchor.structure_depth = Some(placement.depth)
}

///|
fn energy_valley_grow_block_structures(
  tiles : Array[Array[ExactEnergyValleyTile]],
  seed : Int,
  layout : EnergyValleyRoadBlockLayout,
) -> Unit {
  let fragments = energy_valley_largest_reference_fragment_per_block(
    energy_valley_reference_fragments(tiles, layout, seed),
    layout.blocks.length(),
  )
  for fragment in fragments {
    let source_kind = match
      wenyu_reference_building_kind_from_code(fragment.code) {
      Some(value) => value
      None => continue
    }
    let target = source_kind.new_system_kind()
    let kind = target.runtime_name()
    let (base_floors, floor_variants) = target.floor_profile()
    let floors = base_floors +
      energy_valley_variation(
        seed,
        fragment.min_x,
        fragment.min_y,
        659 + fragment.block_ordinal,
        floor_variants,
      )
    match
      energy_valley_best_block_structure_placement(
        tiles, layout, seed, fragment,
      ) {
      Some(placement) => {
        energy_valley_mark_block_structure_ground(
          tiles, layout, placement, fragment, kind,
        )
        energy_valley_mark_block_structure_footprint(
          tiles, placement, fragment, kind, floors,
        )
      }
      None => ()
    }
  }
}

///|
fn energy_valley_grow_parcel_structures(
  tiles : Array[Array[ExactEnergyValleyTile]],
  seed : Int,
  layout : EnergyValleyRoadBlockLayout,
) -> Unit {
  if reference_building_snapshot_ready() &&
    reference_road_graph_snapshot_ready() {
    energy_valley_grow_block_structures(tiles, seed, layout)
  } else {
    // The production bootstrap installs the Wenyu building snapshot before
    // world generation. Keep the prior deterministic fallback for isolated
    // tests and degraded/offline startup where that authoring evidence is
    // intentionally unavailable.
    energy_valley_grow_legacy_parcel_structures(tiles, seed)
  }
}
