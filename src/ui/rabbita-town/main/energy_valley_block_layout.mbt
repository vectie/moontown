///|
/// One road-enclosed Wenyu block. Cells are encoded as `y * cols + x` so the
/// layout stays compact while every placement caller shares the same identity.
priv struct EnergyValleyRoadBlock {
  ordinal : Int
  anchor_x : Int
  anchor_y : Int
  min_x : Int
  min_y : Int
  max_x : Int
  max_y : Int
  cells : Array[Int]
}

///|
/// One dry four-neighbor region inside a road block. Water and wetland may
/// split a legal road enclosure into several placement regions without
/// changing the parent block identity.
priv struct EnergyValleyRoadBlockRegion {
  ordinal : Int
  block_ordinal : Int
  anchor_x : Int
  anchor_y : Int
  min_x : Int
  min_y : Int
  max_x : Int
  max_y : Int
  cells : Array[Int]
}

///|
/// Package-local placement authority. The canonical Wenyu road rows preserve
/// the 75 authored block identities; degraded startup derives the same shape
/// from the typed road graph available to the Canvas and pathfinder.
priv struct EnergyValleyRoadBlockLayout {
  blocks : Array[EnergyValleyRoadBlock]
  regions : Array[EnergyValleyRoadBlockRegion]
  block_by_tile : Array[Array[Int]]
  region_by_tile : Array[Array[Int]]
}

///|
fn energy_valley_int_grid(value : Int) -> Array[Array[Int]] {
  Array::makei(exact_energy_valley_rows(), _ => {
    Array::make(exact_energy_valley_cols(), value)
  })
}

///|
fn energy_valley_bool_grid(value : Bool) -> Array[Array[Bool]] {
  Array::makei(exact_energy_valley_rows(), _ => {
    Array::make(exact_energy_valley_cols(), value)
  })
}

///|
fn energy_valley_layout_cell_in_bounds(x : Int, y : Int) -> Bool {
  x >= 0 &&
  x < exact_energy_valley_cols() &&
  y >= 0 &&
  y < exact_energy_valley_rows()
}

///|
fn energy_valley_layout_cell_is_dry(seed : Int, x : Int, y : Int) -> Bool {
  !energy_valley_water_at(seed, x, y) && !energy_valley_wetland_at(seed, x, y)
}

///|
fn energy_valley_layout_cell_is_road(
  seed : Int,
  road_nodes : Map[String, @energy_valley_contract.RoadNode],
  x : Int,
  y : Int,
) -> Bool {
  if reference_road_graph_snapshot_ready() {
    let code = energy_valley_compiled_road_code_at(seed, x, y)
    code == "M" || code == "R" || code == "b"
  } else {
    ecosystem_road_network_node_at(road_nodes, x, y) is Some(_)
  }
}

///|
fn energy_valley_road_block_layout(
  seed : Int,
  road_network : @energy_valley_contract.RoadNetwork,
) -> EnergyValleyRoadBlockLayout {
  let cols = exact_energy_valley_cols()
  let rows = exact_energy_valley_rows()
  let road_nodes = ecosystem_road_network_node_lookup(road_network)
  let visited = energy_valley_bool_grid(false)
  let block_by_tile = energy_valley_int_grid(0)
  let blocks : Array[EnergyValleyRoadBlock] = []
  for start_y in 0..<rows {
    for start_x in 0..<cols {
      if visited[start_y][start_x] ||
        energy_valley_layout_cell_is_road(seed, road_nodes, start_x, start_y) {
        continue
      }
      let queue : Array[Int] = [start_y * cols + start_x]
      let cells : Array[Int] = []
      visited[start_y][start_x] = true
      let mut head = 0
      let mut touches_boundary = false
      let mut min_x = start_x
      let mut min_y = start_y
      let mut max_x = start_x
      let mut max_y = start_y
      while head < queue.length() {
        let encoded = queue[head]
        head += 1
        cells.push(encoded)
        let x = encoded % cols
        let y = encoded / cols
        min_x = min_x.min(x)
        min_y = min_y.min(y)
        max_x = max_x.max(x)
        max_y = max_y.max(y)
        if x == 0 || y == 0 || x == cols - 1 || y == rows - 1 {
          touches_boundary = true
        }
        for delta in [(0, -1), (1, 0), (0, 1), (-1, 0)] {
          let next_x = x + delta.0
          let next_y = y + delta.1
          if energy_valley_layout_cell_in_bounds(next_x, next_y) &&
            !visited[next_y][next_x] &&
            !energy_valley_layout_cell_is_road(seed, road_nodes, next_x, next_y) {
            visited[next_y][next_x] = true
            queue.push(next_y * cols + next_x)
          }
        }
      }
      if touches_boundary {
        continue
      }
      let ordinal = blocks.length() + 1
      for encoded in cells {
        block_by_tile[encoded / cols][encoded % cols] = ordinal
      }
      blocks.push({
        ordinal,
        anchor_x: min_x,
        anchor_y: min_y,
        min_x,
        min_y,
        max_x,
        max_y,
        cells,
      })
    }
  }
  let region_by_tile = energy_valley_int_grid(0)
  let regions : Array[EnergyValleyRoadBlockRegion] = []
  for block in blocks {
    for start in block.cells {
      let start_x = start % cols
      let start_y = start / cols
      if region_by_tile[start_y][start_x] != 0 ||
        !energy_valley_layout_cell_is_dry(seed, start_x, start_y) {
        continue
      }
      let ordinal = regions.length() + 1
      let queue : Array[Int] = [start]
      let cells : Array[Int] = []
      region_by_tile[start_y][start_x] = ordinal
      let mut head = 0
      let mut min_x = start_x
      let mut min_y = start_y
      let mut max_x = start_x
      let mut max_y = start_y
      while head < queue.length() {
        let encoded = queue[head]
        head += 1
        cells.push(encoded)
        let x = encoded % cols
        let y = encoded / cols
        min_x = min_x.min(x)
        min_y = min_y.min(y)
        max_x = max_x.max(x)
        max_y = max_y.max(y)
        for delta in [(0, -1), (1, 0), (0, 1), (-1, 0)] {
          let next_x = x + delta.0
          let next_y = y + delta.1
          if energy_valley_layout_cell_in_bounds(next_x, next_y) &&
            block_by_tile[next_y][next_x] == block.ordinal &&
            region_by_tile[next_y][next_x] == 0 &&
            energy_valley_layout_cell_is_dry(seed, next_x, next_y) {
            region_by_tile[next_y][next_x] = ordinal
            queue.push(next_y * cols + next_x)
          }
        }
      }
      regions.push({
        ordinal,
        block_ordinal: block.ordinal,
        anchor_x: min_x,
        anchor_y: min_y,
        min_x,
        min_y,
        max_x,
        max_y,
        cells,
      })
    }
  }
  { blocks, regions, block_by_tile, region_by_tile }
}

///|
fn energy_valley_road_block_layout_at(
  layout : EnergyValleyRoadBlockLayout,
  x : Int,
  y : Int,
) -> (Int, Int)? {
  if !energy_valley_layout_cell_in_bounds(x, y) {
    return None
  }
  let block = layout.block_by_tile[y][x]
  let region = layout.region_by_tile[y][x]
  if block > 0 && region > 0 {
    Some((block, region))
  } else {
    None
  }
}

///|
fn energy_valley_road_block_layout_for_footprint(
  layout : EnergyValleyRoadBlockLayout,
  x : Int,
  y : Int,
  width : Int,
  depth : Int,
) -> (Int, Int)? {
  let identity = match energy_valley_road_block_layout_at(layout, x, y) {
    Some(value) => value
    None => return None
  }
  for yy in y..<(y + depth) {
    for xx in x..<(x + width) {
      if energy_valley_road_block_layout_at(layout, xx, yy) != Some(identity) {
        return None
      }
    }
  }
  Some(identity)
}
