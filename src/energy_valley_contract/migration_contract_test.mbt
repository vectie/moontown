///|
fn migration_delta_source() -> @energy_valley_contract.Provenance {
  @energy_valley_contract.provenance(
    "moontown-world-delta",
    "v3",
    UserDelta,
    Bounded,
  )
}

///|
test "versioned world delta normalizes losslessly and stays blueprint-bound" {
  let world = test_world()
  let source = migration_delta_source()
  let road_id = test_id("delta-road", "player-path-01")
  let addition : @energy_valley_contract.WorldDeltaOperation = AddRoad(
    @energy_valley_contract.road_addition(
      road_id,
      [
        @energy_valley_contract.grid_position(2, 3),
        @energy_valley_contract.grid_position(2, 3),
        @energy_valley_contract.grid_position(3, 3),
      ],
      Footpath,
      2.5,
      [Pedestrian],
      source,
    ),
  )
  let delta = @energy_valley_contract.world_delta(
    "energy-valley.delta.v1",
    world.blueprint_id,
    world.blueprint_digest,
    7,
    [addition, addition],
  )
  assert_true(delta.targets(world))
  assert_eq(delta.operations_for(road_id).length(), 2)
  assert_true(delta.latest_operation_for(road_id) is Some(AddRoad(_)))
  let normalized = delta.normalized()
  assert_eq(normalized.operations.length(), 1)
  guard normalized.operations[0] is AddRoad(normalized_road) else {
    fail("normalized road addition must retain its typed payload")
  }
  assert_eq(normalized_road.grid_path.length(), 2)
  assert_true(
    @energy_valley_contract.validate_world_delta(
      normalized,
      base_world=Some(world),
    ).is_empty(),
  )
  let stale = { ..normalized, base_blueprint_digest: "sha256:stale", }
  assert_true(
    @energy_valley_contract.validate_world_delta(stale, base_world=Some(world)).any(issue => {
        issue.code == WorldDeltaBlueprintMismatch
      },
    ),
  )
}

///|
test "one-cell road delta is valid only when it extends the base graph" {
  let world = test_world()
  let source = migration_delta_source()
  let connected = @energy_valley_contract.world_delta(
    "energy-valley.delta.v1",
    world.blueprint_id,
    world.blueprint_digest,
    8,
    [
      AddRoad(
        @energy_valley_contract.road_addition(
          test_id("delta-road", "one-cell-extension"),
          [@energy_valley_contract.grid_position(1, 0)],
          Local,
          4.0,
          [Pedestrian],
          source,
        ),
      ),
    ],
  )
  assert_true(
    @energy_valley_contract.validate_world_delta(
      connected,
      base_world=Some(world),
    ).is_empty(),
  )
  let detached = {
    ..connected,
    operations: [
      AddRoad(
        @energy_valley_contract.road_addition(
          test_id("delta-road", "detached-cell"),
          [@energy_valley_contract.grid_position(100, 100)],
          Local,
          4.0,
          [Pedestrian],
          source,
        ),
      ),
    ],
  }
  assert_true(
    @energy_valley_contract.validate_world_delta(
      detached,
      base_world=Some(world),
    ).any(issue => issue.code == InvalidWorldDeltaOperation),
  )
}

///|
test "typed delta operations preserve building and park geometry" {
  let source = migration_delta_source()
  let building_id = test_id("delta-building", "knowledge-hall")
  let park_id = test_id("delta-park", "river-garden")
  let closed_footprint = @energy_valley_contract.polygon([
    @energy_valley_contract.world_point(1.0, 1.0),
    @energy_valley_contract.world_point(4.0, 1.0),
    @energy_valley_contract.world_point(4.0, 4.0),
    @energy_valley_contract.world_point(1.0, 4.0),
    @energy_valley_contract.world_point(1.0, 1.0),
  ])
  let delta = @energy_valley_contract.world_delta(
    "energy-valley.delta.v1",
    test_id("blueprint", "wenyu-v1"),
    "sha256:test-wenyu-blueprint",
    8,
    [
      AddBuilding(
        @energy_valley_contract.building_addition(
          building_id,
          "Knowledge Hall",
          @energy_valley_contract.grid_position(12, 8),
          closed_footprint,
          @energy_valley_contract.building_profile(
            "knowledge-hall",
            3,
            15.0,
            Garden,
            88,
          ),
          source,
        ),
      ),
      AddPark(
        @energy_valley_contract.park_addition(
          park_id,
          "River garden",
          @energy_valley_contract.grid_position(18, 8),
          closed_footprint,
          source,
        ),
      ),
      MovePark(
        @energy_valley_contract.park_movement(
          park_id,
          @energy_valley_contract.grid_position(20, 9),
          closed_footprint,
          source,
        ),
      ),
    ],
  ).normalized()
  guard delta.operations[0] is AddBuilding(building) else {
    fail("expected building operation")
  }
  guard delta.operations[2] is MovePark(park) else {
    fail("expected park operation")
  }
  assert_eq(building.footprint.vertices.length(), 4)
  assert_eq(park.boundary.vertices.length(), 4)
  assert_true(@energy_valley_contract.validate_world_delta(delta).is_empty())
}

///|
test "world delta lifecycle requires Add before Move and makes Delete terminal" {
  let source = migration_delta_source()
  let id = test_id("delta-building", "lifecycle-building")
  let footprint = @energy_valley_contract.polygon([
    @energy_valley_contract.world_point(2.0, 2.0),
    @energy_valley_contract.world_point(4.0, 2.0),
    @energy_valley_contract.world_point(4.0, 4.0),
    @energy_valley_contract.world_point(2.0, 4.0),
  ])
  let addition : @energy_valley_contract.WorldDeltaOperation = AddBuilding(
    @energy_valley_contract.building_addition(
      id,
      "Lifecycle building",
      @energy_valley_contract.grid_position(2, 2),
      footprint,
      @energy_valley_contract.building_profile("lab", 2, 8.4, Flat, 17),
      source,
    ),
  )
  let movement : @energy_valley_contract.WorldDeltaOperation = MoveBuilding(
    @energy_valley_contract.building_movement(
      id,
      @energy_valley_contract.grid_position(8, 9),
      footprint,
      source,
    ),
  )
  let deletion : @energy_valley_contract.WorldDeltaOperation = DeleteBuilding(
    @energy_valley_contract.building_deletion(id, source),
  )
  let valid = @energy_valley_contract.world_delta(
    "energy-valley.delta.v1",
    test_id("blueprint", "wenyu-v1"),
    "sha256:test-wenyu-blueprint",
    3,
    [addition, movement, deletion],
  )
  assert_false(
    @energy_valley_contract.has_errors(
      @energy_valley_contract.validate_world_delta(valid),
    ),
  )
  for
    invalid_operations in [
      [movement],
      [deletion],
      [addition, deletion, movement],
      [addition, deletion, addition],
    ] {
    let invalid = @energy_valley_contract.world_delta(
      valid.schema_version,
      valid.base_blueprint_id,
      valid.base_blueprint_digest,
      valid.revision,
      invalid_operations,
    )
    assert_true(
      @energy_valley_contract.validate_world_delta(invalid).any(issue => {
        issue.code == InvalidWorldDeltaOperation
      }),
    )
  }
}

///|
test "public realm installations and Map Lab evidence belong to the world" {
  let base = test_world()
  let source = @energy_valley_contract.provenance(
    "wenyu-public-realm",
    "v2",
    Derived,
    Bounded,
  )
  let bench_id = test_id("installation", "bench-knowledge-lab")
  let metro_id = test_id("installation", "metro-line-17")
  let target_id = test_id("attention-target", "bench-knowledge-lab")
  let target = @energy_valley_contract.attention_target(
    target_id,
    Some(bench_id),
    AmbientDetail,
    "Bench conversation",
    @energy_valley_contract.world_point(17.0, 4.0),
    420,
    ["bench", "social"],
  )
  let bench = @energy_valley_contract.installation(
    bench_id,
    "Knowledge Lab bench",
    Bench,
    @energy_valley_contract.installation_point(
      @energy_valley_contract.world_point(17.0, 4.0),
    ),
    source,
    owner_place_id=Some(test_id("place", "knowledge-lab-01")),
    attention_target_id=Some(target_id),
    interactive=true,
  )
  let metro = @energy_valley_contract.installation(
    metro_id,
    "Metro line 17",
    MetroAlignment,
    @energy_valley_contract.installation_path([
      @energy_valley_contract.world_point(5.0, 20.0),
      @energy_valley_contract.world_point(40.0, 55.0),
    ]),
    source,
    tags=["transit", "landmark"],
  )
  let diagnostic_id = test_id("world-diagnostic", "metro-evidence")
  let diagnostic = @energy_valley_contract.world_diagnostic(
    diagnostic_id,
    ReferenceEvidence,
    Information,
    EvidenceAccepted,
    "Metro alignment retained from the reference evidence",
    source,
    entity_id=Some(metro_id),
    evidence_id=Some("wenyu:metro-line-17"),
  )
  let candidate_id = test_id("placement-candidate", "waterfront-lab")
  let rejection = @energy_valley_contract.rejected_placement(
    test_id("placement-rejection", "waterfront-lab-water"),
    candidate_id,
    BuildingPlacement,
    @energy_valley_contract.grid_position(24, 14),
    test_polygon(24.0, 14.0, 3.0),
    IntersectsWater,
    "Candidate overlaps retained Wenyu water",
    source,
    parcel_id=Some(test_id("parcel", "energy-core-01")),
  )
  let targets : Array[@energy_valley_contract.AttentionTarget] = []
  for existing in base.attention_targets {
    targets.push(existing)
  }
  targets.push(target)
  let world = @energy_valley_contract.compiled_town_world(
    base.schema_version,
    base.blueprint_id,
    base.blueprint_digest,
    base.layout_seed,
    base.bounds,
    base.terrain_regions,
    base.road_network,
    base.land_blocks,
    base.parcels,
    base.places,
    targets,
    installations=[bench, metro],
    diagnostics=[diagnostic],
    rejected_placements=[rejection],
  )
  assert_true(world.find_installation(bench_id) is Some(_))
  assert_eq(world.diagnostics_for(metro_id).length(), 1)
  assert_eq(world.rejections_for(candidate_id).length(), 1)
  assert_true(@energy_valley_contract.validate_world(world).is_empty())
}

///|
test "snapshot route position is the sole outdoor actor location" {
  let world = test_world()
  let actor_id = test_id("resident", "road-walker")
  let segment_id = test_id("road-segment", "10-0--20-0")
  let route = @energy_valley_contract.actor_route_position(
    @energy_valley_contract.world_point(15.0, 0.0),
    500,
    road_segment_id=Some(segment_id),
    origin_node_id=Some(test_id("road-node", "10-0")),
    destination_node_id=Some(test_id("road-node", "20-0")),
    heading_degrees=Some(0.0),
  )
  let presence = @energy_valley_contract.actor_presence(
    actor_id,
    test_id("place", "knowledge-lab-01"),
    Some(test_id("portal", "knowledge-lab-01-20-0")),
    None,
    Approaching,
    "walk to the lab",
    10,
    Some(30),
    migration_delta_source(),
    route_position=Some(route),
  )
  let snapshot = @energy_valley_contract.town_snapshot(world, 14, [], [], actor_presences=[
    presence,
  ])
  assert_eq(snapshot.outdoor_presences().length(), 1)
  assert_eq(
    presence.render_position(world),
    Some(@energy_valley_contract.world_point(15.0, 0.0)),
  )
  assert_true(@energy_valley_contract.validate_snapshot(snapshot).is_empty())
  let broken_route = {
    ..route,
    road_segment_id: Some(test_id("road-segment", "missing")),
    progress_per_mille: 1001,
  }
  let broken_presence = { ..presence, route_position: Some(broken_route), }
  let issues = @energy_valley_contract.validate_snapshot(
    @energy_valley_contract.town_snapshot(world, 14, [], [], actor_presences=[
      broken_presence,
    ]),
  )
  assert_true(issues.any(issue => issue.code == InvalidActorRoutePosition))
  assert_true(issues.any(issue => issue.code == MissingRoadSegment))
}

///|
test "one authored block compiles multiple typed buildable regions" {
  let source = @energy_valley_contract.provenance(
    "wenyu-block-fragments",
    "v2",
    WenyuReference,
    Fixed,
  )
  let block_id = test_id("land-block", "mixed-fragments")
  let research_region = @energy_valley_contract.buildable_region(
    test_id("buildable-region", "mixed-fragments-research"),
    test_polygon(0.0, 0.0, 10.0),
    Research,
    source,
  )
  let park_region = @energy_valley_contract.buildable_region(
    test_id("buildable-region", "mixed-fragments-park"),
    test_polygon(20.0, 0.0, 10.0),
    Park,
    source,
  )
  let seed = @energy_valley_contract.land_block_seed(
    block_id,
    @energy_valley_contract.polygon([
      @energy_valley_contract.world_point(0.0, 0.0),
      @energy_valley_contract.world_point(30.0, 0.0),
      @energy_valley_contract.world_point(30.0, 10.0),
      @energy_valley_contract.world_point(0.0, 10.0),
    ]),
    MixedUse,
    [],
    Fixed,
    source,
    @energy_valley_contract.parcel_grammar(1, minimum_area_sqm=20.0),
    buildable_regions=[research_region, park_region],
  )
  let research_program = @energy_valley_contract.parcel_program(
    test_id("parcel-program", "research-fragment"),
    "Research fragment",
    [Research],
  )
  let park_program = @energy_valley_contract.parcel_program(
    test_id("parcel-program", "park-fragment"),
    "Park fragment",
    [Park],
  )
  let plan = @energy_valley_contract.compile_parcel_plan(
    "fragment-compiler-v1",
    20260727,
    @energy_valley_contract.road_network([], [], []),
    [seed],
    [research_program, park_program],
  ).unwrap()
  assert_eq(plan.land_blocks.length(), 1)
  assert_eq(plan.land_blocks[0].buildable_regions.length(), 2)
  assert_eq(plan.parcels.length(), 2)
  assert_true(plan.parcels.any(value => value.land_use == Research))
  assert_true(plan.parcels.any(value => value.land_use == Park))
}
