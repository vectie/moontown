///|
fn energy_valley_access_in_bounds(x : Int, y : Int) -> Bool {
  x >= 0 &&
  x < exact_energy_valley_cols() &&
  y >= 0 &&
  y < exact_energy_valley_rows()
}

///|
fn energy_valley_access_key(x : Int, y : Int) -> String {
  "\{x}:\{y}"
}

///|
fn energy_valley_access_is_road(
  tiles : Array[Array[ExactEnergyValleyTile]],
  x : Int,
  y : Int,
) -> Bool {
  if !energy_valley_access_in_bounds(x, y) {
    return false
  }
  let terrain = tiles[y][x].terrain
  terrain == "road" || terrain == "bridge"
}

///|
fn energy_valley_largest_road_component(
  tiles : Array[Array[ExactEnergyValleyTile]],
) -> Map[String, Bool] {
  let visited : Map[String, Bool] = Map([])
  let mut largest : Array[Int] = []
  let directions = [(0, -1), (1, 0), (0, 1), (-1, 0)]
  for y in 0..<exact_energy_valley_rows() {
    for x in 0..<exact_energy_valley_cols() {
      let origin_key = energy_valley_access_key(x, y)
      if visited.contains(origin_key) ||
        !energy_valley_access_is_road(tiles, x, y) {
        continue
      }
      let component : Array[Int] = []
      let queue : Array[Int] = [y * exact_energy_valley_cols() + x]
      visited[origin_key] = true
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
          let next_key = energy_valley_access_key(next_x, next_y)
          if energy_valley_access_in_bounds(next_x, next_y) &&
            !visited.contains(next_key) &&
            energy_valley_access_is_road(tiles, next_x, next_y) {
            visited[next_key] = true
            queue.push(next_y * exact_energy_valley_cols() + next_x)
          }
        }
      }
      if component.length() > largest.length() {
        largest = component
      }
    }
  }
  let result : Map[String, Bool] = Map([])
  for cell in largest {
    result[energy_valley_access_key(
      cell % exact_energy_valley_cols(),
      cell / exact_energy_valley_cols(),
    )] = true
  }
  result
}

///|
fn energy_valley_access_can_cross(
  tiles : Array[Array[ExactEnergyValleyTile]],
  x : Int,
  y : Int,
) -> Bool {
  if !energy_valley_access_in_bounds(x, y) {
    return false
  }
  let tile = tiles[y][x]
  tile.building_id is None && tile.terrain != "water"
}

///|
fn energy_valley_access_path_to_network(
  tiles : Array[Array[ExactEnergyValleyTile]],
  network : Map[String, Bool],
  start_x : Int,
  start_y : Int,
) -> Array[Int]? {
  if !energy_valley_access_in_bounds(start_x, start_y) {
    return None
  }
  let columns = exact_energy_valley_cols()
  let start = start_y * columns + start_x
  let queue : Array[Int] = [start]
  let seen : Map[String, Bool] = Map([])
  seen[energy_valley_access_key(start_x, start_y)] = true
  let previous : Map[String, Int] = Map([])
  // Cardinal BFS gives the shortest orthogonal spur into the shared road graph.
  let directions = [(0, -1), (1, 0), (0, 1), (-1, 0)]
  let mut head = 0
  let mut reached = -1
  while head < queue.length() {
    let current = queue[head]
    head += 1
    let current_x = current % columns
    let current_y = current / columns
    if network.contains(energy_valley_access_key(current_x, current_y)) {
      reached = current
      break
    }
    for direction in directions {
      let next_x = current_x + direction.0
      let next_y = current_y + direction.1
      let next_key = energy_valley_access_key(next_x, next_y)
      if !seen.contains(next_key) &&
        energy_valley_access_can_cross(tiles, next_x, next_y) {
        seen[next_key] = true
        previous[next_key] = current
        queue.push(next_y * columns + next_x)
      }
    }
  }
  if reached < 0 {
    return None
  }
  let reversed : Array[Int] = []
  let mut cursor = reached
  while cursor >= 0 {
    reversed.push(cursor)
    if cursor == start {
      break
    }
    let cursor_x = cursor % columns
    let cursor_y = cursor / columns
    cursor = previous
      .get(energy_valley_access_key(cursor_x, cursor_y))
      .unwrap_or(-1)
  }
  let result : Array[Int] = []
  let mut index = reversed.length() - 1
  while index >= 0 {
    result.push(reversed[index])
    index -= 1
  }
  Some(result)
}

///|
fn energy_valley_paint_access_spur(
  tiles : Array[Array[ExactEnergyValleyTile]],
  network : Map[String, Bool],
  path : Array[Int],
) -> Unit {
  let columns = exact_energy_valley_cols()
  for cell in path {
    let x = cell % columns
    let y = cell / columns
    let tile = tiles[y][x]
    if tile.terrain == "water" || tile.terrain == "bridge" {
      tile.terrain = "bridge"
      tile.base_terrain = "road"
      tile.generated_terrain = "road"
    } else {
      tile.terrain = "road"
      tile.base_terrain = "road"
      tile.generated_terrain = "road"
    }
    tile.structure = None
    tile.structure_floors = None
    tile.structure_width = None
    tile.structure_depth = None
    network[energy_valley_access_key(x, y)] = true
  }
}

///|
fn energy_valley_compile_building_access(
  tiles : Array[Array[ExactEnergyValleyTile]],
  buildings : Array[ExactEnergyValleyBuilding],
) -> Unit {
  let network = energy_valley_largest_road_component(tiles)
  // A map without a compiled corridor still gets one shared civic access
  // graph: the first entrance seeds it and later entrances connect to it.
  if network.is_empty() && !buildings.is_empty() {
    let first = buildings[0]
    let seed_path = [
      first.entrance_y * exact_energy_valley_cols() + first.entrance_x,
    ]
    energy_valley_paint_access_spur(tiles, network, seed_path)
  }
  for building in buildings {
    match
      energy_valley_access_path_to_network(
        tiles,
        network,
        building.entrance_x,
        building.entrance_y,
      ) {
      Some(path) => energy_valley_paint_access_spur(tiles, network, path)
      None => ()
    }
  }
}
