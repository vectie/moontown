///|
fn compiler_test_id(scope : String, key : String) -> StableId {
  stable_id(scope, key).unwrap()
}

///|
fn compiler_test_source() -> Provenance {
  provenance("wenyu-block-labels", "v1", WenyuReference, Fixed)
}

///|
fn compiler_test_rectangle(
  left : Double,
  top : Double,
  right : Double,
  bottom : Double,
) -> Polygon {
  polygon([
    world_point(left, top),
    world_point(right, top),
    world_point(right, bottom),
    world_point(left, bottom),
  ])
}

///|
fn compiler_test_roads() -> RoadNetwork {
  let source = compiler_test_source()
  let west_a = compiler_test_id("road-node", "west-a")
  let west_b = compiler_test_id("road-node", "west-b")
  let east_a = compiler_test_id("road-node", "east-a")
  let east_b = compiler_test_id("road-node", "east-b")
  road_network(
    [
      road_node(west_a, grid_position(0, 0), world_point(0.0, 0.0), source),
      road_node(west_b, grid_position(20, 0), world_point(20.0, 0.0), source),
      road_node(east_a, grid_position(40, 0), world_point(40.0, 0.0), source),
      road_node(east_b, grid_position(60, 0), world_point(60.0, 0.0), source),
    ],
    [
      road_segment(
        compiler_test_id("road-segment", "west"),
        west_a,
        west_b,
        [world_point(0.0, 0.0), world_point(20.0, 0.0)],
        Local,
        8.0,
        [Pedestrian],
        source,
      ),
      road_segment(
        compiler_test_id("road-segment", "east"),
        east_a,
        east_b,
        [world_point(40.0, 0.0), world_point(60.0, 0.0)],
        Local,
        8.0,
        [Pedestrian],
        source,
      ),
    ],
    [west_a],
  )
}

///|
fn compiler_test_seed(
  variation : PreservationLevel,
  target_count? : Int = 3,
) -> LandBlockSeed {
  land_block_seed(
    compiler_test_id("land-block", "research-core"),
    compiler_test_rectangle(0.0, 0.0, 60.0, 30.0),
    Research,
    [
      compiler_test_id("road-segment", "west"),
      compiler_test_id("road-segment", "east"),
    ],
    Fixed,
    compiler_test_source(),
    parcel_grammar(
      target_count,
      split_axis=VerticalBands,
      variation~,
      minimum_area_sqm=100.0,
    ),
  )
}

///|
fn compiler_test_programs() -> Array[ParcelProgram] {
  [
    parcel_program(
      compiler_test_id("parcel-program", "garden-court"),
      "Garden court",
      [Research, MixedUse],
      minimum_area_sqm=100.0,
      weight=30,
    ),
    parcel_program(
      compiler_test_id("parcel-program", "street-lab"),
      "Street research lab",
      [Research],
      minimum_area_sqm=100.0,
      requires_frontage=true,
      weight=70,
    ),
  ]
}

///|
fn compiler_test_plan(
  seed : Int,
  variation? : PreservationLevel = Bounded,
) -> ParcelPlan {
  compile_parcel_plan(
    "v2",
    seed,
    compiler_test_roads(),
    [compiler_test_seed(variation)],
    compiler_test_programs(),
  ).unwrap()
}

///|
test "parcel compiler is deterministic and input-order independent" {
  let programs = compiler_test_programs()
  let first = compile_parcel_plan(
    "v2",
    20260727,
    compiler_test_roads(),
    [compiler_test_seed(Bounded)],
    programs,
  ).unwrap()
  let second = compile_parcel_plan(
    "v2",
    20260727,
    compiler_test_roads(),
    [compiler_test_seed(Bounded)],
    [programs[1], programs[0]],
  ).unwrap()
  assert_eq(first, second)
  assert_eq(first.land_blocks.length(), 1)
  assert_eq(first.parcels.length(), 3)
  assert_eq(first.assignments.length(), 3)
  assert_eq(first.land_blocks[0].parcel_ids.length(), 3)
  for parcel in first.parcels {
    assert_true(first.find_assignment(parcel.id) is Some(_))
  }
}

///|
test "parcel compiler retains an explicitly nonparcelable land block" {
  let source = compiler_test_source()
  let block_id = compiler_test_id("land-block", "retained-road-island")
  let seed = land_block_seed(
    block_id,
    compiler_test_rectangle(0.0, 0.0, 1.0, 1.0),
    Utility,
    [],
    Fixed,
    source,
    parcel_grammar(0),
    parcelable=false,
  )
  let plan = compile_parcel_plan(
    "v2",
    20260727,
    road_network([], [], []),
    [seed],
    compiler_test_programs(),
  ).unwrap()
  assert_eq(plan.land_blocks.length(), 1)
  assert_eq(plan.land_blocks[0].id, block_id)
  assert_false(plan.land_blocks[0].parcelable)
  assert_eq(plan.land_blocks[0].effective_buildable_regions().length(), 0)
  assert_eq(plan.parcels.length(), 0)
  assert_eq(plan.assignments.length(), 0)
}

///|
test "bounded subdivision stays inside the exact Wenyu block" {
  let plan = compiler_test_plan(20260727)
  let block = plan.land_blocks[0]
  let mut compiled_area = 0.0
  for parcel in plan.parcels {
    compiled_area = compiled_area + parcel.boundary.area()
    for vertex in parcel.boundary.vertices {
      assert_true(block.boundary.contains_point(vertex))
    }
  }
  assert_true((compiled_area - block.boundary.area()).abs() < 0.0001)
  assert_eq(block.boundary, compiler_test_seed(Bounded).boundary)
}

///|
test "frontage is attributed to the nearest parcel, not copied everywhere" {
  let plan = compiler_test_plan(20260727)
  assert_eq(plan.parcels[0].frontage_segment_ids.length(), 1)
  assert_eq(plan.parcels[1].frontage_segment_ids.length(), 0)
  assert_eq(plan.parcels[2].frontage_segment_ids.length(), 1)
  let middle_assignment = plan.find_assignment(plan.parcels[1].id).unwrap()
  assert_eq(
    middle_assignment.program_id,
    compiler_test_id("parcel-program", "garden-court"),
  )
  assert_eq(middle_assignment.frontage_segment_id, None)
  assert_eq(plan.parcels[1].allowed_programs.length(), 1)
}

///|
test "preservation level controls whether the seed may move parcels" {
  let fixed_a = compiler_test_plan(1, variation=Fixed)
  let fixed_b = compiler_test_plan(999, variation=Fixed)
  assert_eq(fixed_a.parcels, fixed_b.parcels)
  assert_eq(fixed_a.assignments, fixed_b.assignments)
  let bounded_a = compiler_test_plan(1)
  let bounded_b = compiler_test_plan(999)
  assert_true(bounded_a.parcels != bounded_b.parcels)
  assert_eq(
    bounded_a.parcels.map(parcel => parcel.id),
    bounded_b.parcels.map(parcel => parcel.id),
  )
}

///|
test "invalid grammar and missing authored frontage fail explicitly" {
  let invalid = compile_parcel_plan(
    "v2",
    1,
    compiler_test_roads(),
    [compiler_test_seed(Bounded, target_count=0)],
    compiler_test_programs(),
  )
  assert_true(invalid is Err(InvalidParcelGrammar(_)))
  let source = compiler_test_source()
  let missing_frontage = land_block_seed(
    compiler_test_id("land-block", "broken-frontage"),
    compiler_test_rectangle(0.0, 0.0, 20.0, 20.0),
    Research,
    [compiler_test_id("road-segment", "missing")],
    Fixed,
    source,
    parcel_grammar(1, variation=Fixed),
  )
  let missing = compile_parcel_plan(
    "v2",
    1,
    compiler_test_roads(),
    [missing_frontage],
    compiler_test_programs(),
  )
  assert_true(missing is Err(MissingFrontageSegment(..)))
}

///|
test "program compatibility is a compiler invariant" {
  let park_only = parcel_program(
    compiler_test_id("parcel-program", "wetland-walk"),
    "Wetland walk",
    [Park],
  )
  let result = compile_parcel_plan(
    "v2",
    1,
    compiler_test_roads(),
    [compiler_test_seed(Bounded)],
    [park_only],
  )
  assert_true(result is Err(NoCompatibleProgram(_)))
}
