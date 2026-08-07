///|
fn ecosystem_presence_test_provenance(
  kind : @energy_valley_contract.ProvenanceKind,
) -> @energy_valley_contract.Provenance {
  @energy_valley_contract.provenance(
    "presence-view-test",
    "v1",
    kind,
    @energy_valley_contract.Free,
  )
}

///|
fn ecosystem_presence_test_snapshot(
  tick : Int,
  presences : Array[@energy_valley_contract.ActorPresence],
) -> @energy_valley_contract.TownSnapshot {
  @energy_valley_contract.town_snapshot(
    ecosystem_contract_world_for_model(init_model(), 20260727),
    tick,
    [],
    [],
    actor_presences=presences,
  )
}

///|
test "runtime Inside presence is included in building occupancy" {
  let world = ecosystem_contract_world_for_model(init_model(), 20260727)
  let place = world.places[0]
  let presence = @energy_valley_contract.actor_presence(
    ecosystem_contract_scoped_id("runtime-agent", "agent-live"),
    place.id,
    place.primary_entrance().map(portal => portal.id),
    None,
    @energy_valley_contract.Inside,
    "整理真实研究结果",
    4,
    None,
    ecosystem_presence_test_provenance(
      @energy_valley_contract.RuntimeProjection,
    ),
  )
  let view = ecosystem_place_presence_view(
    init_model(),
    ecosystem_presence_test_snapshot(8, [presence]),
    place.id,
  )
  assert_eq(view.occupant_names, ["agent-live"])
  assert_eq(view.arriving_names, [])
  assert_true(
    view.provenance_groups.any(group => group.label == "RUNTIME · LIVE"),
  )
}

///|
test "traveling presence is visible as arrival but never counted inside" {
  let world = ecosystem_contract_world_for_model(init_model(), 20260727)
  let place = world.places[0]
  let presence = @energy_valley_contract.actor_presence(
    ecosystem_contract_scoped_id("runtime-agent", "agent-traveling"),
    place.id,
    place.primary_entrance().map(portal => portal.id),
    None,
    @energy_valley_contract.Approaching,
    "沿语义路网前往",
    4,
    None,
    ecosystem_presence_test_provenance(
      @energy_valley_contract.RuntimeProjection,
    ),
  )
  let view = ecosystem_place_presence_view(
    init_model(),
    ecosystem_presence_test_snapshot(8, [presence]),
    place.id,
  )
  assert_eq(view.occupant_names, [])
  assert_eq(view.arriving_names, ["agent-traveling"])
}

///|
test "ambient snapshot presence retains preview provenance and resident name" {
  let model = init_model()
  let world = ecosystem_contract_world_for_model(model, 20260727)
  let place = world.places[0]
  let resident = ecosystem_preview_resident_profiles()[0]
  let presence = @energy_valley_contract.actor_presence(
    ecosystem_contract_scoped_id("resident", resident.id),
    place.id,
    place.primary_entrance().map(portal => portal.id),
    None,
    @energy_valley_contract.Inside,
    "校准镇务脉冲",
    4,
    None,
    ecosystem_presence_test_provenance(@energy_valley_contract.Derived),
  )
  let view = ecosystem_place_presence_view(
    model,
    ecosystem_presence_test_snapshot(8, [presence]),
    place.id,
  )
  assert_eq(view.occupant_names, [resident.name])
  assert_true(
    view.provenance_groups.any(group => group.label == "AMBIENT · PREVIEW"),
  )
}

///|
test "presence at an assigned destination does not leak into another building" {
  let world = ecosystem_contract_world_for_model(init_model(), 20260727)
  let assigned_place = world.places[0]
  let other_place = world.places[1]
  let assigned_presence = @energy_valley_contract.actor_presence(
    ecosystem_contract_scoped_id("runtime-agent", "agent-assigned"),
    assigned_place.id,
    assigned_place.primary_entrance().map(portal => portal.id),
    None,
    @energy_valley_contract.Approaching,
    "已分派，尚在路上",
    4,
    None,
    ecosystem_presence_test_provenance(
      @energy_valley_contract.RuntimeProjection,
    ),
  )
  let snapshot = ecosystem_presence_test_snapshot(8, [assigned_presence])
  let assigned_view = ecosystem_place_presence_view(
    init_model(),
    snapshot,
    assigned_place.id,
  )
  let other_view = ecosystem_place_presence_view(
    init_model(),
    snapshot,
    other_place.id,
  )
  assert_eq(assigned_view.occupant_names, [])
  assert_eq(assigned_view.arriving_names, ["agent-assigned"])
  assert_eq(other_view.occupant_names, [])
  assert_eq(other_view.arriving_names, [])
  assert_true(other_view.provenance_groups.is_empty())
}

///|
test "runtime assignment copy does not claim an approaching Agent is inside" {
  let model = runtime_map_routing_live_model()
  let semantic_place_id = ecosystem_contract_place_id_from_profile(
    "social-square",
  )
  let semantic_snapshot = ecosystem_presence_test_snapshot(model.tick, [
    @energy_valley_contract.actor_presence(
      ecosystem_contract_scoped_id("runtime-agent", "routing-agent"),
      semantic_place_id,
      None,
      None,
      @energy_valley_contract.Approaching,
      "Walking to the work building",
      41,
      None,
      ecosystem_presence_test_provenance(
        @energy_valley_contract.RuntimeProjection,
      ),
    ),
  ])
  let place = ecosystem_cached_world_snapshot(model, 20260727).places.filter(place => {
      ecosystem_contract_id(place.id) == semantic_place_id
    })[0]
  let runtime_presence = semantic_snapshot
    .presences_at(semantic_place_id)
    .filter(presence => {
      presence.provenance.kind == @energy_valley_contract.RuntimeProjection
    })[0]
  assert_eq(runtime_presence.phase, @energy_valley_contract.Approaching)
  let copy = ecosystem_story_runtime_copy(model, place, semantic_snapshot)
  assert_true(copy.contains("真实运行时在途"))
  assert_true(copy.contains("尚未计入建筑占用"))
  assert_false(copy.contains("在内 Agent"))
  let presence_view = ecosystem_place_presence_view(
    model, semantic_snapshot, semantic_place_id,
  )
  let building = golden_valley_buildings(20260727).filter(building => {
      golden_valley_building_module_key(building) == "social-square"
    })[0]
  let profile = ecosystem_place_profile_for_building(building)
  assert_eq(
    ecosystem_canvas_attention_label(profile, presence_view),
    "真实工作 · 在途",
  )
  assert_eq(ecosystem_canvas_attention_tone(place, presence_view), "live")
}

///|
test "Live to Stale without a version bump cannot leak live place presentation" {
  ecosystem_world_snapshot_cache.clear()
  ecosystem_contract_world_cache.clear()
  let live = runtime_map_routing_live_model()
  let stale = {
    ..live,
    energy_valley_runtime: { ..live.energy_valley_runtime, phase: Stale },
  }
  assert_eq(
    live.energy_valley_runtime.version,
    stale.energy_valley_runtime.version,
  )
  assert_eq(
    ecosystem_snapshot_cache_key(live, 20260727),
    ecosystem_snapshot_cache_key(stale, 20260727),
  )
  let live_world = ecosystem_cached_world_snapshot(live, 20260727)
  let stale_world = ecosystem_cached_world_snapshot(stale, 20260727)
  assert_eq(live_world, stale_world)
  let place_id = ecosystem_contract_place_id_from_profile("social-square")
  let place = stale_world.places.filter(place => {
      ecosystem_contract_id(place.id) == place_id
    })[0]
  let building = golden_valley_buildings(20260727).filter(building => {
      golden_valley_building_module_key(building) == "social-square"
    })[0]
  let profile = ecosystem_place_profile_for_building(building)
  let live_snapshot = ecosystem_presence_test_snapshot(live.tick, [
    @energy_valley_contract.actor_presence(
      ecosystem_contract_scoped_id("runtime-agent", "routing-agent"),
      place_id,
      None,
      None,
      @energy_valley_contract.Approaching,
      "Walking to the work building",
      41,
      None,
      ecosystem_presence_test_provenance(
        @energy_valley_contract.RuntimeProjection,
      ),
    ),
  ])
  let stale_snapshot = ecosystem_contract_town_snapshot(stale, 20260727)
  assert_false(
    stale_snapshot.actor_presences.any(presence => {
      presence.provenance.kind == @energy_valley_contract.RuntimeProjection
    }),
  )
  let live_presence = ecosystem_place_presence_view(
    live, live_snapshot, place_id,
  )
  let stale_presence = ecosystem_place_presence_view(
    stale, stale_snapshot, place_id,
  )
  assert_true(live_presence.runtime_arriving_count > 0)
  assert_eq(stale_presence.runtime_inside_count, 0)
  assert_eq(stale_presence.runtime_arriving_count, 0)
  assert_eq(ecosystem_canvas_attention_tone(place, live_presence), "live")
  assert_true(ecosystem_canvas_attention_tone(place, stale_presence) != "live")
  assert_eq(
    ecosystem_canvas_attention_label(profile, stale_presence),
    profile.characteristic,
  )
  assert_true(
    ecosystem_story_runtime_provenance(live, profile, place, live_snapshot)
    is RuntimeLive,
  )
  assert_true(
    ecosystem_story_runtime_provenance(stale, profile, place, stale_snapshot)
    is RuntimeRecord,
  )
  let stale_copy = ecosystem_story_runtime_copy(stale, place, stale_snapshot)
  assert_true(stale_copy.contains("最近运行时记录"))
  assert_false(stale_copy.contains("真实运行时在场"))
  assert_false(stale_copy.contains("真实运行时在途"))
}
