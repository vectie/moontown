///|
test "worker avatar placement uses worker yard grid slots" {
  let first = worker_avatar_placement_for_frame(
    "worker-yard",
    100,
    200,
    300,
    180,
    0,
  )
  assert_eq(first.left, 172)
  assert_eq(first.top, 220)
  let next_row = worker_avatar_placement_for_frame(
    "worker-yard",
    100,
    200,
    300,
    180,
    5,
  )
  assert_eq(next_row.left, 172)
  assert_eq(next_row.top, 254)
}

///|
test "worker avatar placement anchors city hall near lower right" {
  let placement = worker_avatar_placement_for_frame(
    "city-hall",
    610,
    100,
    280,
    180,
    4,
  )
  assert_eq(placement.left, 846)
  assert_eq(placement.top, 218)
}

///|
test "worker avatar placement shares default slot table" {
  let slot0 = worker_avatar_placement_for_frame("book-research", 80, 120, 180, 120, 0)
  assert_eq(slot0.left, 88)
  assert_eq(slot0.top, 194)
  let slot2 = worker_avatar_placement_for_frame("book-research", 80, 120, 180, 120, 2)
  assert_eq(slot2.left, 146)
  assert_eq(slot2.top, 166)
  let slot5 = worker_avatar_placement_for_frame("book-research", 80, 120, 180, 120, 5)
  assert_eq(slot5.left, 200)
  assert_eq(slot5.top, 212)
}

///|
test "worker avatar helpers keep initials status class and roster asset policy" {
  assert_eq(worker_avatar_initials("Mayor Keeper"), "MK")
  assert_eq(worker_avatar_initials("   "), "??")
  assert_eq(worker_status_class(@core.WorkerStatus::Blocked), "worker-blocked")
  assert_eq(worker_roster_asset(65), "tilemap/actors/roster/resident_1_walk_strip.png")
}

///|
test "worker wander helpers expose deterministic profile values" {
  assert_eq(worker_wander_x1(0), 28)
  assert_eq(worker_wander_y1(0), -12)
  assert_eq(worker_wander_x2(1), -42)
  assert_eq(worker_wander_y2(1), 16)
  assert_eq(worker_wander_x3(5), 18)
  assert_eq(worker_wander_y3(5), 18)
  assert_eq(worker_wander_duration(7), 6480)
}
