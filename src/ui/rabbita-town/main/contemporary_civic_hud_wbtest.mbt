///|
test "MoonTown topbar keeps its identity and discloses town state" {
  let dispatch : Dispatch[Msg] = Emit(fn(_message) { @rabbita.none })
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_energy_valley_topbar(dispatch, init_model())),
  )
  assert_true(html.contains("town-topbar-leading"))
  assert_true(html.contains("town-topbar-trailing"))
  assert_eq(html.split("town-topbar-leading").length(), 2)
  assert_eq(html.split("town-topbar-trailing").length(), 2)
  assert_true(html.contains("<details"))
  assert_true(html.contains("class=\"town-topbar-disclosure\""))
  assert_true(html.contains("town-topbar-controls"))
  assert_true(html.contains(">镇况<"))
  assert_true(html.contains("town-topbar-town-state"))
  assert_true(html.contains("MoonTown 镇况"))
  assert_true(!html.contains(">控制<"))
  assert_true(html.contains(">模拟时间<"))
  assert_true(html.contains(">运行看板<"))
  assert_true(html.contains("town-topbar-metric-label"))
  assert_true(html.contains(">居民<"))
  assert_true(html.contains(">能源<"))
}

///|
test "graduated MoonTown quest keeps a clear Knowledge Square next action" {
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
  assert_true(html.contains("常住居民"))
  assert_true(html.contains("继续共建：分享或收藏知识"))
  assert_true(html.contains("前往知识广场"))
  assert_true(html.contains("aria-label=\"打开小镇知识广场\""))
  assert_true(html.contains("quest-tracker-action-civic"))
}

///|
test "active quest uses MoonTown town-duty copy" {
  let dispatch : Dispatch[Msg] = Emit(fn(_message) { @rabbita.none })
  let model = {
    ..init_model(),
    player: Some(test_player_avatar()),
    quest_done: ["create-avatar"],
  }
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_quest_tracker(dispatch, model)),
  )
  assert_true(html.contains("镇务 2/7"))
  assert_true(!html.contains("进度 1/7"))
}

///|
test "five-slot primary dock discloses every specialist tool" {
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
  assert_eq(dock_html.split("town-dock-primary").length(), 6)
  assert_true(dock_html.contains("<details"))
  assert_true(dock_html.contains("class=\"town-dock-more\""))
  assert_true(dock_html.contains(">扩建<"))
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
  assert_true(rail_html.contains("<details"))
  assert_true(
    rail_html.contains("class=\"town-actions town-utility-disclosure"),
  )
  assert_true(rail_html.contains(">镇务<"))
  for
    label in [
      "联络", "居民", "今日", "17号线", "运行状态", "知识广场", "运营",
      "地图诊断",
    ] {
    assert_true(rail_html.contains(label))
  }
  assert_true(rail_html.contains("town-action-primary"))
  assert_true(rail_html.contains("town-action-secondary"))
  assert_true(rail_html.contains("aria-controls=\"town-runtime-status\""))
  assert_true(rail_html.contains("aria-controls=\"map-lab-panel\""))
}

///|
test "graduated resident actions use one keyboard-native disclosure" {
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
    @rabbita.static_cell(render_player_chip(dispatch, model)),
  )
  assert_true(html.contains("<details"))
  assert_true(html.contains("class=\"player-chip-disclosure\""))
  assert_true(html.contains("player-chip-menu-toggle"))
  for label in ["居民", "行走", "跟随", "签到", "编辑"] {
    assert_true(html.contains(label))
  }
  assert_true(html.contains("aria-label=\"点地行走模式\""))
  assert_true(html.contains("aria-label=\"跟随角色\""))
}

///|
test "HUD disclosures form one native exclusive group" {
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
      @rabbita.static_cell(render_energy_valley_topbar(dispatch, model)),
    ) +
    @rabbita.render_to_string(
      @rabbita.static_cell(render_energy_valley_tool_dock(dispatch, model)),
    ) +
    @rabbita.render_to_string(
      @rabbita.static_cell(render_player_chip(dispatch, model)),
    ) +
    @rabbita.render_to_string(
      @rabbita.static_cell(render_town_action_rail(dispatch, model, false, 7)),
    )
  assert_eq(html.split("name=\"moontown-hud-disclosure\"").length(), 5)
}
