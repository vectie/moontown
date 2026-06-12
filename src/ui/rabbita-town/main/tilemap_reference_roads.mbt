///|
fn reference_major_road_at(grid_x : Int, grid_y : Int) -> Bool {
  abs_int(grid_y * 3 + grid_x * 2 - 142) <= 2 ||
  abs_int(grid_y * 2 - grid_x + 24) <= 1 ||
  (abs_int(grid_y - 35) <= 1 && grid_x < 100) ||
  (abs_int(grid_y - 55) <= 1 && grid_x > 20 && grid_x < 112) ||
  (abs_int(grid_x - 62) <= 1 && grid_y > 10 && grid_y < 58) ||
  (abs_int(grid_x - 94) <= 1 && grid_y > 20)
}

///|
fn reference_local_road_at(grid_x : Int, grid_y : Int) -> Bool {
  (
    in_rect(grid_x, grid_y, 7, 18, 38, 34) &&
    (grid_x % 7 == 0 || grid_y % 5 == 0)
  ) ||
  (
    in_rect(grid_x, grid_y, 31, 15, 69, 36) &&
    (grid_x % 6 == 0 || grid_y % 5 == 0)
  ) ||
  (
    in_rect(grid_x, grid_y, 14, 39, 43, 57) &&
    (grid_x % 5 == 0 || grid_y % 4 == 0)
  ) ||
  (
    in_rect(grid_x, grid_y, 48, 49, 86, 63) &&
    (grid_x % 6 == 0 || grid_y % 4 == 0)
  ) ||
  (
    in_rect(grid_x, grid_y, 92, 33, 118, 51) &&
    (grid_x % 5 == 0 || grid_y % 5 == 0)
  ) ||
  (
    in_rect(grid_x, grid_y, 88, 54, 123, 63) &&
    (grid_x % 6 == 0 || grid_y % 4 == 0)
  )
}

///|
fn reference_road_at(grid_x : Int, grid_y : Int) -> Bool {
  reference_major_road_at(grid_x, grid_y) ||
  reference_local_road_at(grid_x, grid_y)
}
