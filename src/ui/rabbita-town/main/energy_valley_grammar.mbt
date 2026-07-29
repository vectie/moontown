///|
priv struct EnergyValleyGrammar {
  seed : Int
  river_shift : Int
  north_road_y : Int
  civic_road_y : Int
  lake_road_y : Int
  south_road_y : Int
  market_road_y : Int
  west_road_x : Int
  civic_road_x : Int
  research_road_x : Int
  east_road_x : Int
}

///|
fn energy_valley_grammar(seed : Int) -> EnergyValleyGrammar {
  let normalized = normalized_energy_valley_seed(seed)
  {
    seed: normalized,
    river_shift: energy_valley_signed_variation(normalized, 0, 0, 11, 2),
    north_road_y: 55 + energy_valley_signed_variation(normalized, 1, 0, 17, 2),
    civic_road_y: 72 + energy_valley_signed_variation(normalized, 2, 0, 19, 2),
    lake_road_y: 94 + energy_valley_signed_variation(normalized, 3, 0, 23, 2),
    south_road_y: 106 + energy_valley_signed_variation(normalized, 4, 0, 29, 2),
    market_road_y: 114 + energy_valley_signed_variation(normalized, 5, 0, 31, 2),
    west_road_x: 92 + energy_valley_signed_variation(normalized, 0, 1, 37, 2),
    civic_road_x: 128 + energy_valley_signed_variation(normalized, 0, 2, 41, 2),
    research_road_x: 151 +
    energy_valley_signed_variation(normalized, 0, 3, 43, 2),
    east_road_x: 181 + energy_valley_signed_variation(normalized, 0, 4, 47, 2),
  }
}

///|
fn energy_valley_road_pattern_shift_x(seed : Int) -> Int {
  let normalized = normalized_energy_valley_seed(seed)
  if normalized == default_energy_valley_seed {
    0
  } else {
    energy_valley_signed_variation(normalized, 17, 3, 503, 3)
  }
}

///|
fn energy_valley_road_pattern_shift_y(seed : Int) -> Int {
  let normalized = normalized_energy_valley_seed(seed)
  if normalized == default_energy_valley_seed {
    0
  } else {
    energy_valley_signed_variation(normalized, 23, 5, 509, 3)
  }
}

///|
fn energy_valley_reference_road_kind_at(
  seed : Int,
  grid_x : Int,
  grid_y : Int,
) -> String? {
  reference_tile_kind_at(
    grid_x - energy_valley_road_pattern_shift_x(seed),
    grid_y - energy_valley_road_pattern_shift_y(seed),
  )
}

///|
fn energy_valley_reference_road_like_at(
  seed : Int,
  grid_x : Int,
  grid_y : Int,
) -> Bool {
  match energy_valley_reference_road_kind_at(seed, grid_x, grid_y) {
    Some("road-major") | Some("road") | Some("bridge") => true
    _ => false
  }
}

///|
fn energy_valley_reference_road_gap_at(
  seed : Int,
  grid_x : Int,
  grid_y : Int,
) -> Bool {
  // The semantic JSON is a down-sampled image graph. A one-cell hole between
  // opposite road samples is a sampling seam, not a new street. Repair only
  // those seams so the authored curves, loops, and feeders stay recognizable.
  energy_valley_road_gap_from_neighbors(
    energy_valley_reference_road_like_at(seed, grid_x, grid_y),
    energy_valley_reference_road_like_at(seed, grid_x - 1, grid_y),
    energy_valley_reference_road_like_at(seed, grid_x + 1, grid_y),
    energy_valley_reference_road_like_at(seed, grid_x, grid_y - 1),
    energy_valley_reference_road_like_at(seed, grid_x, grid_y + 1),
    energy_valley_reference_road_like_at(seed, grid_x - 1, grid_y - 1),
    energy_valley_reference_road_like_at(seed, grid_x + 1, grid_y + 1),
    energy_valley_reference_road_like_at(seed, grid_x + 1, grid_y - 1),
    energy_valley_reference_road_like_at(seed, grid_x - 1, grid_y + 1),
  )
}

///|
fn energy_valley_road_gap_from_neighbors(
  center : Bool,
  west : Bool,
  east : Bool,
  north : Bool,
  south : Bool,
  northwest : Bool,
  southeast : Bool,
  northeast : Bool,
  southwest : Bool,
) -> Bool {
  !center &&
  (
    (west && east) ||
    (north && south) ||
    (northwest && southeast) ||
    (northeast && southwest)
  )
}

///|
fn energy_valley_preserved_reference_kind(
  seed : Int,
  grid_x : Int,
  grid_y : Int,
) -> String? {
  match reference_tile_kind_at(grid_x, grid_y) {
    None => None
    Some(kind) =>
      // Roads are compiled as a coherent layer below. Letting this generic
      // preservation pass randomly retain road cells would break corridors.
      if kind == "road-major" || kind == "road" || kind == "bridge" {
        None
      } else if normalized_energy_valley_seed(seed) ==
        default_energy_valley_seed ||
        energy_valley_variation(seed, grid_x, grid_y, 499, 100) < 86 {
        Some(kind)
      } else {
        None
      }
  }
}

///|
fn energy_valley_main_river_center_x(seed : Int, grid_y : Int) -> Int {
  let grammar = energy_valley_grammar(seed)
  let segment = grid_y / 9
  river_center_x_at(grid_y) +
  grammar.river_shift +
  energy_valley_signed_variation(grammar.seed, segment, grid_y % 9, 53, 2)
}

///|
fn energy_valley_reference_water_core_at(grid_x : Int, grid_y : Int) -> Bool {
  reference_water_at(grid_x, grid_y) &&
  reference_water_at(grid_x - 1, grid_y) &&
  reference_water_at(grid_x + 1, grid_y) &&
  reference_water_at(grid_x, grid_y - 1) &&
  reference_water_at(grid_x, grid_y + 1)
}

///|
fn energy_valley_main_river_at(seed : Int, grid_x : Int, grid_y : Int) -> Bool {
  if grid_y < 7 || grid_y >= tilemap_grid_height() {
    return false
  }
  let center = energy_valley_main_river_center_x(seed, grid_y)
  let half_width = if grid_y > 96 { 5 } else if grid_y > 50 { 4 } else { 3 }
  abs_int(grid_x - center) <= half_width
}

///|
fn energy_valley_tributary_at(seed : Int, grid_x : Int, grid_y : Int) -> Bool {
  let normalized = normalized_energy_valley_seed(seed)
  let north_shift = energy_valley_signed_variation(normalized, 1, 1, 59, 2)
  let west_shift = energy_valley_signed_variation(normalized, 2, 1, 61, 2)
  let north = grid_y >= 2 &&
    grid_y <= 15 &&
    abs_int(grid_x - (8 + grid_y * 2 + grid_y / 3 + north_shift)) <= 1
  let west = grid_y >= 37 &&
    grid_y <= 54 &&
    abs_int(grid_x - (42 + (grid_y - 37) * 3 + west_shift)) <= 2
  north || west
}

///|
fn energy_valley_lake_at(seed : Int, grid_x : Int, grid_y : Int) -> Bool {
  match energy_valley_preserved_reference_kind(seed, grid_x, grid_y) {
    Some(kind) => return kind == "lake"
    None => ()
  }
  let normalized = normalized_energy_valley_seed(seed)
  let central_x = 48 + energy_valley_signed_variation(normalized, 3, 2, 67, 3)
  let central_y = 43 + energy_valley_signed_variation(normalized, 3, 3, 71, 2)
  let learning_x = 80 + energy_valley_signed_variation(normalized, 4, 2, 73, 3)
  let learning_y = 39 + energy_valley_signed_variation(normalized, 4, 3, 79, 2)
  let south_x = 119 + energy_valley_signed_variation(normalized, 5, 2, 83, 4)
  let south_y = 57 + energy_valley_signed_variation(normalized, 5, 3, 89, 3)
  in_ellipse(grid_x, grid_y, central_x, central_y, 10, 6) ||
  in_ellipse(grid_x, grid_y, learning_x, learning_y, 7, 5) ||
  in_ellipse(grid_x, grid_y, south_x, south_y, 10, 13) ||
  (
    reference_lake_at(grid_x, grid_y) &&
    energy_valley_reference_water_core_at(grid_x, grid_y)
  )
}

///|
fn energy_valley_water_at(seed : Int, grid_x : Int, grid_y : Int) -> Bool {
  match energy_valley_preserved_reference_kind(seed, grid_x, grid_y) {
    Some(kind) => return kind == "river" || kind == "lake"
    None => ()
  }
  energy_valley_main_river_at(seed, grid_x, grid_y) ||
  energy_valley_tributary_at(seed, grid_x, grid_y) ||
  energy_valley_lake_at(seed, grid_x, grid_y) ||
  energy_valley_reference_water_core_at(grid_x, grid_y)
}

///|
fn energy_valley_near_water(
  seed : Int,
  grid_x : Int,
  grid_y : Int,
  radius : Int,
) -> Bool {
  for y_offset in 0..<(radius * 2 + 1) {
    for x_offset in 0..<(radius * 2 + 1) {
      if energy_valley_water_at(
          seed,
          grid_x + x_offset - radius,
          grid_y + y_offset - radius,
        ) {
        return true
      }
    }
  }
  false
}

///|
fn energy_valley_wetland_at(seed : Int, grid_x : Int, grid_y : Int) -> Bool {
  match energy_valley_preserved_reference_kind(seed, grid_x, grid_y) {
    Some(kind) => return kind == "wetland"
    None => ()
  }
  !energy_valley_water_at(seed, grid_x, grid_y) &&
  (
    energy_valley_near_water(seed, grid_x, grid_y, 3) ||
    (
      reference_wetland_at(grid_x, grid_y) &&
      energy_valley_variation(seed, grid_x, grid_y, 97, 5) != 0
    )
  )
}

///|
fn energy_valley_fallback_major_road_at(
  seed : Int,
  grid_x : Int,
  grid_y : Int,
) -> Bool {
  let grammar = energy_valley_grammar(seed)
  (abs_int(grid_y - grammar.north_road_y) <= 1 && grid_x >= 78 && grid_x <= 190) ||
  (abs_int(grid_y - grammar.civic_road_y) <= 1 && grid_x >= 76 && grid_x <= 194) ||
  (abs_int(grid_y - grammar.lake_road_y) <= 1 && grid_x >= 88 && grid_x <= 174) ||
  (
    abs_int(grid_y - grammar.south_road_y) <= 1 &&
    grid_x >= 112 &&
    grid_x <= 194
  ) ||
  (
    abs_int(grid_y - grammar.market_road_y) <= 1 &&
    grid_x >= 144 &&
    grid_x <= 198
  ) ||
  (abs_int(grid_x - grammar.west_road_x) <= 1 && grid_y >= 48 && grid_y <= 102) ||
  (abs_int(grid_x - grammar.civic_road_x) <= 1 && grid_y >= 48 && grid_y <= 116) ||
  (
    abs_int(grid_x - grammar.research_road_x) <= 1 &&
    grid_y >= 42 &&
    grid_y <= 116
  ) ||
  (abs_int(grid_x - grammar.east_road_x) <= 1 && grid_y >= 62 && grid_y <= 124)
}

///|
fn energy_valley_fallback_local_road_at(
  seed : Int,
  grid_x : Int,
  grid_y : Int,
) -> Bool {
  let north_lane = grid_x >= 96 &&
    grid_x <= 162 &&
    grid_y >= 43 &&
    grid_y <= 66 &&
    energy_valley_mod(grid_x - energy_valley_variation(seed, 6, 1, 103, 9), 13) ==
    0
  let lake_lane = grid_x >= 96 &&
    grid_x <= 170 &&
    grid_y >= 78 &&
    grid_y <= 108 &&
    energy_valley_mod(grid_y - energy_valley_variation(seed, 7, 1, 107, 8), 11) ==
    0
  let east_lane = grid_x >= 154 &&
    grid_x <= 194 &&
    grid_y >= 68 &&
    grid_y <= 124 &&
    energy_valley_mod(grid_x - energy_valley_variation(seed, 8, 1, 109, 7), 12) ==
    0
  north_lane || lake_lane || east_lane
}

///|
fn energy_valley_framework_major_road_at(
  seed : Int,
  grid_x : Int,
  grid_y : Int,
) -> Bool {
  if !reference_tile_snapshot_ready() {
    return energy_valley_fallback_major_road_at(seed, grid_x, grid_y)
  }
  match energy_valley_reference_road_kind_at(seed, grid_x, grid_y) {
    Some("road-major") => true
    _ =>
      if energy_valley_reference_road_gap_at(seed, grid_x, grid_y) {
        let mut major_neighbors = 0
        for y in (grid_y - 1)..<=(grid_y + 1) {
          for x in (grid_x - 1)..<=(grid_x + 1) {
            if energy_valley_reference_road_kind_at(seed, x, y) ==
              Some("road-major") {
              major_neighbors += 1
            }
          }
        }
        major_neighbors >= 2
      } else {
        false
      }
  }
}

///|
fn energy_valley_framework_local_road_at(
  seed : Int,
  grid_x : Int,
  grid_y : Int,
) -> Bool {
  if !reference_tile_snapshot_ready() {
    return energy_valley_fallback_local_road_at(seed, grid_x, grid_y)
  }
  match energy_valley_reference_road_kind_at(seed, grid_x, grid_y) {
    Some("road") | Some("bridge") => true
    _ =>
      energy_valley_reference_road_gap_at(seed, grid_x, grid_y) &&
      !energy_valley_framework_major_road_at(seed, grid_x, grid_y)
  }
}

///|
fn energy_valley_framework_road_at(
  seed : Int,
  grid_x : Int,
  grid_y : Int,
) -> Bool {
  energy_valley_framework_major_road_at(seed, grid_x, grid_y) ||
  energy_valley_framework_local_road_at(seed, grid_x, grid_y)
}

///|
fn energy_valley_major_road_at(seed : Int, grid_x : Int, grid_y : Int) -> Bool {
  energy_valley_framework_major_road_at(seed, grid_x, grid_y)
}

///|
fn energy_valley_local_road_at(seed : Int, grid_x : Int, grid_y : Int) -> Bool {
  energy_valley_framework_local_road_at(seed, grid_x, grid_y)
}

///|
fn energy_valley_road_at(seed : Int, grid_x : Int, grid_y : Int) -> Bool {
  energy_valley_framework_road_at(seed, grid_x, grid_y)
}

///|
fn energy_valley_bridge_at(seed : Int, grid_x : Int, grid_y : Int) -> Bool {
  match energy_valley_reference_road_kind_at(seed, grid_x, grid_y) {
    Some("bridge") => return true
    None => ()
    _ => ()
  }
  energy_valley_water_at(seed, grid_x, grid_y) &&
  (
    energy_valley_road_at(seed, grid_x, grid_y) ||
    reference_bridge_at(grid_x, grid_y)
  )
}

///|
fn energy_valley_district_at(seed : Int, grid_x : Int, grid_y : Int) -> String {
  let river_x = energy_valley_main_river_center_x(seed, grid_y)
  if grid_y < 62 {
    if grid_x < 132 {
      "north-innovation"
    } else {
      "north-research"
    }
  } else if in_rect(grid_x, grid_y, 108, 60, 150, 82) {
    "civic-core"
  } else if grid_x < 103 && grid_y >= 76 {
    "west-community"
  } else if grid_x < river_x - 9 {
    "west-research"
  } else if grid_x > river_x + 58 && grid_y < 100 {
    "east-river"
  } else if grid_x > 150 && grid_y < 92 {
    "east-research"
  } else if grid_y >= 103 || (grid_y >= 88 && grid_x > 150) {
    "south-showcase"
  } else if grid_y >= 80 && grid_x < 124 {
    "lake-learning"
  } else if grid_y >= 80 {
    "lake-exchange"
  } else {
    "civic-core"
  }
}

///|
fn energy_valley_forest_at(seed : Int, grid_x : Int, grid_y : Int) -> Bool {
  match energy_valley_preserved_reference_kind(seed, grid_x, grid_y) {
    Some(kind) => return kind == "forest"
    None => ()
  }
  let reference_weight = if reference_forest_at(grid_x, grid_y) { 3 } else { 0 }
  energy_valley_variation(seed, grid_x, grid_y, 113, 7) + reference_weight >= 6
}

///|
fn energy_valley_farm_at(seed : Int, grid_x : Int, grid_y : Int) -> Bool {
  match energy_valley_preserved_reference_kind(seed, grid_x, grid_y) {
    Some(kind) => return kind == "farm" || kind == "field"
    None => ()
  }
  let reference_weight = if reference_farm_at(grid_x, grid_y) { 2 } else { 0 }
  let district = energy_valley_district_at(seed, grid_x, grid_y)
  (district == "west-community" || district == "north-innovation") &&
  energy_valley_variation(seed, grid_x / 3, grid_y / 3, 127, 8) +
  reference_weight >=
  7
}

///|
fn energy_valley_tile_kind_at(seed : Int, grid_x : Int, grid_y : Int) -> String {
  if energy_valley_bridge_at(seed, grid_x, grid_y) {
    "bridge"
  } else if energy_valley_framework_road_at(seed, grid_x, grid_y) {
    if energy_valley_framework_major_road_at(seed, grid_x, grid_y) {
      "road-major"
    } else {
      "road"
    }
  } else {
    match energy_valley_preserved_reference_kind(seed, grid_x, grid_y) {
      Some(kind) => return kind
      None => ()
    }
    if energy_valley_water_at(seed, grid_x, grid_y) {
      if energy_valley_lake_at(seed, grid_x, grid_y) {
        "lake"
      } else {
        "river"
      }
    } else if energy_valley_road_at(seed, grid_x, grid_y) {
      if energy_valley_major_road_at(seed, grid_x, grid_y) {
        "road-major"
      } else {
        "road"
      }
    } else if energy_valley_wetland_at(seed, grid_x, grid_y) {
      "wetland"
    } else {
      let district = energy_valley_district_at(seed, grid_x, grid_y)
      if district == "civic-core" {
        if energy_valley_variation(seed, grid_x, grid_y, 131, 5) <= 1 {
          "campus"
        } else {
          "urban-dense"
        }
      } else if district == "lake-exchange" ||
        district == "south-showcase" ||
        district == "east-research" {
        if energy_valley_variation(seed, grid_x, grid_y, 137, 4) == 0 {
          "campus"
        } else {
          "urban"
        }
      } else if energy_valley_farm_at(seed, grid_x, grid_y) {
        if energy_valley_variation(seed, grid_x, grid_y, 139, 3) == 0 {
          "field"
        } else {
          "farm"
        }
      } else if energy_valley_forest_at(seed, grid_x, grid_y) {
        "forest"
      } else if energy_valley_variation(seed, grid_x, grid_y, 149, 19) == 0 {
        "grass-flower-pink"
      } else if energy_valley_variation(seed, grid_x, grid_y, 151, 23) == 0 {
        "grass-flower-yellow"
      } else if energy_valley_variation(seed, grid_x, grid_y, 157, 4) == 0 {
        "grass-light"
      } else {
        "grass"
      }
    }
  }
}

///|
fn energy_valley_buildable_at(seed : Int, grid_x : Int, grid_y : Int) -> Bool {
  !energy_valley_water_at(seed, grid_x, grid_y) &&
  !energy_valley_wetland_at(seed, grid_x, grid_y) &&
  !energy_valley_road_at(seed, grid_x, grid_y)
}
