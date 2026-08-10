///|
test "coordinate grid keeps a stable world scale across zoom levels" {
  assert_eq(energy_valley_coordinate_grid_spacing(0.20), 32)
  assert_eq(energy_valley_coordinate_grid_spacing(0.25), 32)
  assert_eq(energy_valley_coordinate_grid_spacing(0.26), 16)
  assert_eq(energy_valley_coordinate_grid_spacing(0.42), 16)
  assert_eq(energy_valley_coordinate_grid_spacing(0.74), 16)
  assert_eq(energy_valley_coordinate_grid_spacing(0.75), 8)
  assert_eq(energy_valley_coordinate_grid_spacing(1.80), 8)
}
