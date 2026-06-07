///|
test "viewport stage dimensions use scene size in embedded dashboard" {
  let scene = town_scene(init_model())
  let dimensions = viewport_stage_dimensions(false, scene)
  assert_eq(dimensions.width, scene.width)
  assert_eq(dimensions.height, scene.height)
}

///|
test "viewport stage dimensions use tilemap size in standalone viewport" {
  let scene = town_scene(init_model())
  let dimensions = viewport_stage_dimensions(true, scene)
  assert_eq(dimensions.width, tilemap_scene_width())
  assert_eq(dimensions.height, tilemap_scene_height())
}

///|
test "viewport stage style exposes width height and frame width" {
  let dimensions = { width: 640, height: 360 }
  let stage_style = viewport_stage_style(dimensions)
  let frame_style = viewport_frame_style(dimensions)
  assert_eq(stage_style.length(), 2)
  assert_eq(stage_style[0], "width: 640px")
  assert_eq(stage_style[1], "height: 360px")
  assert_eq(frame_style.length(), 1)
  assert_eq(frame_style[0], "--scene-width: 640px")
}
