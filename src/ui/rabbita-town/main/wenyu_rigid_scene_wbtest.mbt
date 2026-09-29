///|
extern "js" fn wenyu_scene_test_location(
  search : String,
  restore : Bool,
) -> Unit =
  #| (search,restore) => {
  #|   if (restore) {
  #|     if (globalThis.__wenyuTestLocation === undefined) delete globalThis.location;
  #|     else globalThis.location=globalThis.__wenyuTestLocation;
  #|     delete globalThis.__wenyuTestLocation;
  #|   } else {
  #|     if (!('__wenyuTestLocation' in globalThis)) globalThis.__wenyuTestLocation=globalThis.location;
  #|     globalThis.location={search};
  #|   }
  #| }

///|
test "production uses restored scene without a trial query and keeps comparisons explicit" {
  wenyu_scene_test_location("", false)
  assert_true(wenyu_scene_default_requested())
  assert_true(wenyu_rigid_scene_active())
  wenyu_scene_test_location("?road-trial=gentle", false)
  assert_false(wenyu_scene_default_requested())
  assert_false(wenyu_rigid_scene_active())
  wenyu_scene_test_location("?road-trial=gentle&shore=1", false)
  assert_true(wenyu_rigid_scene_active())
  wenyu_scene_test_location("?registration-review=1", false)
  assert_false(wenyu_scene_default_requested())
  wenyu_scene_test_location("", true)
}

///|
test "corrected scene rectangle query includes its full footprint and apron" {
  let prefix = Array::make(257 * 145, 0)
  for y in 1..<=144 {
    for x in 1..<=256 {
      let i = y * 257 + x
      prefix[i] = (if x == 11 && y == 21 { 1 } else { 0 }) +
        prefix[i - 1] +
        prefix[i - 257] -
        prefix[i - 258]
    }
  }
  assert_false(wenyu_scene_region_clear(prefix, 9, 19, 3, 3))
  assert_true(wenyu_scene_region_clear(prefix, 11, 20, 3, 3))
  assert_false(wenyu_scene_region_clear(prefix, -1, 20, 3, 3))
  assert_false(wenyu_scene_region_clear(prefix, 255, 140, 3, 3))
}

///|
test "corrected scene walkers follow bends and reverse without endpoint jumps" {
  let path : WenyuScenePath = {
    points: [{ x: 0, y: 0, }, { x: 3, y: 0, }, { x: 3, y: 4, }],
    lengths: [0, 3, 7],
    total: 7,
  }
  let p = wenyu_scene_sample(path, 5)
  assert_eq(p.x, 3.0)
  assert_eq(p.y, 2.0)
  let before = wenyu_scene_sample(path, 6.99)
  let after = wenyu_scene_sample(path, 7.01)
  assert_true((before.x - after.x).abs() < 0.00001)
  assert_true((before.y - after.y).abs() < 0.00001)
  let wrap = wenyu_scene_sample(path, 14.01)
  assert_true((wrap.x - 0.01).abs() < 0.00001)
  assert_eq(wrap.y, 0.0)
}
