///|
fn energy_valley_road_bool_grid(value : Bool) -> Array[Array[Bool]] {
  let result : Array[Array[Bool]] = []
  for _ in 0..<exact_energy_valley_rows() {
    let row : Array[Bool] = []
    for _ in 0..<exact_energy_valley_cols() {
      row.push(value)
    }
    result.push(row)
  }
  result
}

///|
fn energy_valley_source_road_tile(tile : ExactEnergyValleyTile) -> Bool {
  tile.base_terrain == "road-major" ||
  tile.base_terrain == "road" ||
  tile.base_terrain == "bridge"
}

///|
fn energy_valley_raw_road_source(
  tiles : Array[Array[ExactEnergyValleyTile]],
) -> Array[Array[Bool]] {
  let result = energy_valley_road_bool_grid(false)
  for y in 0..<exact_energy_valley_rows() {
    for x in 0..<exact_energy_valley_cols() {
      result[y][x] = energy_valley_source_road_tile(tiles[y][x])
    }
  }
  result
}

///|
fn energy_valley_compiled_road_code_at(seed : Int, x : Int, y : Int) -> String {
  reference_road_graph_code_at(
    x - energy_valley_road_pattern_shift_x(seed),
    y - energy_valley_road_pattern_shift_y(seed),
  )
}

///|
fn energy_valley_reference_road_source(
  tiles : Array[Array[ExactEnergyValleyTile]],
  seed : Int,
) -> Array[Array[Bool]] {
  if !reference_road_graph_snapshot_ready() {
    return energy_valley_raw_road_source(tiles)
  }
  let result = energy_valley_road_bool_grid(false)
  for y in 0..<exact_energy_valley_rows() {
    for x in 0..<exact_energy_valley_cols() {
      let code = energy_valley_compiled_road_code_at(seed, x, y)
      result[y][x] = code == "M" || code == "R" || code == "b"
    }
  }
  result
}

///|
fn energy_valley_dilate_road_source(
  source : Array[Array[Bool]],
  radius : Int,
) -> Array[Array[Bool]] {
  let result = energy_valley_road_bool_grid(false)
  for y in 0..<exact_energy_valley_rows() {
    for x in 0..<exact_energy_valley_cols() {
      for yy in (y - radius)..<=(y + radius) {
        for xx in (x - radius)..<=(x + radius) {
          if energy_valley_access_in_bounds(xx, yy) && source[yy][xx] {
            result[y][x] = true
          }
        }
      }
    }
  }
  result
}

///|
fn energy_valley_road_neighbor_values(
  mask : Array[Array[Bool]],
  x : Int,
  y : Int,
) -> Array[Bool] {
  [
    mask[y - 1][x],
    mask[y - 1][x + 1],
    mask[y][x + 1],
    mask[y + 1][x + 1],
    mask[y + 1][x],
    mask[y + 1][x - 1],
    mask[y][x - 1],
    mask[y - 1][x - 1],
  ]
}

///|
fn energy_valley_road_transition_count(neighbors : Array[Bool]) -> Int {
  let mut transitions = 0
  for index in 0..<neighbors.length() {
    if !neighbors[index] && neighbors[(index + 1) % neighbors.length()] {
      transitions += 1
    }
  }
  transitions
}

///|
fn energy_valley_road_true_count(neighbors : Array[Bool]) -> Int {
  let mut count = 0
  for neighbor in neighbors {
    if neighbor {
      count += 1
    }
  }
  count
}

///|
fn energy_valley_thin_road_pass(
  mask : Array[Array[Bool]],
  second_pass : Bool,
) -> Bool {
  let removals : Array[(Int, Int)] = []
  for y in 1..<(exact_energy_valley_rows() - 1) {
    for x in 1..<(exact_energy_valley_cols() - 1) {
      if !mask[y][x] {
        continue
      }
      let neighbors = energy_valley_road_neighbor_values(mask, x, y)
      let count = energy_valley_road_true_count(neighbors)
      if count < 2 ||
        count > 6 ||
        energy_valley_road_transition_count(neighbors) != 1 {
        continue
      }
      let north = neighbors[0]
      let east = neighbors[2]
      let south = neighbors[4]
      let west = neighbors[6]
      let blocks_first = if second_pass {
        north && east && west
      } else {
        north && east && south
      }
      let blocks_second = if second_pass {
        north && south && west
      } else {
        east && south && west
      }
      if !blocks_first && !blocks_second {
        removals.push((x, y))
      }
    }
  }
  for point in removals {
    mask[point.1][point.0] = false
  }
  !removals.is_empty()
}

///|
fn energy_valley_thin_road_source(
  source : Array[Array[Bool]],
) -> Array[Array[Bool]] {
  let result = energy_valley_dilate_road_source(source, 2)
  let mut changed = true
  let mut iterations = 0
  while changed && iterations < 96 {
    changed = energy_valley_thin_road_pass(result, false)
    if energy_valley_thin_road_pass(result, true) {
      changed = true
    }
    iterations += 1
  }
  result
}

///|
fn energy_valley_remove_tiny_road_fragments(mask : Array[Array[Bool]]) -> Unit {
  let visited = energy_valley_road_bool_grid(false)
  let directions = [
    (0, -1),
    (1, -1),
    (1, 0),
    (1, 1),
    (0, 1),
    (-1, 1),
    (-1, 0),
    (-1, -1),
  ]
  for y in 0..<exact_energy_valley_rows() {
    for x in 0..<exact_energy_valley_cols() {
      if !mask[y][x] || visited[y][x] {
        continue
      }
      let component : Array[Int] = []
      let queue : Array[Int] = [y * exact_energy_valley_cols() + x]
      visited[y][x] = true
      let mut head = 0
      while head < queue.length() {
        let cell = queue[head]
        head += 1
        component.push(cell)
        let cell_x = cell % exact_energy_valley_cols()
        let cell_y = cell / exact_energy_valley_cols()
        for direction in directions {
          let next_x = cell_x + direction.0
          let next_y = cell_y + direction.1
          if energy_valley_access_in_bounds(next_x, next_y) &&
            mask[next_y][next_x] &&
            !visited[next_y][next_x] {
            visited[next_y][next_x] = true
            queue.push(next_y * exact_energy_valley_cols() + next_x)
          }
        }
      }
      if component.length() < 8 {
        for cell in component {
          mask[cell / exact_energy_valley_cols()][cell %
          exact_energy_valley_cols()] = false
        }
      }
    }
  }
}

///|
fn energy_valley_source_road_score(
  source : Array[Array[Bool]],
  x : Int,
  y : Int,
) -> Int {
  let mut score = 0
  for yy in (y - 1)..<=(y + 1) {
    for xx in (x - 1)..<=(x + 1) {
      if energy_valley_access_in_bounds(xx, yy) && source[yy][xx] {
        score += 1
      }
    }
  }
  score
}

///|
fn energy_valley_orthogonalize_road_network(
  network : Array[Array[Bool]],
  source : Array[Array[Bool]],
  seed : Int,
) -> Unit {
  for y in 0..<(exact_energy_valley_rows() - 1) {
    for x in 0..<(exact_energy_valley_cols() - 1) {
      if network[y][x] &&
        network[y + 1][x + 1] &&
        !network[y][x + 1] &&
        !network[y + 1][x] {
        let east_score = energy_valley_source_road_score(source, x + 1, y)
        let south_score = energy_valley_source_road_score(source, x, y + 1)
        if east_score > south_score ||
          (
            east_score == south_score &&
            energy_valley_variation(seed, x, y, 719, 2) == 0
          ) {
          network[y][x + 1] = true
        } else {
          network[y + 1][x] = true
        }
      }
      if network[y + 1][x] &&
        network[y][x + 1] &&
        !network[y][x] &&
        !network[y + 1][x + 1] {
        let north_score = energy_valley_source_road_score(source, x, y)
        let southeast_score = energy_valley_source_road_score(
          source,
          x + 1,
          y + 1,
        )
        if north_score > southeast_score ||
          (
            north_score == southeast_score &&
            energy_valley_variation(seed, x, y, 727, 2) == 0
          ) {
          network[y][x] = true
        } else {
          network[y + 1][x + 1] = true
        }
      }
    }
  }
}

///|
fn energy_valley_road_fill_kind(
  tiles : Array[Array[ExactEnergyValleyTile]],
  x : Int,
  y : Int,
) -> String {
  let mut dense = 0
  let mut urban = 0
  let mut campus = 0
  let mut water = 0
  let mut forest = 0
  let mut farm = 0
  let mut grass = 0
  for yy in (y - 2)..<=(y + 2) {
    for xx in (x - 2)..<=(x + 2) {
      if !energy_valley_access_in_bounds(xx, yy) {
        continue
      }
      match tiles[yy][xx].base_terrain {
        "urban-dense" => dense += 1
        "urban" => urban += 1
        "campus" => campus += 1
        "river" | "lake" => water += 1
        "forest" => forest += 1
        "farm" | "field" => farm += 1
        "road-major" | "road" | "bridge" => ()
        _ => grass += 1
      }
    }
  }
  let mut kind = "grass"
  let mut score = grass
  if farm > score {
    kind = "farm"
    score = farm
  }
  if forest > score {
    kind = "forest"
    score = forest
  }
  if water > score {
    kind = "river"
    score = water
  }
  if campus > score {
    kind = "campus"
    score = campus
  }
  if urban > score {
    kind = "urban"
    score = urban
  }
  if dense > score {
    kind = "urban-dense"
  }
  kind
}

///|
fn energy_valley_major_road_source_near(
  tiles : Array[Array[ExactEnergyValleyTile]],
  x : Int,
  y : Int,
) -> Bool {
  for yy in (y - 2)..<=(y + 2) {
    for xx in (x - 2)..<=(x + 2) {
      if energy_valley_access_in_bounds(xx, yy) &&
        tiles[yy][xx].base_terrain == "road-major" {
        return true
      }
    }
  }
  false
}

///|
fn energy_valley_compile_reference_road_network(
  tiles : Array[Array[ExactEnergyValleyTile]],
  seed : Int,
) -> Unit {
  if !reference_tile_snapshot_ready() {
    return
  }
  let raw_source = energy_valley_raw_road_source(tiles)
  let source = energy_valley_reference_road_source(tiles, seed)
  let network = if reference_road_graph_snapshot_ready() {
    source
  } else {
    energy_valley_thin_road_source(source)
  }
  energy_valley_remove_tiny_road_fragments(network)
  energy_valley_orthogonalize_road_network(network, source, seed)
  let fill_kinds : Array[Array[String]] = []
  for y in 0..<exact_energy_valley_rows() {
    let row : Array[String] = []
    for x in 0..<exact_energy_valley_cols() {
      row.push(energy_valley_road_fill_kind(tiles, x, y))
    }
    fill_kinds.push(row)
  }
  for y in 0..<exact_energy_valley_rows() {
    for x in 0..<exact_energy_valley_cols() {
      let tile = tiles[y][x]
      if network[y][x] {
        let fill_kind = fill_kinds[y][x]
        let compiled_code = energy_valley_compiled_road_code_at(seed, x, y)
        let bridge = compiled_code == "b" ||
          fill_kind == "river" ||
          fill_kind == "lake"
        let road_kind = if bridge {
          "bridge"
        } else if compiled_code == "M" ||
          energy_valley_major_road_source_near(tiles, x, y) {
          "road-major"
        } else {
          "road"
        }
        tile.terrain = if bridge { "bridge" } else { "road" }
        tile.base_terrain = road_kind
        tile.generated_terrain = road_kind
        tile.river_flow = None
      } else if raw_source[y][x] {
        let fill_kind = fill_kinds[y][x]
        tile.terrain = exact_energy_valley_canvas_terrain(fill_kind)
        tile.base_terrain = fill_kind
        tile.generated_terrain = fill_kind
        tile.river_flow = if fill_kind == "river" || fill_kind == "lake" {
          Some(0.7)
        } else {
          None
        }
      }
    }
  }
}
