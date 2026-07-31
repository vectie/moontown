///|
test "ambient architecture grammar gives every Wenyu archetype a silhouette" {
  let expected = [
    ("lowrise", 2, ["ridge", "solar"]),
    ("row", 3, ["ridge"]),
    ("block", 2, ["terrace", "garden"]),
    ("tower", 3, ["crown"]),
    ("courtyard", 3, ["garden"]),
    ("campus", 3, ["solar", "garden"]),
    ("civic", 3, ["ridge"]),
    ("industrial", 3, ["sawtooth"]),
  ]
  for item in expected {
    let (structure, mass_count, roof_features) = item
    let plan = golden_architecture_plan(structure, 61, 43, 6, 5, 4)
    assert_eq(plan.masses.length(), mass_count)
    assert_true(roof_features.contains(plan.roof_feature))
    assert_true(plan.feature_index >= 0)
    assert_true(plan.feature_index < plan.masses.length())
  }
}

///|
test "ambient architecture masses stay inside their authored footprint" {
  for
    structure in [
      "lowrise", "row", "block", "tower", "courtyard", "campus", "civic", "industrial",
    ] {
    let plan = golden_architecture_plan(structure, 137, 72, 7, 4, 3)
    for mass in plan.masses {
      assert_true(mass.x_offset >= 0.0)
      assert_true(mass.y_offset >= 0.0)
      assert_true(mass.width > 0.0)
      assert_true(mass.depth > 0.0)
      assert_true(mass.x_offset + mass.width <= 7.0)
      assert_true(mass.y_offset + mass.depth <= 4.0)
      assert_true(mass.height > 0.0)
      assert_true(mass.window_columns >= 1)
      assert_true(mass.window_rows >= 1)
    }
  }
}

///|
test "ambient architecture variation is deterministic and bounded" {
  let first = golden_architecture_variant(137, 72, 7, 4, 3)
  let second = golden_architecture_variant(137, 72, 7, 4, 3)
  assert_eq(first, second)
  assert_true(first >= 0)
  assert_true(first <= 2)
  assert_true(golden_architecture_variant(138, 72, 7, 4, 3) != first)
}
