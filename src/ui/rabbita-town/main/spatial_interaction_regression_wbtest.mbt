///|
test "hotspots serialize numeric coordinates and share the room camera" {
  for underground in [false, true] {
    let (x, y) = spatial_scene_anchor(100, 100, 0.2, 0.7, underground)
    let css = spatial_scene_hotspot_style(0.2, 0.7, underground, 11.0, 14.0)
    assert_eq(css[0], "left: \{x}%")
    assert_eq(css[1], "top: \{y}%")
    assert_false(css.join(";").contains("{"))
    assert_true(
      css != spatial_scene_hotspot_style(0.8, 0.2, underground, 11.0, 14.0),
    )
  }
}

///|
test "art scales linearly on phones and both projected floor axes are 2 to 1" {
  assert_eq(spatial_scene_scale(350) * 4.0, spatial_scene_scale(1400))
  for underground in [false, true] {
    let (nx, ny) = spatial_scene_anchor(1200, 900, 0.0, 0.0, underground)
    let (ex, ey) = spatial_scene_anchor(1200, 900, 1.0, 0.0, underground)
    let (wx, wy) = spatial_scene_anchor(1200, 900, 0.0, 1.0, underground)
    assert_true(((ey - ny) / (ex - nx) - 0.5).abs() < 0.000001)
    assert_true(((wy - ny) / (nx - wx) - 0.5).abs() < 0.000001)
    let source = spatial_scene_camera(underground)
    let (xx, yx, yy, tx, ty) = spatial_scene_plate_registration(underground)
    assert_true(((source.east_x * xx + tx) * 1200.0 - ex).abs() < 0.000001)
    assert_true(
      ((source.east_x * yx + source.east_y * yy + ty) * 900.0 - ey).abs() <
      0.000001,
    )
  }
}

///|
test "compute deep links restore the return building and invalid ids fail safely" {
  let layer = town_spatial_layer_for_route("compute", "policy-hall")
  guard layer is Underground(Some(building)) else { fail("lost origin") }
  assert_eq(golden_valley_building_module_key(building), "policy-hall")
  assert_true(
    town_spatial_layer_for_route("compute", "missing") is Underground(None),
  )
  assert_true(town_spatial_layer_for_route("indoor", "missing") is Outdoor)
}

///|
test "room interaction opens a contextual request without submitting it" {
  let dispatch : Dispatch[Msg] = Emit(fn(_) { @rabbita.none })
  let base = {
    ..init_model(),
    town_spatial_layer: town_spatial_layer_for_route("indoor", "policy-hall"),
  }
  let (_, selected) = update(dispatch, SelectIndoorSlot("evidence-desk"), base)
  let (_, request) = update(dispatch, StartIndoorWork, selected)
  assert_true(request.energy_request_open)
  guard request.town_spatial_layer is Indoor(request_building) else {
    fail("request left its room")
  }
  assert_eq(golden_valley_building_module_key(request_building), "policy-hall")
  assert_false(request.request_submitting)
  assert_true(request.request_prompt.contains("evidence-desk"))
  assert_true(request.request_prompt.contains("policy-hall"))
  assert_eq(moonclaw_guide_context(base), "policy-hall:changping")
  let (_, underground) = update(dispatch, OpenSecretComputeRoom, selected)
  let (_, returned) = update(dispatch, CloseSecretComputeRoom, underground)
  assert_eq(returned.indoor_selected_slot_id, "evidence-desk")
}

///|
test "work selection crosses layers without inventing execution evidence" {
  let dispatch : Dispatch[Msg] = Emit(fn(_) { @rabbita.none })
  let base = resident_explorer_test_model()
  let (_, selected) = update(dispatch, SelectSpatialWork("research-task"), base)
  let (_, underground) = update(dispatch, OpenSecretComputeRoom, selected)
  assert_eq(
    spatial_selected_work(underground).unwrap().runId,
    Some("run-parent"),
  )
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_spatial_work_journey(dispatch, underground)),
  )
  assert_true(html.contains("run-parent"))
  assert_true(html.contains("没有可验证的 Run"))
  assert_false(html.contains("/Users/example/private"))
  assert_false(html.contains("记录审阅 +10"))
}

///|
test "only completed evidenced work can be reviewed and reward is idempotent" {
  let base = resident_explorer_test_model()
  let projection = base.energy_valley_runtime.projection.unwrap()
  let task = projection.tasks[0]
  assert_false(spatial_work_can_review(task))
  let completed = { ..task, status: "completed", }
  assert_true(spatial_work_can_review(completed))
  assert_false(spatial_work_can_review({ ..completed, resultLinks: None, }))
  let model = {
    ..base,
    spatial_selected_work_id: completed.id,
    energy_valley_runtime: {
      ..base.energy_valley_runtime,
      projection: Some({ ..projection, tasks: [], history: Some([completed]), }),
    },
  }
  let reviewed = spatial_review_work_model(model)
  assert_eq(reviewed.spark, model.spark + 10)
  assert_eq(spatial_review_work_model(reviewed).spark, reviewed.spark)
  assert_eq(
    spatial_work_review_key(completed),
    spatial_work_review_key({ ..completed, updatedAt: Some("later-poll"), }),
  )
}

///|
test "accepted request correlates by request id rather than task title" {
  let base = resident_explorer_test_model()
  let projection = base.energy_valley_runtime.projection.unwrap()
  let task = { ..projection.tasks[0], requestId: Some("request-123"), }
  let model = {
    ..base,
    spatial_request_id: "request-123",
    energy_valley_runtime: {
      ..base.energy_valley_runtime,
      projection: Some({ ..projection, tasks: [task], }),
    },
  }
  assert_eq(spatial_selected_work(model).unwrap().id, task.id)
  assert_true(
    spatial_selected_work({ ..model, spatial_request_id: "unrelated", }) is None,
  )
}

///|
test "area routes show their content without active map controls behind them" {
  let dispatch : Dispatch[Msg] = Emit(fn(_) { @rabbita.none })
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_energy_valley_page(dispatch, {
        ..init_model(),
        dashboard_section: Some(SocialCapitalSection),
        town_spatial_layer: Outdoor,
      }),
    ),
  )
  assert_true(html.contains("town-area-route"))
  assert_true(html.contains("Talent"))
  assert_true(html.contains("不代表当前已核验或实时执行"))
  assert_false(html.contains("energy-valley-canvas"))
}
