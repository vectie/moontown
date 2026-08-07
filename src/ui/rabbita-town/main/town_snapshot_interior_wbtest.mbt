///|
test "procedural interior renders only contract interaction slots" {
  let model = init_model()
  let base = ecosystem_contract_town_snapshot(model, 20260727)
  guard base.world.places.search_by(place => {
      place.building is Some(_) && !place.interaction_slots.is_empty()
    })
    is Some(index) else {
    fail("compiled town should expose an enterable building")
  }
  let place = base.world.places[index]
  let slot = place.interaction_slots[0]
  let presence = @energy_valley_contract.actor_presence(
    ecosystem_contract_scoped_id("runtime-agent", "interior-test"),
    place.id,
    place.primary_entrance().map(portal => portal.id),
    Some(slot.id),
    @energy_valley_contract.Inside,
    "验证真实交互位",
    0,
    None,
    @energy_valley_contract.provenance(
      "interior-test-runtime",
      "v1",
      @energy_valley_contract.RuntimeProjection,
      @energy_valley_contract.Free,
    ),
  )
  let snapshot = @energy_valley_contract.town_snapshot(base.world, 1, [], [], actor_presences=[
    presence,
  ])
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_town_snapshot_place_interior(snapshot, place)),
  )
  assert_true(html.contains("TownSnapshot interior"))
  assert_true(html.contains("LIVE · interior-test"))
  assert_true(html.contains("验证真实交互位"))
  assert_true(html.contains("semantic-interior-slot-dot is-occupied"))
}
