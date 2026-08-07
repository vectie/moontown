///|
test "polygon clipping preserves a convex irregular block" {
  let source = provenance("wenyu-block-labels", "v1", WenyuReference, Fixed)
  let block = land_block_seed(
    stable_id("land-block", "trapezoid").unwrap(),
    polygon([
      world_point(5.0, 0.0),
      world_point(35.0, 0.0),
      world_point(40.0, 20.0),
      world_point(0.0, 20.0),
    ]),
    MixedUse,
    [],
    Fixed,
    source,
    parcel_grammar(
      4,
      split_axis=VerticalBands,
      variation=Statistical,
      minimum_area_sqm=10.0,
    ),
  )
  let geometries = compiled_parcel_geometries(block, 77)
  assert_eq(geometries.length(), 4)
  let mut total_area = 0.0
  for geometry in geometries {
    assert_true(geometry.boundary.is_well_formed())
    total_area = total_area + geometry.boundary.area()
    for vertex in geometry.boundary.vertices {
      assert_true(block.boundary.contains_point(vertex))
    }
  }
  assert_true((total_area - block.boundary.area()).abs() < 0.0001)
}

///|
test "deterministic number is stable and seed-sensitive" {
  assert_eq(
    deterministic_number(20260727, "parcel/energy-core/1"),
    deterministic_number(20260727, "parcel/energy-core/1"),
  )
  assert_true(
    deterministic_number(20260727, "parcel/energy-core/1") !=
    deterministic_number(20260728, "parcel/energy-core/1"),
  )
}
