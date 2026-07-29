///|
test "default valley is generated from the authored JSON migration process" {
  let seed = 20260727
  let world = exact_energy_valley_generate_int(seed)
  assert_eq(world.tiles.length(), 144)
  assert_eq(world.tiles[0].length(), 256)
  assert_true(world.landmarks.river_crossing_y >= 70)
  assert_true(world.landmarks.bridge_columns.length() > 0)
  let buildings = golden_valley_buildings(seed)
  assert_eq(buildings.length(), 16)
  assert_eq(buildings[0].name, "市政厅")
  assert_eq(buildings[1].name, "政策大厅")
  assert_eq(buildings[2].name, "活力塔")
  assert_true(buildings[4].y < world.landmarks.river_crossing_y)
  assert_true(buildings[8].y > world.landmarks.river_crossing_y)
}

///|
test "road placement uses the reference bridge price and park rejects water" {
  let base = { ..init_model(), energy_weather: Sunny }
  let seed = 20260727
  let world = exact_energy_valley_generate_int(seed)
  let mut water_x = 0
  let mut water_y = 0
  for y in 60..<85 {
    for x in 105..<150 {
      if world.terrain_at(x, y) == Some("water") {
        water_x = x
        water_y = y
      }
    }
  }
  assert_true(water_x > 0)
  let screen_x = golden_screen_x(
      water_x.to_double() + 0.5,
      water_y.to_double() + 0.5,
      1280,
    )
    .floor()
    .to_int()
  let screen_y = golden_screen_y(
      water_x.to_double() + 0.5,
      water_y.to_double() + 0.5,
      720,
    )
    .floor()
    .to_int()
  let bridge = energy_valley_canvas_click_model(
    { ..base, energy_tool: RoadTool },
    screen_x,
    screen_y,
  )
  assert_eq(bridge.energy_build_budget, 2280)
  assert_eq(bridge.energy_toast, "新桥贯通温榆河（-120）")
  assert_eq(bridge.energy_roads.length(), 1)
  let park = energy_valley_canvas_click_model(
    { ..base, energy_tool: ParkTool },
    screen_x,
    screen_y,
  )
  assert_eq(park.energy_build_budget, 2400)
  assert_eq(park.energy_toast, "仅可改造草地、草甸或农田")
}

///|
test "custom buildings use the reference half-price demolition refund" {
  let building = {
    module_key: None,
    name: "创新工坊 1",
    style: "custom-hall",
    x: 20,
    y: 20,
    width: 2,
    depth: 2,
    entrance_x: None,
    entrance_y: None,
    floors: 2,
  }
  assert_eq(golden_valley_building_refund(building), 200)
}

///|
test "live runtime feed never fabricates ambient work events" {
  let runtime = energy_valley_runtime_state_from_text(
    energy_valley_runtime_test_projection_text(
      "1970-01-01T00:01:40.000Z", "live",
    ),
    1,
    110000.0,
  )
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_energy_valley_event_feed({
        ..init_model(),
        energy_valley_runtime: runtime,
      }),
    ),
  )
  assert_true(!html.contains("工蜂"))
  assert_true(!html.contains("镇长前往"))
  assert_true(!html.contains("结果回传"))
}

///|
test "demo clock and weather begin from the reference simulation state" {
  let model = init_model()
  assert_eq(energy_valley_sim_clock(model), "09:12")
  assert_eq(energy_valley_sim_day(model), 1)
  assert_true(model.energy_weather == Sunny)
  assert_eq(model.energy_build_budget, 2400)
}

///|
test "real work dialog exposes the existing live request composers" {
  let model = {
    ..init_model(),
    energy_request_open: true,
    request_composer: StandingWatchComposer,
  }
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_energy_valley_request_dialog(dashboard_test_dispatch(), model),
    ),
  )
  assert_true(html.contains("派遣真实协作工作"))
  assert_true(html.contains("Ask the town to keep watching"))
  assert_true(html.contains("Save Watch"))
}

///|
test "canonical buildings resolve to the same durable runtime stations" {
  let buildings = golden_valley_buildings(20260727)
  assert_eq(golden_valley_building_module_key(buildings[0]), "town-shell")
  assert_eq(golden_valley_building_module_key(buildings[1]), "policy-hall")
  assert_eq(golden_valley_building_module_key(buildings[7]), "social-square")
  assert_eq(
    golden_valley_building_module_key(buildings[9]),
    "research-ai-agents",
  )
}

///|
test "building inspector only claims real work assigned to that building" {
  let runtime = energy_valley_runtime_state_from_text(
    energy_valley_runtime_test_projection_text(
      "1970-01-01T00:01:40.000Z", "live",
    ),
    1,
    110000.0,
  )
  let buildings = golden_valley_buildings(20260727)
  let town_hall_html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_energy_valley_inspector(dashboard_test_dispatch(), {
        ..init_model(),
        energy_valley_runtime: runtime,
        energy_selected_building: Some(buildings[0]),
      }),
    ),
  )
  assert_true(town_hall_html.contains("真实工作"))
  assert_true(
    town_hall_html.contains("这座建筑当前没有真实运行时任务。"),
  )
  assert_false(town_hall_html.contains("Collaborated research"))
  let policy_html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_energy_valley_inspector(dashboard_test_dispatch(), {
        ..init_model(),
        energy_valley_runtime: runtime,
        energy_selected_building: Some(buildings[1]),
      }),
    ),
  )
  assert_true(policy_html.contains("Collaborated research"))
  assert_true(policy_html.contains("Policy Hall · 协议制定与治理"))
  assert_true(policy_html.contains("running · run-parent"))
  assert_true(policy_html.contains("在内 Agent"))
  assert_true(policy_html.contains("进入建筑 · 查看真实工作"))
  assert_true(policy_html.contains("module=policy-hall"))
  assert_true(policy_html.contains("seed=20260727"))
}

///|
test "runtime dashboard reveals recorded assignments instead of inert tabs" {
  let runtime = energy_valley_runtime_state_from_text(
    energy_valley_runtime_test_projection_text(
      "1970-01-01T00:01:40.000Z", "live",
    ),
    1,
    110000.0,
  )
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_energy_valley_dashboard(dashboard_test_dispatch(), {
        ..init_model(),
        energy_board_open: true,
        energy_valley_runtime: runtime,
      }),
    ),
  )
  assert_true(html.contains("Collaborated research"))
  assert_true(html.contains("policy-hall"))
  assert_true(html.contains("1 agent · run-parent"))
  assert_true(html.contains("进入对应建筑查看 Agent"))
  assert_true(html.contains("module=policy-hall"))
  assert_true(html.contains("seed=20260727"))
}

///|
test "pre-migration saved town remains readable after civic entrances were added" {
  let previous_json = @json.parse(
    (
      #|{
      #|  "budget": 1730,
      #|  "buildings": [{
      #|    "name": "旧版工坊",
      #|    "style": "custom-hall",
      #|    "x": 21,
      #|    "y": 24,
      #|    "width": 6,
      #|    "depth": 6,
      #|    "floors": 2
      #|  }],
      #|  "roads": ["19:24"],
      #|  "parks": ["18:23"]
      #|}
    ),
  )
  let save : EnergyValleySave = @json.from_json(previous_json) catch {
    error => fail("previous Energy Valley save must migrate: \{error}")
  }
  assert_eq(save.budget, 1730)
  assert_eq(save.buildings.length(), 1)
  assert_eq(save.buildings[0].entrance_x, None)
  assert_eq(save.buildings[0].entrance_y, None)
  assert_eq(save.roads, ["19:24"])
  assert_eq(save.parks, ["18:23"])
  let roundtrip : EnergyValleySave = @json.from_json(ToJson::to_json(save)) catch {
    error => fail("migrated Energy Valley save must round-trip: \{error}")
  }
  assert_eq(roundtrip.budget, save.budget)
  assert_eq(roundtrip.buildings[0].name, "旧版工坊")
  assert_eq(roundtrip.roads, save.roads)
  assert_eq(roundtrip.parks, save.parks)
}
