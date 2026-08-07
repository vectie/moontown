///|
fn program_world_test_id(scope : String, key : String) -> StableId {
  stable_id(scope, key).unwrap()
}

///|
fn program_world_test_source() -> Provenance {
  provenance("parcel-program-world-test", "v1", Derived, Fixed)
}

///|
fn program_world_test_polygon(
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
fn program_world_test_program(
  key : String,
  compatible_land_uses : ArrayView[LandUse],
) -> ParcelProgram {
  parcel_program(
    program_world_test_id("parcel-program", key),
    key,
    compatible_land_uses,
    minimum_area_sqm=1.0,
  )
}

///|
fn program_world_test_assignment(
  key : String,
  parcel_id : StableId,
  program_id : StableId,
) -> ParcelProgramAssignment {
  {
    id: program_world_test_id("parcel-program-assignment", key),
    parcel_id,
    program_id,
    placement_anchor: world_point(12.0, 12.0),
    frontage_segment_id: Some(program_world_test_id("road-segment", "main")),
    variant_seed: 27,
    provenance: program_world_test_source(),
  }
}

///|
fn program_world_test_world(
  programs : ArrayView[ParcelProgram],
  assignments : ArrayView[ParcelProgramAssignment],
  place_program_id : StableId?,
  include_second_parcel? : Bool = false,
) -> CompiledTownWorld {
  let source = program_world_test_source()
  let node_a_id = program_world_test_id("road-node", "west")
  let node_b_id = program_world_test_id("road-node", "east")
  let segment_id = program_world_test_id("road-segment", "main")
  let block_id = program_world_test_id("land-block", "research-core")
  let parcel_a_id = program_world_test_id("parcel", "research-a")
  let parcel_b_id = program_world_test_id("parcel", "research-b")
  let parcel_ids : Array[StableId] = [parcel_a_id]
  let parcels : Array[Parcel] = [
    parcel(
      parcel_a_id,
      block_id,
      program_world_test_polygon(5.0, 5.0, 25.0, 25.0),
      Research,
      [segment_id],
      [
        program_world_test_id("parcel-program", "knowledge-lab").to_string(),
        program_world_test_id("parcel-program", "research-court").to_string(),
      ],
      Fixed,
      source,
    ),
  ]
  if include_second_parcel {
    parcel_ids.push(parcel_b_id)
    parcels.push(
      parcel(
        parcel_b_id,
        block_id,
        program_world_test_polygon(25.0, 5.0, 45.0, 25.0),
        Research,
        [segment_id],
        [
          program_world_test_id("parcel-program", "knowledge-lab").to_string(),
          program_world_test_id("parcel-program", "research-court").to_string(),
        ],
        Fixed,
        source,
      ),
    )
  }
  let place_id = program_world_test_id("place", "knowledge-lab")
  let place = place(
    place_id,
    "Knowledge Lab",
    Building,
    Some(parcel_a_id),
    program_world_test_polygon(8.0, 8.0, 20.0, 20.0),
    [
      entrance_portal(
        program_world_test_id("portal", "knowledge-lab-main"),
        world_point(20.0, 0.0),
        Some(node_b_id),
        [Pedestrian],
        primary=true,
      ),
    ],
    [KnowledgeWork, Accessible],
    [],
    Some(building_profile("knowledge-lab", 4, 18.0, Garden, 27)),
    None,
    source,
    program_id=place_program_id,
  )
  compiled_town_world(
    "energy-valley.world.v2",
    program_world_test_id("blueprint", "program-world"),
    "sha256:program-world",
    27,
    world_bounds(world_point(0.0, 0.0), world_point(100.0, 100.0, z=50.0)),
    [],
    road_network(
      [
        road_node(node_a_id, grid_position(0, 0), world_point(0.0, 0.0), source),
        road_node(
          node_b_id,
          grid_position(20, 0),
          world_point(20.0, 0.0),
          source,
        ),
      ],
      [
        road_segment(
          segment_id,
          node_a_id,
          node_b_id,
          [world_point(0.0, 0.0), world_point(20.0, 0.0)],
          Local,
          6.0,
          [Pedestrian],
          source,
        ),
      ],
      [node_a_id],
    ),
    [
      land_block(
        block_id,
        program_world_test_polygon(0.0, 0.0, 50.0, 30.0),
        Research,
        parcel_ids,
        [segment_id],
        Fixed,
        source,
      ),
    ],
    parcels,
    [place],
    [],
    parcel_programs=programs,
    parcel_program_assignments=assignments,
  )
}

///|
fn program_world_test_has_issue(
  issues : ArrayView[ContractIssue],
  code : ContractIssueCode,
  entity_id : StableId,
) -> Bool {
  issues.any(issue => issue.code == code && issue.entity_id == Some(entity_id))
}

///|
test "compiled world retains parcel programs and resolves assignments" {
  let parcel_id = program_world_test_id("parcel", "research-a")
  let program = program_world_test_program("knowledge-lab", [Research])
  let assignment = program_world_test_assignment(
    "research-a",
    parcel_id,
    program.id,
  )
  let world = program_world_test_world(
    [program],
    [assignment],
    Some(program.id),
  )
  guard world.find_parcel_program(program.id) is Some(found) else {
    fail("compiled world lost its program catalog")
  }
  assert_eq(found, program)
  guard world.parcel_program_for(parcel_id) is Some(bound) else {
    fail("compiled world lost its parcel assignment")
  }
  assert_eq(bound.id, program.id)
  assert_true(validate_world(world).is_empty())
}

///|
test "validation reports an assignment whose program is missing" {
  let parcel_id = program_world_test_id("parcel", "research-a")
  let missing_program_id = program_world_test_id("parcel-program", "missing")
  let assignment = program_world_test_assignment(
    "research-a", parcel_id, missing_program_id,
  )
  let issues = validate_world(program_world_test_world([], [assignment], None))
  assert_true(
    program_world_test_has_issue(issues, MissingParcelProgram, assignment.id),
  )
}

///|
test "validation reports every parcel omitted from a nonempty assignment set" {
  let parcel_a_id = program_world_test_id("parcel", "research-a")
  let parcel_b_id = program_world_test_id("parcel", "research-b")
  let program = program_world_test_program("knowledge-lab", [Research])
  let assignment = program_world_test_assignment(
    "research-a",
    parcel_a_id,
    program.id,
  )
  let issues = validate_world(
    program_world_test_world(
      [program],
      [assignment],
      Some(program.id),
      include_second_parcel=true,
    ),
  )
  assert_true(
    program_world_test_has_issue(
      issues,
      MissingParcelProgramAssignment,
      parcel_b_id,
    ),
  )
}

///|
test "validation rejects a program incompatible with parcel land use" {
  let parcel_id = program_world_test_id("parcel", "research-a")
  let park_program = program_world_test_program("wetland-walk", [Park])
  let assignment = program_world_test_assignment(
    "research-a",
    parcel_id,
    park_program.id,
  )
  let issues = validate_world(
    program_world_test_world(
      [park_program],
      [assignment],
      Some(park_program.id),
    ),
  )
  assert_true(
    program_world_test_has_issue(issues, ParcelProgramMismatch, assignment.id),
  )
}

///|
test "validation rejects a place program that differs from its parcel" {
  let parcel_id = program_world_test_id("parcel", "research-a")
  let assigned = program_world_test_program("knowledge-lab", [Research])
  let place_program = program_world_test_program("research-court", [Research])
  let assignment = program_world_test_assignment(
    "research-a",
    parcel_id,
    assigned.id,
  )
  let issues = validate_world(
    program_world_test_world(
      [assigned, place_program],
      [assignment],
      Some(place_program.id),
    ),
  )
  assert_true(
    program_world_test_has_issue(
      issues,
      ParcelProgramMismatch,
      program_world_test_id("place", "knowledge-lab"),
    ),
  )
}

///|
test "validation rejects more than one program assignment per parcel" {
  let parcel_id = program_world_test_id("parcel", "research-a")
  let program = program_world_test_program("knowledge-lab", [Research])
  let first = program_world_test_assignment(
    "research-a-primary",
    parcel_id,
    program.id,
  )
  let second = program_world_test_assignment(
    "research-a-duplicate",
    parcel_id,
    program.id,
  )
  let issues = validate_world(
    program_world_test_world([program], [first, second], Some(program.id)),
  )
  assert_true(
    program_world_test_has_issue(
      issues,
      DuplicateParcelProgramAssignment,
      second.id,
    ),
  )
}

///|
test "validation enforces parcel program allow-list and area constraints" {
  let parcel_id = program_world_test_id("parcel", "research-a")
  let disallowed = program_world_test_program("private-reactor", [Research])
  let disallowed_assignment = program_world_test_assignment(
    "research-a-disallowed",
    parcel_id,
    disallowed.id,
  )
  let disallowed_issues = validate_world(
    program_world_test_world(
      [disallowed],
      [disallowed_assignment],
      Some(disallowed.id),
    ),
  )
  assert_true(
    program_world_test_has_issue(
      disallowed_issues,
      ParcelProgramMismatch,
      disallowed_assignment.id,
    ),
  )
  let oversized_minimum = parcel_program(
    program_world_test_id("parcel-program", "knowledge-lab"),
    "Knowledge lab",
    [Research],
    minimum_area_sqm=401.0,
  )
  let area_assignment = program_world_test_assignment(
    "research-a-area",
    parcel_id,
    oversized_minimum.id,
  )
  let area_issues = validate_world(
    program_world_test_world(
      [oversized_minimum],
      [area_assignment],
      Some(oversized_minimum.id),
    ),
  )
  assert_true(
    program_world_test_has_issue(
      area_issues,
      ParcelProgramMismatch,
      area_assignment.id,
    ),
  )
}

///|
test "validation enforces assignment frontage and placement geometry" {
  let parcel_id = program_world_test_id("parcel", "research-a")
  let program = parcel_program(
    program_world_test_id("parcel-program", "knowledge-lab"),
    "Knowledge lab",
    [Research],
    minimum_area_sqm=1.0,
    requires_frontage=true,
  )
  let base = program_world_test_assignment(
    "research-a-invalid-placement",
    parcel_id,
    program.id,
  )
  let assignment = {
    ..base,
    placement_anchor: world_point(80.0, 80.0),
    frontage_segment_id: None,
  }
  let issues = validate_world(
    program_world_test_world([program], [assignment], Some(program.id)),
  )
  let assignment_mismatches = issues.filter(issue => {
    issue.code == ParcelProgramMismatch &&
    issue.entity_id == Some(assignment.id)
  })
  assert_true(assignment_mismatches.length() >= 2)
}
