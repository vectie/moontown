///|
test "player movement remains on the connected Wenyu road graph" {
  let model = { ..init_model(), player: Some(test_player_avatar()) }
  let next = player_step_direction_model(model, -1, -1)
  guard next.player_motion is Some(motion) else {
    fail("expected a connected road route from the player spawn")
  }
  assert_true(motion.path.length() >= 2)
  for index in 1..<motion.path.length() {
    let point = motion.path[index]
    assert_true(
      golden_valley_walkable(
        next,
        active_energy_valley_seed(),
        point.0.floor().to_int(),
        point.1.floor().to_int(),
      ),
    )
  }
}

///|
test "new resident quests cannot award later steps out of order" {
  let arrived = {
    ..init_model(),
    player: Some(test_player_avatar()),
    quest_done: ["create-avatar"],
  }
  let blocked = complete_quest(arrived, "first-chat")
  assert_true(!blocked.quest_done.contains("first-chat"))
  assert_eq(blocked.spark, 0)
  let walked = complete_quest(arrived, "first-walk")
  let visited = complete_quest(walked, "visit-building")
  let chatted = complete_quest(visited, "first-chat")
  assert_true(chatted.quest_done.contains("first-chat"))
  assert_eq(quest_progress_count(chatted), 4)
}

///|
test "onboarding tool dock reveals only the current task control" {
  let dispatch : Dispatch[Msg] = Emit(fn(_msg) { @rabbita.none })
  let visit_model = {
    ..init_model(),
    player: Some(test_player_avatar()),
    quest_done: ["create-avatar", "first-walk"],
  }
  let visit_html = @rabbita.render_to_string(
    @rabbita.static_cell(render_energy_valley_tool_dock(dispatch, visit_model)),
  )
  assert_true(visit_html.contains("视察"))
  assert_true(!visit_html.contains("铺路"))
  assert_true(!visit_html.contains("实验室"))
  let build_model = {
    ..visit_model,
    quest_done: ["create-avatar", "first-walk", "visit-building", "first-chat"],
  }
  let build_html = @rabbita.render_to_string(
    @rabbita.static_cell(render_energy_valley_tool_dock(dispatch, build_model)),
  )
  assert_true(build_html.contains("研发塔楼"))
  assert_true(build_html.contains("实验室"))
  assert_true(build_html.contains("创新工坊"))
  assert_true(!build_html.contains("拆除"))
}

///|
test "canvas building inspection advances the ordered visit task" {
  let building = golden_valley_buildings(active_energy_valley_seed())[0]
  let ready = {
    ..init_model(),
    player: Some(test_player_avatar()),
    quest_done: ["create-avatar", "first-walk"],
    energy_selected_building: Some(building),
  }
  let advanced = town_life_record_canvas_inspection(ready)
  assert_true(quest_completed(advanced, "visit-building"))
  assert_eq(quest_progress_count(advanced), 3)
}
