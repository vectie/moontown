///|
fn reference_dense_urban_at(grid_x : Int, grid_y : Int) -> Bool {
  in_rect(grid_x, grid_y, 35, 16, 69, 34) ||
  in_rect(grid_x, grid_y, 88, 54, 123, 63) ||
  in_rect(grid_x, grid_y, 95, 35, 116, 48)
}

///|
fn reference_urban_at(grid_x : Int, grid_y : Int) -> Bool {
  reference_dense_urban_at(grid_x, grid_y) ||
  in_rect(grid_x, grid_y, 13, 39, 43, 57) ||
  in_rect(grid_x, grid_y, 48, 49, 86, 63) ||
  in_rect(grid_x, grid_y, 7, 8, 30, 18) ||
  in_rect(grid_x, grid_y, 70, 34, 84, 50)
}

///|
fn reference_campus_at(grid_x : Int, grid_y : Int) -> Bool {
  in_rect(grid_x, grid_y, 52, 37, 65, 47) ||
  in_rect(grid_x, grid_y, 79, 51, 91, 61) ||
  in_rect(grid_x, grid_y, 102, 27, 121, 33)
}

///|
fn reference_farm_at(grid_x : Int, grid_y : Int) -> Bool {
  in_rect(grid_x, grid_y, 70, 18, 88, 33) ||
  in_rect(grid_x, grid_y, 6, 20, 36, 34) ||
  in_rect(grid_x, grid_y, 2, 49, 18, 63) ||
  in_rect(grid_x, grid_y, 105, 8, 127, 25)
}

///|
fn reference_forest_at(grid_x : Int, grid_y : Int) -> Bool {
  grid_y < 7 ||
  (grid_x < 7 && grid_y > 36) ||
  (grid_y > 58 && grid_x < 48) ||
  (grid_x > 96 && grid_y < 30) ||
  in_ellipse(grid_x, grid_y, 9, 50, 11, 10) ||
  in_ellipse(grid_x, grid_y, 92, 13, 13, 9)
}
