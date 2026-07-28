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
  energy_valley_tile_kind_at(active_energy_valley_seed(), grid_x, grid_y)
}
