///|
test "default town scene layout defines semantic places and assets" {
  let layout = @ui.default_town_scene_layout()
  assert_eq(layout.width, 1280)
  assert_eq(layout.height, 720)
  assert_eq(layout.background.key, "town-square")
  assert_true(layout.areas.any(fn(area) { area.key == "city-hall" }))
  assert_true(layout.areas.any(fn(area) { area.key == "book-coding" }))
  assert_true(layout.areas.any(fn(area) { area.key == "worker-yard" }))
  assert_true(layout.assets.any(fn(asset) { asset.key == "mayor-claw" }))
  assert_true(layout.assets.any(fn(asset) { asset.key == "anomaly-signal" }))
}
