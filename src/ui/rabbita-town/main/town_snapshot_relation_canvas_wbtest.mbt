///|
test "Canvas relations are the selected snapshot relation ledger exactly" {
  let snapshot = ecosystem_contract_town_snapshot(init_model(), 20260727)
  assert_true(!snapshot.world.place_relations.is_empty())
  let source_id = snapshot.world.place_relations[0].source_place_id
  let accepted = snapshot.world.relations_from(source_id)
  let projected = town_snapshot_canvas_relations_from(snapshot, source_id)
  assert_eq(projected.length(), accepted.length())
  for relation in projected {
    assert_true(accepted.any(candidate => candidate.id == relation.relation_id))
    assert_eq(relation.source_place_id, source_id)
    assert_true(snapshot.world.find_place(relation.target_place_id) is Some(_))
  }

  // This source has an authored civic relationship in the historical UI
  // grammar. Removing relations from the snapshot must still remove every
  // Canvas edge, proving the renderer does not retain that old lookup table.
  let without_relations = {
    ..snapshot,
    world: { ..snapshot.world, place_relations: [] },
  }
  assert_true(
    town_snapshot_canvas_relations_from(without_relations, source_id).is_empty(),
  )
}

///|
test "Canvas relation geometry and styling derive from semantic endpoints" {
  let snapshot = ecosystem_contract_town_snapshot(init_model(), 20260727)
  assert_true(!snapshot.world.place_relations.is_empty())
  let authored = snapshot.world.place_relations[0]
  let source = snapshot.world.find_place(authored.source_place_id).unwrap()
  let target = snapshot.world.find_place(authored.target_place_id).unwrap()
  let relation = @energy_valley_contract.place_relation(
    ecosystem_contract_scoped_id("place-relation", "snapshot-only-test"),
    source.id,
    target.id,
    @energy_valley_contract.KnowledgeFlow,
    "snapshot knowledge flow",
    source.provenance,
  )
  let isolated = {
    ..snapshot,
    world: { ..snapshot.world, place_relations: [relation] },
  }
  let projected = town_snapshot_canvas_relations_from(isolated, source.id)
  assert_eq(projected.length(), 1)
  assert_eq(projected[0].relation_id, relation.id)
  assert_eq(projected[0].source_place_id, source.id)
  assert_eq(projected[0].target_place_id, target.id)
  assert_eq(
    projected[0].source_position,
    town_snapshot_place_center(source).unwrap(),
  )
  assert_eq(
    projected[0].target_position,
    town_snapshot_place_center(target).unwrap(),
  )
  assert_eq(projected[0].accent, "#a78bfa")
  assert_true(
    town_snapshot_canvas_relations_from(isolated, target.id).is_empty(),
  )
}
