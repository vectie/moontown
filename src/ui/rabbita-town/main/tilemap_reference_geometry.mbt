///|
fn abs_int(value : Int32) -> Int32 {
  if value < 0 {
    -value
  } else {
    value
  }
}

///|
fn in_rect(
  grid_x : Int32,
  grid_y : Int32,
  min_x : Int32,
  min_y : Int32,
  max_x : Int32,
  max_y : Int32,
) -> Bool {
  grid_x >= min_x && grid_x <= max_x && grid_y >= min_y && grid_y <= max_y
}

///|
fn in_ellipse(
  grid_x : Int32,
  grid_y : Int32,
  center_x : Int32,
  center_y : Int32,
  radius_x : Int32,
  radius_y : Int32,
) -> Bool {
  let dx = grid_x - center_x
  let dy = grid_y - center_y
  dx * dx * radius_y * radius_y + dy * dy * radius_x * radius_x <=
  radius_x * radius_x * radius_y * radius_y
}
