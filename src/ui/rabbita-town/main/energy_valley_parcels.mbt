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
fn energy_valley_grow_parcel_structures(
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
