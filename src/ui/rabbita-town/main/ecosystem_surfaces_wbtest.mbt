///|
test "ecosystem attention digest stays bounded and labels preview provenance" {
  let dispatch : Dispatch[Msg] = Emit(fn(_message) { @rabbita.none })
  let model = { ..init_model(), tick: 18 }
  let snapshot = ecosystem_contract_town_snapshot(model, 20260727)
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_ecosystem_attention_digest(dispatch, model, snapshot),
    ),
  )
  assert_true(html.contains("此刻值得看"))
  assert_true(html.contains("真实工作优先"))
  assert_true(html.contains("AMBIENT · PREVIEW"))
  assert_true(html.contains("ecosystem-digest-action"))
  assert_true(html.contains("aria-label="))
  assert_true(html.split("ecosystem-digest-item ").length() <= 4)
}

///|
test "ecosystem place story joins personality to semantic access and truth" {
  let model = { ..init_model(), tick: 18 }
  let semantic_snapshot = ecosystem_contract_town_snapshot(model, 20260727)
  let bridge = ecosystem_cached_world_snapshot(model, 20260727)
  let occupied_buildings = golden_valley_buildings(20260727).filter(building => {
    match ecosystem_canvas_place_for_building(bridge, building) {
      Some(place) =>
        !semantic_snapshot
        .presences_at(ecosystem_contract_id(place.id))
        .is_empty()
      None => false
    }
  })
  assert_true(!occupied_buildings.is_empty())
  let building = occupied_buildings[0]
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_ecosystem_place_story(model, building, semantic_snapshot),
    ),
  )
  assert_true(html.contains("PLACE · WENYU"))
  assert_true(html.contains("语义活力"))
  assert_true(html.contains("此刻在这里"))
  assert_true(html.contains("AMBIENT · PREVIEW"))
  assert_true(html.contains("运行真相"))
  assert_true(html.contains("程序基因"))
  assert_true(
    html.contains("空间变体") ||
    html.contains("温榆原始场所 · 保留地理骨架"),
  )
  assert_true(html.contains("没有真实运行时工作证据"))
  assert_true(html.contains("到达方式"))
  assert_true(html.contains("它如何连接全镇"))
  assert_false(html.contains("真实运行时在场"))
}

///|
test "ecosystem access copy distinguishes direct and disconnected entrances" {
  let entrance : EcosystemEntrance = {
    id: "portal/test",
    place_id: "place/test",
    label: "主入口",
    threshold: ecosystem_point(10, 10),
    access_point: ecosystem_point(10, 11),
    direction: "south",
    portal_kind: "door",
    primary: true,
    accessible: true,
  }
  let frontage : EcosystemRoadFrontage = {
    id: "frontage/test",
    place_id: "place/test",
    entrance_id: entrance.id,
    road_cell_id: "road-node/10-11",
    road_class: "major",
    road_mask: 5,
    distance: 0,
    direct: true,
  }
  assert_eq(
    ecosystem_story_access_copy(Some(entrance), Some(frontage)),
    "主入口 · 主干路 · 直接接入 · 可通行",
  )
  assert_eq(
    ecosystem_story_access_copy(Some(entrance), None),
    "主入口已定位，但尚无道路接驳证据",
  )
}

///|
test "inspector access and actions follow the accepted semantic place" {
  let seed = 20260727
  let model = init_model()
  let bridge = ecosystem_cached_world_snapshot(model, seed)
  let building = golden_valley_buildings(seed)[0]
  let bridge_place = ecosystem_canvas_place_for_building(bridge, building).unwrap()
  let world = ecosystem_contract_world_for_model(model, seed)
  let place_id = ecosystem_contract_id(bridge_place.id)
  let accepted = world.find_place(place_id).unwrap()
  let inspect_slot_ids = ecosystem_affordances_for_place(
      bridge,
      bridge_place.id,
    )
    .filter(affordance => affordance.kind is EcosystemInspect)
    .map(affordance => ecosystem_contract_id(affordance.id))
  let sealed_place = {
    ..accepted,
    entrances: accepted.entrances.map(portal => { ..portal, road_node_id: None }),
    traits: accepted.traits.filter(place_trait => {
      !(place_trait is @energy_valley_contract.Accessible)
    }),
    interaction_slots: accepted.interaction_slots.filter(slot => {
      inspect_slot_ids.contains(slot.id)
    }),
  }
  let places : Array[@energy_valley_contract.Place] = []
  for candidate in world.places {
    places.push(if candidate.id == place_id { sealed_place } else { candidate })
  }
  let sealed_world = @energy_valley_contract.compiled_town_world(
    world.schema_version,
    world.blueprint_id,
    world.blueprint_digest,
    world.layout_seed,
    world.bounds,
    world.terrain_regions,
    world.road_network,
    world.land_blocks,
    world.parcels,
    places,
    world.attention_targets,
    parcel_programs=world.parcel_programs,
    parcel_program_assignments=world.parcel_program_assignments,
  )
  let (entrance, frontage) = ecosystem_story_semantic_access(
    bridge, bridge_place, sealed_world,
  )
  assert_true(entrance is Some(portal) && !portal.accessible)
  assert_true(frontage is None)
  let actions = ecosystem_story_semantic_affordances(
    bridge, bridge_place, sealed_world,
  )
  assert_true(
    actions.any(action => action.kind is EcosystemInspect && action.enabled),
  )
  assert_false(
    actions.any(action => !(action.kind is EcosystemInspect) && action.enabled),
  )
}
