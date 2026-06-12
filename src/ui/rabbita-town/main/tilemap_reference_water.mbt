///|
fn river_center_x_at(grid_y : Int) -> Int {
  74 + grid_y / 3 + (if grid_y % 18 < 9 { -2 } else { 2 })
}

///|
fn reference_river_at(grid_x : Int, grid_y : Int) -> Bool {
  let center = river_center_x_at(grid_y)
  (grid_y >= 7 && abs_int(grid_x - center) <= (if grid_y > 50 { 4 } else { 2 })) ||
  (
    grid_y >= 2 &&
    grid_y <= 13 &&
    abs_int(grid_x - (8 + grid_y * 2 + grid_y / 3)) <= 1
  ) ||
  (
    grid_y >= 38 &&
    grid_y <= 50 &&
    abs_int(grid_x - (43 + (grid_y - 38) * 3)) <= 2
  ) ||
  (grid_y >= 49 && grid_x >= 108 && in_ellipse(grid_x, grid_y, 118, 56, 9, 12))
}

///|
fn reference_lake_at(grid_x : Int, grid_y : Int) -> Bool {
  in_ellipse(grid_x, grid_y, 44, 42, 8, 5) ||
  in_ellipse(grid_x, grid_y, 52, 44, 6, 4) ||
  in_ellipse(grid_x, grid_y, 80, 38, 6, 4) ||
  in_ellipse(grid_x, grid_y, 13, 8, 5, 3) ||
  in_ellipse(grid_x, grid_y, 27, 8, 4, 2) ||
  in_ellipse(grid_x, grid_y, 75, 8, 7, 3)
}

///|
fn reference_water_at(grid_x : Int, grid_y : Int) -> Bool {
  reference_river_at(grid_x, grid_y) || reference_lake_at(grid_x, grid_y)
}

///|
fn reference_bridge_at(grid_x : Int, grid_y : Int) -> Bool {
  (
    grid_y >= 33 &&
    grid_y <= 36 &&
    abs_int(grid_x - river_center_x_at(grid_y)) <= 3
  ) ||
  (
    grid_y >= 54 &&
    grid_y <= 56 &&
    abs_int(grid_x - river_center_x_at(grid_y)) <= 4
  ) ||
  (grid_x >= 57 && grid_x <= 62 && grid_y >= 42 && grid_y <= 44) ||
  (grid_x >= 88 && grid_x <= 94 && grid_y >= 39 && grid_y <= 41) ||
  (grid_x >= 18 && grid_x <= 23 && grid_y >= 8 && grid_y <= 10)
}

///|
fn reference_wetland_at(grid_x : Int, grid_y : Int) -> Bool {
  let river_center = river_center_x_at(grid_y)
  (grid_y >= 7 && abs_int(grid_x - river_center) <= 5) ||
  in_ellipse(grid_x, grid_y, 47, 43, 13, 8) ||
  in_ellipse(grid_x, grid_y, 80, 39, 11, 7) ||
  in_ellipse(grid_x, grid_y, 20, 8, 12, 5) ||
  (
    grid_y >= 36 &&
    grid_y <= 52 &&
    abs_int(grid_x - (43 + (grid_y - 38) * 3)) <= 4
  )
}
