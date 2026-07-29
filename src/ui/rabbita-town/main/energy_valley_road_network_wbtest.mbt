///|
fn energy_valley_test_road_count(mask : Array[Array[Bool]]) -> Int {
  let mut count = 0
  for row in mask {
    for cell in row {
      if cell {
        count += 1
      }
    }
  }
  count
}

///|
fn energy_valley_test_cardinal_component_size(
  mask : Array[Array[Bool]],
  start_x : Int,
  start_y : Int,
) -> Int {
  let visited = energy_valley_road_bool_grid(false)
  let queue : Array[Int] = [start_y * exact_energy_valley_cols() + start_x]
  visited[start_y][start_x] = true
  let mut head = 0
  while head < queue.length() {
    let cell = queue[head]
    head += 1
    let x = cell % exact_energy_valley_cols()
    let y = cell / exact_energy_valley_cols()
    for direction in [(0, -1), (1, 0), (0, 1), (-1, 0)] {
      let next_x = x + direction.0
      let next_y = y + direction.1
      if energy_valley_access_in_bounds(next_x, next_y) &&
        mask[next_y][next_x] &&
        !visited[next_y][next_x] {
        visited[next_y][next_x] = true
        queue.push(next_y * exact_energy_valley_cols() + next_x)
      }
    }
  }
  queue.length()
}

///|
test "fragmented block boundaries compile into one cardinal road graph" {
  let source = energy_valley_road_bool_grid(false)
  for x in 72..<=132 {
    if (x - 72) % 4 == 0 {
      source[56][x] = true
      source[88][x] = true
    }
  }
  for y in 56..<=88 {
    if (y - 56) % 4 == 0 {
      source[y][72] = true
      source[y][102] = true
      source[y][132] = true
    }
  }
  let network = energy_valley_thin_road_source(source)
  energy_valley_remove_tiny_road_fragments(network)
  energy_valley_orthogonalize_road_network(
    network, source, default_energy_valley_seed,
  )
  let total = energy_valley_test_road_count(network)
  assert_true(total > 120)
  let mut start_x = -1
  let mut start_y = -1
  for y in 0..<exact_energy_valley_rows() {
    for x in 0..<exact_energy_valley_cols() {
      if start_x < 0 && network[y][x] {
        start_x = x
        start_y = y
      }
    }
  }
  assert_true(start_x >= 0)
  assert_eq(
    energy_valley_test_cardinal_component_size(network, start_x, start_y),
    total,
  )
  for y in 0..<(exact_energy_valley_rows() - 1) {
    for x in 0..<(exact_energy_valley_cols() - 1) {
      if network[y][x] && network[y + 1][x + 1] {
        assert_true(network[y][x + 1] || network[y + 1][x])
      }
      if network[y + 1][x] && network[y][x + 1] {
        assert_true(network[y][x] || network[y + 1][x + 1])
      }
    }
  }
}
