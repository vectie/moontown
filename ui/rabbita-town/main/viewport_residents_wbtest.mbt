///|
test "resident waypoint table keeps x and y coordinates together" {
  let first = viewport_resident_waypoint(0)
  assert_eq(first.grid_x, 34)
  assert_eq(first.grid_y, 32)
  let downtown = viewport_resident_waypoint(31)
  assert_eq(downtown.grid_x, 232)
  assert_eq(downtown.grid_y, 90)
  let river = viewport_resident_waypoint(48)
  assert_eq(river.grid_x, 22)
  assert_eq(river.grid_y, 30)
  let final_slot = viewport_resident_waypoint(63)
  assert_eq(final_slot.grid_x, 168)
  assert_eq(final_slot.grid_y, 80)
}

///|
test "resident waypoint table wraps roster indices" {
  let wrapped = viewport_resident_waypoint(64)
  assert_eq(wrapped.grid_x, viewport_resident_grid_x(0))
  assert_eq(wrapped.grid_y, viewport_resident_grid_y(0))
}
