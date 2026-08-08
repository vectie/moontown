///|
test "contemporary civic topbar keeps explicit leading and trailing anchors" {
  let dispatch : Dispatch[Msg] = Emit(fn(_message) { @rabbita.none })
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_energy_valley_topbar(dispatch, init_model())),
  )
  assert_true(html.contains("town-topbar-leading"))
  assert_true(html.contains("town-topbar-controls"))
  assert_true(html.contains("town-topbar-trailing"))
  assert_true(html.contains("town-topbar-metric-label"))
  assert_true(html.contains(">居民<"))
  assert_true(html.contains(">能源<"))
}

///|
test "graduated quest keeps a clear Knowledge Square next action" {
  let dispatch : Dispatch[Msg] = Emit(fn(_message) { @rabbita.none })
  let model = {
    ..init_model(),
    player: Some(test_player_avatar()),
    quest_done: [
      "create-avatar", "first-walk", "visit-building", "first-chat", "build-knowledge",
      "publish-knowledge", "collect-building",
    ],
  }
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_quest_tracker(dispatch, model)),
  )
  assert_true(html.contains("下一步：分享或收藏知识"))
  assert_true(html.contains("打开知识广场"))
  assert_true(html.contains("aria-label=\"打开小镇知识广场\""))
  assert_true(html.contains("quest-tracker-action-civic"))
}

///|
test "five-slot build viewport keeps every graduated tool accessible" {
  let dispatch : Dispatch[Msg] = Emit(fn(_message) { @rabbita.none })
  let model = {
    ..init_model(),
    player: Some(test_player_avatar()),
    quest_done: [
      "create-avatar", "first-walk", "visit-building", "first-chat", "build-knowledge",
      "publish-knowledge", "collect-building",
    ],
  }
  let dock_html = @rabbita.render_to_string(
    @rabbita.static_cell(render_energy_valley_tool_dock(dispatch, model)),
  )
  for
    label in [
      "视察", "铺路", "造林", "拆除", "研发塔楼", "实验室", "创新工坊",
      "人才公寓",
    ] {
    assert_true(dock_html.contains(label))
  }
  let rail_html = @rabbita.render_to_string(
    @rabbita.static_cell(render_town_action_rail(dispatch, model, false, 7)),
  )
  assert_true(rail_html.contains("town-action-primary"))
  assert_true(rail_html.contains("town-action-secondary"))
  assert_true(rail_html.contains("知识广场"))
}
