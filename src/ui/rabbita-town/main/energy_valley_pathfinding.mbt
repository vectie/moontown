///|
fn golden_valley_walkable(model : Model, seed : Int, x : Int, y : Int) -> Bool {
  if x < 0 || x >= golden_valley_cols() || y < 0 || y >= golden_valley_rows() {
    return false
  }
  let terrain = golden_valley_terrain(model, seed, x, y)
  terrain == "road" || terrain == "bridge"
}

///|
fn golden_valley_nearest_road(
  model : Model,
  seed : Int,
  building : GoldenValleyBuilding,
) -> (Int, Int)? {
  let candidates : Array[(Int, Int)] = []
  for x in (building.x - 1)..<=(building.x + building.width) {
    candidates.push((x, building.y - 1))
    candidates.push((x, building.y + building.depth))
  }
  for y in (building.y - 1)..<=(building.y + building.depth) {
    candidates.push((building.x - 1, y))
    candidates.push((building.x + building.width, y))
  }
  for candidate in candidates {
    if golden_valley_walkable(model, seed, candidate.0, candidate.1) {
      return Some(candidate)
    }
  }
  None
}

///|
fn golden_valley_road_path(
  model : Model,
  seed : Int,
  start : (Int, Int),
  destination : (Int, Int),
) -> Array[(Double, Double)]? {
  if start == destination {
    return Some([(start.0.to_double() + 0.5, start.1.to_double() + 0.5)])
  }
  let columns = golden_valley_cols()
  let queue : Array[Int] = [start.1 * columns + start.0]
  let seen : Map[String, Bool] = {}
  seen[golden_valley_tile_key(start.0, start.1)] = true
  let previous : Map[String, Int] = {}
  let directions = [(0, -1), (1, 0), (0, 1), (-1, 0)]
  let mut head = 0
  let mut reached = -1
  while head < queue.length() {
    let current = queue[head]
    head = head + 1
    let current_x = current % columns
    let current_y = current / columns
    if current_x == destination.0 && current_y == destination.1 {
      reached = current
      break
    }
    for direction in directions {
      let next_x = current_x + direction.0
      let next_y = current_y + direction.1
      let key = golden_valley_tile_key(next_x, next_y)
      if !seen.contains(key) &&
        golden_valley_walkable(model, seed, next_x, next_y) {
        seen[key] = true
        previous[key] = current
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
    let cursor_x = cursor % columns
    let cursor_y = cursor / columns
    cursor = previous
      .get(golden_valley_tile_key(cursor_x, cursor_y))
      .unwrap_or(-1)
  }
  let path : Array[(Double, Double)] = []
  let mut index = reversed.length() - 1
  while index >= 0 {
    let tile = reversed[index]
    path.push(
      ((tile % columns).to_double() + 0.5, (tile / columns).to_double() + 0.5),
    )
    index = index - 1
  }
  Some(path)
}

///|
fn golden_valley_building_road_path(
  model : Model,
  seed : Int,
  from : GoldenValleyBuilding,
  destination : GoldenValleyBuilding,
) -> Array[(Double, Double)]? {
  match
    (
      golden_valley_nearest_road(model, seed, from),
      golden_valley_nearest_road(model, seed, destination),
    ) {
    (Some(start), Some(end)) => golden_valley_road_path(model, seed, start, end)
    _ => None
  }
}

///|
fn golden_valley_path_point(
  path : Array[(Double, Double)],
  distance : Double,
) -> (Double, Double)? {
  if path.length() < 2 || distance >= (path.length() - 1).to_double() {
    return None
  }
  let clamped = if distance < 0.0 { 0.0 } else { distance }
  let index = clamped.floor().to_int()
  let fraction = clamped - index.to_double()
  let current = path[index]
  let next = path[index + 1]
  Some(
    (
      current.0 + (next.0 - current.0) * fraction,
      current.1 + (next.1 - current.1) * fraction,
    ),
  )
}
