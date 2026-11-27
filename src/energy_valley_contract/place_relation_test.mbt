///|
fn relation_test_provenance() -> @energy_valley_contract.Provenance {
  @energy_valley_contract.provenance("relation-test", "v1", Derived, Bounded)
}

///|
fn relation_test_place(
  id : @energy_valley_contract.StableId,
  x : Double,
) -> @energy_valley_contract.Place {
  @energy_valley_contract.place(
    id,
    id.local_key(),
    Park,
    None,
    @energy_valley_contract.polygon([
      @energy_valley_contract.world_point(x, 1.0),
      @energy_valley_contract.world_point(x + 1.0, 1.0),
      @energy_valley_contract.world_point(x + 1.0, 2.0),
      @energy_valley_contract.world_point(x, 2.0),
    ]),
    [],
    [Public],
    [],
    None,
    None,
    relation_test_provenance(),
  )
}

///|
fn relation_test_world(
  relation : @energy_valley_contract.PlaceRelation,
) -> @energy_valley_contract.CompiledTownWorld raise {
  let first = test_id("place", "first")
  let second = test_id("place", "second")
  let anchor = @energy_valley_contract.road_node(
    test_id("road-node", "anchor"),
    @energy_valley_contract.grid_position(0, 0),
    @energy_valley_contract.world_point(0.5, 0.5),
    relation_test_provenance(),
  )
  @energy_valley_contract.compiled_town_world(
    "relation-test.v1",
    test_id("blueprint", "relation-test"),
    "relation-test-digest",
    1,
    @energy_valley_contract.world_bounds(
      @energy_valley_contract.world_point(0.0, 0.0),
      @energy_valley_contract.world_point(8.0, 8.0),
    ),
    [],
    @energy_valley_contract.road_network([anchor], [], [anchor.id]),
    [],
    [],
    [relation_test_place(first, 1.0), relation_test_place(second, 3.0)],
    [],
    place_relations=[relation],
  )
}

///|
test "compiled place relations resolve only accepted semantic endpoints" {
  let first = test_id("place", "first")
  let second = test_id("place", "second")
  let relation = @energy_valley_contract.place_relation(
    test_id("place-relation", "first--second"),
    first,
    second,
    Collaboration,
    "collaborates",
    relation_test_provenance(),
  )
  let world = relation_test_world(relation)
  assert_eq(world.relations_from(first), [relation])
  assert_eq(world.relations_for(second), [relation])
  assert_false(
    @energy_valley_contract.has_errors(
      @energy_valley_contract.validate_world(world),
    ),
  )
  let invalid = relation_test_world({
    ..relation,
    target_place_id: test_id("place", "missing"),
  })
  assert_true(
    @energy_valley_contract.validate_world(invalid).any(issue => {
      issue.code == InvalidPlaceRelation && issue.severity == Error
    }),
  )
}
