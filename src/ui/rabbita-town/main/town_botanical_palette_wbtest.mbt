///|
test "botanical palette produces six stable tree forms with waterside willows" {
  let kinds : Map[Int, Bool] = Map([])
  let mut willows = 0
  for i in 0..<100 {
    let seed = i.to_double() / 100.0
    let kind = town_botanical_tree_kind(i * 3, i * 7, seed, false)
    assert_eq(kind, town_botanical_tree_kind(i * 3, i * 7, seed, false))
    assert_true(kind >= 0 && kind < 6)
    kinds[kind] = true
    let wet = town_botanical_tree_kind(i * 3, i * 7, seed, true)
    kinds[wet] = true
    if wet == 3 {
      willows += 1
    }
  }
  assert_eq(kinds.length(), 6)
  assert_true(willows >= 50)
  assert_eq(town_botanical_tree_scale(-1), 0.78)
  assert_eq(town_botanical_tree_scale(2), 1.2)
}

///|
test "flower drifts offer four types and leave most ground quiet" {
  let kinds : Map[Int, Bool] = Map([])
  let mut planted = 0
  for y in 0..<144 {
    for x in 0..<256 {
      let kind = town_botanical_flower_kind(x, y)
      assert_eq(kind, town_botanical_flower_kind(x, y))
      if kind >= 0 {
        planted += 1
        kinds[kind] = true
      }
    }
  }
  assert_eq(kinds.length(), 4)
  assert_true(planted > 1500 && planted < 4500)
}
