///|
test "no third floor slab fills the central atrium" {
  let p : Array[Part] = []
  interior_shell(p)
  for part in p {
    if part.layer == "floor" {
      let overlaps_x = part.position[0] + part.scale[0] / 2 >
        plan_x(540) + 0.00001 &&
        part.position[0] - part.scale[0] / 2 < plan_x(1150) - 0.00001
      let overlaps_z = part.position[2] + part.scale[2] / 2 >
        plan_z(705) + 0.00001 &&
        part.position[2] - part.scale[2] / 2 < plan_z(845) - 0.00001
      assert_true(!(overlaps_x && overlaps_z))
    }
  }
}

///|
test "furniture is finite and never placed inside the atrium" {
  let p : Array[Part] = []
  interior_furniture(p)
  for part in p {
    for v in [..part.position, ..part.scale] {
      assert_true(v.abs() < 1000)
    }
    for v in part.scale {
      assert_true(v > 0)
    }
    assert_true(
      !(part.position[0] > plan_x(540) &&
      part.position[0] < plan_x(1150) &&
      part.position[2] > plan_z(705) &&
      part.position[2] < plan_z(845)),
    )
  }
}

///|
test "rooms 304 and 307 have five and two real doorway gaps" {
  let p : Array[Part] = []
  interior_shell(p)
  let lintels = p.filter(part => {
    part.material == "metal" && part.position[1] == 2.91
  })
  assert_eq(
    lintels
    .filter(part => {
      part.position[2] == plan_z(885) &&
      part.position[0] > plan_x(540) &&
      part.position[0] < plan_x(1010)
    })
    .length(),
    5,
  )
  assert_eq(
    lintels
    .filter(part => {
      part.position[2] == plan_z(665) &&
      part.position[0] > plan_x(395) &&
      part.position[0] < plan_x(550)
    })
    .length(),
    2,
  )
}
