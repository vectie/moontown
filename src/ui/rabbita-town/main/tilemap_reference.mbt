///|
fn tile_kind_for_reference_code(code : String) -> String {
  match code {
    "." => "grass"
    "g" => "grass-light"
    "G" => "forest"
    "p" => "grass-flower-pink"
    "y" => "grass-flower-yellow"
    "f" => "farm"
    "F" => "field"
    "r" => "river"
    "l" => "lake"
    "w" => "wetland"
    "b" => "bridge"
    "M" => "road-major"
    "R" => "road"
    "u" => "urban"
    "U" => "urban-dense"
    "c" => "campus"
    _ => ""
  }
}

///|
fn reference_tile_kind_at(grid_x : Int, grid_y : Int) -> String? {
  let kind = tile_kind_for_reference_code(
    reference_tile_code_at(grid_x, grid_y),
  )
  if kind == "" {
    None
  } else {
    Some(kind)
  }
}

///|
fn tile_kind_at(grid_x : Int, grid_y : Int) -> String {
  match reference_tile_kind_at(grid_x, grid_y) {
    Some(kind) => kind
    None =>
      if reference_water_at(grid_x, grid_y) {
        if reference_bridge_at(grid_x, grid_y) {
          "bridge"
        } else if reference_lake_at(grid_x, grid_y) {
          "lake"
        } else {
          "river"
        }
      } else if reference_road_at(grid_x, grid_y) {
        if reference_major_road_at(grid_x, grid_y) {
          "road-major"
        } else {
          "road"
        }
      } else if reference_wetland_at(grid_x, grid_y) {
        "wetland"
      } else if reference_campus_at(grid_x, grid_y) {
        "campus"
      } else if reference_dense_urban_at(grid_x, grid_y) {
        "urban-dense"
      } else if reference_urban_at(grid_x, grid_y) {
        "urban"
      } else if reference_farm_at(grid_x, grid_y) {
        if (grid_x + grid_y) % 4 == 0 {
          "field"
        } else {
          "farm"
        }
      } else if reference_forest_at(grid_x, grid_y) {
        "forest"
      } else if (grid_x + grid_y) % 11 == 0 {
        "grass-flower-pink"
      } else if (grid_x * 3 + grid_y) % 13 == 0 {
        "grass-flower-yellow"
      } else if (grid_x + grid_y) % 4 == 0 {
        "grass-light"
      } else if (grid_x * 2 + grid_y) % 5 == 0 {
        "grass-dark"
      } else {
        "grass"
      }
  }
}
