///|
test "default valley is generated from the preserved Energy Valley process" {
  let seed = 20260727
  let world = exact_energy_valley_generate_int(seed)
  assert_eq(world.tiles.length(), 52)
  assert_eq(world.tiles[0].length(), 56)
  assert_eq(world.landmarks.bridge_rows, [11, 27, 43])
  assert_eq(world.terrain_at(17, 23), Some("plaza"))
  assert_eq(world.terrain_at(48, 43), Some("bridge"))
  assert_eq(world.structure_at(15, 5), Some(("row", 3)))
  let buildings = golden_valley_buildings(seed)
  assert_eq(buildings[0].name, "市政厅")
  assert_eq((buildings[0].x, buildings[0].y), (17, 23))
  assert_eq(buildings[1].name, "活力塔")
  assert_eq((buildings[1].x, buildings[1].y), (24, 15))
}

///|
test "road placement uses the reference bridge price and park rejects water" {
  let base = { ..init_model(), energy_weather: Sunny }
  let bridge = energy_valley_canvas_click_model(
    { ..base, energy_tool: RoadTool },
    914,
    938,
  )
  assert_eq(bridge.energy_build_budget, 2280)
  assert_eq(bridge.energy_toast, "新桥贯通温榆河（-120）")
  assert_eq(bridge.energy_roads.length(), 1)
  let park = energy_valley_canvas_click_model(
    { ..base, energy_tool: ParkTool },
    914,
    938,
  )
  assert_eq(park.energy_build_budget, 2400)
  assert_eq(park.energy_toast, "仅可改造草地、草甸或农田")
}

///|
test "custom buildings use the reference half-price demolition refund" {
  let building = {
    name: "创新工坊 1",
    style: "custom-hall",
    x: 20,
    y: 20,
    width: 2,
    depth: 2,
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
  assert_eq(golden_valley_building_module_key(buildings[2]), "policy-hall")
  assert_eq(golden_valley_building_module_key(buildings[8]), "social-square")
  assert_eq(golden_valley_building_module_key(buildings[9]), "energy-lab")
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
        energy_selected_building: Some(buildings[2]),
      }),
    ),
  )
  assert_true(policy_html.contains("Collaborated research"))
  assert_true(policy_html.contains("running · run-parent"))
  assert_true(policy_html.contains("在内 Agent"))
}
