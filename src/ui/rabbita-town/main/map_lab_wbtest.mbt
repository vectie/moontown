///|
fn map_lab_test_dispatch() -> Dispatch[Msg] {
  Emit(fn(_message) { @rabbita.none })
}

///|
fn map_lab_test_snapshot(model : Model) -> @energy_valley_contract.TownSnapshot {
  ecosystem_contract_town_snapshot(model, 20260727)
}

///|
fn map_lab_test_canvas_view(model : Model) -> MapLabCanvasViewState {
  {
    open: model.map_lab_open,
    layers: model.map_lab_layers.copy(),
    selected_id: model.map_lab_selected_id,
  }
}

///|
fn map_lab_test_view(model : Model) -> MapLabViewState {
  {
    open: model.map_lab_open,
    layers: model.map_lab_layers.copy(),
    selected_id: model.map_lab_selected_id,
    query: model.map_lab_query,
  }
}

///|
test "Map Lab layer state is read-only presentation state" {
  let model = init_model()
  let seed = 20260727
  let before_key = ecosystem_snapshot_cache_key(model, seed)
  let before_world = ecosystem_contract_world_for_model(model, seed)
  let enabled = map_lab_toggle_layer(model.map_lab_layers, MapLabTerrain)
  assert_true(enabled.contains(MapLabTerrain))
  let disabled = map_lab_toggle_layer(enabled, MapLabTerrain)
  assert_false(disabled.contains(MapLabTerrain))
  let diagnostic_model = {
    ..model,
    map_lab_open: true,
    map_lab_layers: enabled,
    map_lab_selected_id: before_world.blueprint_id.to_string(),
    map_lab_query: "road",
  }
  assert_eq(ecosystem_snapshot_cache_key(diagnostic_model, seed), before_key)
  assert_eq(
    ecosystem_contract_world_for_model(diagnostic_model, seed),
    before_world,
  )
}

///|
test "Map Lab inventory exposes semantic StableIds and accepted ledger counts" {
  let model = init_model()
  let snapshot = ecosystem_contract_town_snapshot(model, 20260727)
  let initial_page = map_lab_visible_entities(snapshot, "")
  let counts = map_lab_counts(snapshot)
  assert_eq(initial_page.rows.length(), map_lab_entity_result_limit)
  assert_eq(initial_page.rows[0].id, snapshot.world.blueprint_id.to_string())
  assert_eq(initial_page.scanned, map_lab_entity_result_limit)
  assert_eq(initial_page.detail_materializations, 0)
  assert_eq(counts.blocks, snapshot.world.land_blocks.length())
  assert_eq(counts.parcels, snapshot.world.parcels.length())
  assert_eq(counts.road_segments, snapshot.world.road_network.segments.length())
  assert_eq(counts.presences, snapshot.active_presences().length())
  assert_eq(counts.exchanges, snapshot.active_exchanges().length())
  assert_eq(counts.installations, snapshot.world.installations.length())
  assert_eq(counts.relations, snapshot.world.place_relations.length())
  assert_eq(counts.diagnostics, snapshot.world.diagnostics.length())
  assert_eq(counts.rejections, snapshot.world.rejected_placements.length())
  assert_eq(counts.actor_profiles, snapshot.actor_profiles.length())
  assert_eq(counts.attention_signals, snapshot.attention_signals.length())
  assert_eq(counts.attention_focuses, snapshot.attention_focuses.length())
  assert_true(
    ecosystem_contract_world_validation_issues_cache.contains(
      ecosystem_contract_world_validation_identity(snapshot.world),
    ),
  )
  assert_eq(
    map_lab_selected_entity(
      snapshot,
      snapshot.world.land_blocks[0].id.to_string(),
    ).category,
    "land block",
  )
  assert_eq(
    map_lab_selected_entity(snapshot, snapshot.world.parcels[0].id.to_string()).category,
    "parcel",
  )
  assert_eq(
    map_lab_selected_entity(
      snapshot,
      snapshot.world.road_network.segments[0].id.to_string(),
    ).category,
    "road segment",
  )
  assert_eq(
    map_lab_selected_entity(
      snapshot,
      snapshot.world.installations[0].id.to_string(),
    ).category,
    "installation",
  )
  assert_eq(
    map_lab_selected_entity(
      snapshot,
      snapshot.world.place_relations[0].id.to_string(),
    ).category,
    "place relation",
  )
  assert_eq(
    map_lab_selected_entity(
      snapshot,
      snapshot.world.diagnostics[0].id.to_string(),
    ).category,
    "world diagnostic",
  )
  assert_true(
    snapshot.world.road_network.segments.any(segment => {
      map_lab_road_segment_is_source_evidence(snapshot.world, segment)
    }),
  )
}

///|
test "Map Lab stays behind one accessible advanced control" {
  let dispatch = map_lab_test_dispatch()
  let closed_model = init_model()
  let closed_html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_map_lab(
        dispatch,
        map_lab_test_view(closed_model),
        map_lab_test_snapshot(closed_model),
      ),
    ),
  )
  assert_true(closed_html.contains("打开地图实验室，快捷键 Shift+M"))
  assert_true(closed_html.contains("aria-controls=\"map-lab-panel\""))
  assert_true(closed_html.contains("aria-expanded=\"false\""))
  assert_false(closed_html.contains("id=\"map-lab-panel\""))

  let open_model = { ..init_model(), map_lab_open: true }
  let open_html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_map_lab(
        dispatch,
        map_lab_test_view(open_model),
        map_lab_test_snapshot(open_model),
      ),
    ),
  )
  assert_true(open_html.contains("id=\"map-lab-panel\""))
  assert_true(open_html.contains("aria-modal=\"false\""))
  assert_true(open_html.contains("ADVANCED · READ ONLY"))
  assert_true(open_html.contains("查找 StableId"))
  assert_true(open_html.contains("源证据"))
  assert_true(open_html.contains("精确地块"))
  assert_true(open_html.contains("道路 / 导航"))
  assert_true(open_html.contains("校验 / 拒绝"))
  assert_true(open_html.contains("Shift+M 开关 · Esc 关闭"))
}

///|
test "Map Lab search is bounded and selected detail remains inspectable" {
  let model = init_model()
  let snapshot = ecosystem_contract_town_snapshot(model, 20260727)
  let roads = map_lab_visible_entities(snapshot, "road-segment/")
  assert_true(!roads.rows.is_empty())
  assert_true(roads.rows.length() <= map_lab_entity_result_limit)
  assert_eq(roads.detail_materializations, 0)
  assert_true(
    roads.rows.all(entity => entity.id.to_lower().contains("road-segment/")),
  )
  let selected = map_lab_selected_entity(snapshot, roads.rows[0].selection_key)
  assert_eq(selected.id, roads.rows[0].id)
  assert_eq(selected.category, "road segment")
}

///|
test "Map Lab installation search caps results without eager detail materialization" {
  let snapshot = ecosystem_contract_town_snapshot(init_model(), 20260727)
  assert_true(snapshot.world.installations.length() > 1000)
  let installations = map_lab_visible_entities(snapshot, "installation/")
  assert_eq(installations.rows.length(), map_lab_entity_result_limit)
  assert_eq(installations.detail_materializations, 0)
  assert_true(
    installations.rows.all(entity => {
      entity.category == "installation" &&
      entity.id.to_lower().contains("installation/")
    }),
  )
  let selected = map_lab_selected_entity(
    snapshot,
    installations.rows[39].selection_key,
  )
  assert_eq(selected.id, installations.rows[39].id)
  assert_eq(selected.category, "installation")
  assert_true(!selected.facts.is_empty())
}

///|
test "Map Lab searches and selects every dynamic attention ledger category" {
  let snapshot = ecosystem_contract_town_snapshot(
    { ..init_model(), tick: 18 },
    20260727,
  )
  assert_true(!snapshot.actor_profiles.is_empty())
  assert_true(!snapshot.attention_signals.is_empty())
  assert_true(!snapshot.attention_focuses.is_empty())
  let lean = {
    ..snapshot,
    world: {
      ..snapshot.world,
      terrain_regions: [],
      road_network: @energy_valley_contract.road_network([], [], []),
      land_blocks: [],
      parcels: [],
      parcel_programs: [],
      parcel_program_assignments: [],
      places: [],
      place_relations: [],
      installations: [],
      attention_targets: [],
      diagnostics: [],
      rejected_placements: [],
    },
  }
  let profiles = map_lab_visible_entities(lean, "actor profile")
  let signals = map_lab_visible_entities(lean, "attention signal")
  let focuses = map_lab_visible_entities(lean, "attention focus")
  assert_true(!profiles.rows.is_empty())
  assert_true(!signals.rows.is_empty())
  assert_true(!focuses.rows.is_empty())
  assert_eq(
    map_lab_selected_entity(lean, profiles.rows[0].selection_key).category,
    "actor profile",
  )
  assert_eq(
    map_lab_selected_entity(lean, signals.rows[0].selection_key).category,
    "attention signal",
  )
  assert_eq(
    map_lab_selected_entity(lean, focuses.rows[0].selection_key).category,
    "attention focus",
  )
}

///|
test "Map Lab validates dynamic contents without a tick-length stale cache" {
  let snapshot = ecosystem_contract_town_snapshot(
    { ..init_model(), tick: 18 },
    20260727,
  )
  let _ = map_lab_validation_issues(snapshot)
  let profiles : Array[@energy_valley_contract.ActorProfile] = []
  for profile in snapshot.actor_profiles {
    profiles.push(profile)
  }
  profiles[0] = { ..profiles[0], display_name: "" }
  let malformed = @energy_valley_contract.town_snapshot(
    snapshot.world,
    snapshot.tick,
    snapshot.attention_signals,
    snapshot.attention_focuses,
    actor_profiles=profiles,
    actor_presences=snapshot.actor_presences,
    place_exchanges=snapshot.place_exchanges,
  )
  assert_true(
    map_lab_validation_issues(malformed).any(issue => {
      issue.code == @energy_valley_contract.InvalidActorProfile
    }),
  )
}

///|
test "Map Lab exposes rejected placements as searchable diagnostics" {
  let snapshot = ecosystem_contract_town_snapshot(init_model(), 20260727)
  let source = @energy_valley_contract.provenance(
    "map-lab-test",
    "v1",
    @energy_valley_contract.UserDelta,
    @energy_valley_contract.Bounded,
  )
  let rejection = @energy_valley_contract.rejected_placement(
    ecosystem_contract_scoped_id("placement-rejection", "test-road-overlap"),
    ecosystem_contract_scoped_id("place", "test"),
    @energy_valley_contract.BuildingPlacement,
    @energy_valley_contract.grid_position(12, 18),
    golden_valley_contract_building_footprint({
      authored_id: Some("test"),
      module_key: None,
      name: "test",
      style: "custom-lab",
      x: 12,
      y: 18,
      width: 3,
      depth: 4,
      entrance_x: None,
      entrance_y: None,
      floors: 2,
    }),
    @energy_valley_contract.IntersectsRoad,
    "test rejection",
    source,
  )
  let rejected_snapshot = {
    ..snapshot,
    world: { ..snapshot.world, rejected_placements: [rejection] },
  }
  let rejected = map_lab_visible_entities(rejected_snapshot, "intersects-road")
  assert_eq(rejected.rows.length(), 1)
  assert_eq(rejected.rows[0].category, "rejected placement")
  assert_eq(rejected.detail_materializations, 0)
  let selected = map_lab_selected_entity(
    rejected_snapshot,
    rejected.rows[0].selection_key,
  )
  assert_eq(selected.category, "rejected placement")
  assert_eq(selected.label, "intersects-road")
  assert_eq(map_lab_counts(rejected_snapshot).rejections, 1)
}

///|
test "Map Lab canvas exists only while diagnostics are open" {
  let closed_model = init_model()
  let closed_html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_map_lab_canvas(
        map_lab_test_snapshot(closed_model),
        map_lab_test_canvas_view(closed_model),
      ),
    ),
  )
  assert_false(closed_html.contains("map-lab-canvas"))
  let open_model = { ..init_model(), map_lab_open: true }
  let open_html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_map_lab_canvas(
        map_lab_test_snapshot(open_model),
        map_lab_test_canvas_view(open_model),
      ),
    ),
  )
  assert_true(open_html.contains("id=\"map-lab-canvas\""))
  assert_true(open_html.contains("aria-hidden=\"true\""))
}
