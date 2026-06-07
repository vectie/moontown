///|
fn abs_int(value : Int) -> Int {
  if value < 0 {
    -value
  } else {
    value
  }
}

///|
fn in_rect(
  grid_x : Int,
  grid_y : Int,
  min_x : Int,
  min_y : Int,
  max_x : Int,
  max_y : Int,
) -> Bool {
  grid_x >= min_x && grid_x <= max_x && grid_y >= min_y && grid_y <= max_y
}

///|
fn in_ellipse(
  grid_x : Int,
  grid_y : Int,
  center_x : Int,
  center_y : Int,
  radius_x : Int,
  radius_y : Int,
) -> Bool {
  let dx = grid_x - center_x
  let dy = grid_y - center_y
  dx * dx * radius_y * radius_y + dy * dy * radius_x * radius_x <=
  radius_x * radius_x * radius_y * radius_y
}
