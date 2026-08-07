///|
test "analytics v1 dictionary is exact and authoritative" {
  let dictionary = analytics_event_dictionary()
  assert_eq(dictionary.length(), 20)
  assert_eq(analytics_event_dictionary_version(), "v1 · 20 种")
  for index, definition in dictionary {
    assert_true(analytics_event_is_known(definition.name))
    assert_eq(analytics_event_label(definition.name), definition.label)
    for other_index, other in dictionary {
      if index != other_index {
        assert_true(definition.name != other.name)
      }
    }
  }
  assert_true(!analytics_event_is_known("invented_event"))
  assert_eq(analytics_event_label("invented_event"), "未知事件")
}

///|
test "analytics ingestion rejects unknown names and preserves its wire format" {
  let base = { ..init_model(), analytics: [], tick: 0 }
  let unknown = track_event(base, "invented_event", "ignored")
  assert_eq(unknown.analytics.length(), 0)
  let next = track_event(base, "phone_send", "mayor|hello\nagain")
  assert_eq(next.analytics.length(), 1)
  assert_eq(next.analytics[0], "1|phone_send|mayor／hello again")
  assert_eq(analytics_count_on(next, 1, "phone_send"), 1)
  assert_eq(analytics_count_on(next, 1, "phone"), 0)
}

///|
test "analytics ring keeps only the configured local activity window" {
  let mut model = { ..init_model(), analytics: [], tick: 0 }
  for index in 0..<(analytics_ring_capacity + 2) {
    model = track_event(model, "walk_step", "step-\{index}")
  }
  assert_eq(model.analytics.length(), analytics_ring_capacity)
  assert_true(model.analytics[0].contains("step-2"))
  assert_true(
    model.analytics[analytics_ring_capacity - 1].contains(
      "step-\{analytics_ring_capacity + 1}",
    ),
  )
}

///|
test "ops metrics use exact local records without a demo baseline" {
  let model = {
    ..init_model(),
    tick: 0,
    analytics: [
      "1|avatar_create|谷民", "1|walk_step|10:10", "1|phone_send|mayor", "1|phone_receive|mayor",
      "1|build_place|实验室",
    ],
    quest_done: ["create-avatar", "first-walk", "first-chat"],
  }
  assert_eq(analytics_today_activity(model), 5)
  assert_eq(analytics_today_builds(model), 1)
  assert_eq(analytics_today_chat_sent(model), 1)
  assert_eq(analytics_today_chat_replies(model), 1)
  assert_eq(analytics_today_chats(model), 2)
  assert_eq(analytics_activity_series(model, 7), [0, 0, 0, 0, 0, 0, 5])
  assert_eq(analytics_active_recorded_days(model, 7), 1)
  assert_eq(analytics_funnel_completed(model), 3)
}

///|
test "ops report separates local records from runtime truth" {
  let model = {
    ..init_model(),
    tick: 0,
    analytics: [
      "1|phone_send|mayor", "1|phone_receive|mayor", "1|build_place|实验室",
    ],
    spark: 75,
    energy_valley_runtime: energy_valley_runtime_loading_state(),
  }
  let report = ops_report_line(model)
  assert_true(report.contains("本机活动 3 条"))
  assert_true(report.contains("本地剧本消息 发送1/回复1"))
  assert_true(report.contains("谷光余额 75"))
  assert_true(report.contains("真实运行时（正在连接）"))
  assert_true(!report.contains("DAU"))
  assert_true(!report.contains("留存"))
  assert_true(!report.contains("流通"))
}

///|
test "board guide and durable town controls emit their declared events" {
  let dispatch : Dispatch[Msg] = Emit(fn(_msg) { @rabbita.none })
  let selected_building = golden_valley_buildings(20260727)[0]
  let base = {
    ..init_model(),
    analytics: [],
    tick: 0,
    selection: Agent("agent-test"),
    energy_selected_building: Some(selected_building),
    energy_first_agent_open: true,
  }
  let (_, board_open) = update_non_form_message(
    dispatch,
    ToggleEnergyBoard,
    base,
  )
  assert_true(board_open.energy_board_open)
  assert_true(board_open.energy_selected_building is None)
  assert_true(board_open.selection is Overview)
  assert_true(!board_open.energy_first_agent_open)
  assert_eq(analytics_count_on(board_open, 1, "board_open"), 1)
  let (_, board_closed) = update_non_form_message(
    dispatch,
    ToggleEnergyBoard,
    board_open,
  )
  assert_true(!board_closed.energy_board_open)
  assert_eq(analytics_count_on(board_closed, 1, "board_open"), 1)
  let (_, guide_open) = update_non_form_message(
    dispatch,
    OpenEnergyGuide,
    board_closed,
  )
  assert_true(guide_open.energy_guide_open)
  assert_eq(analytics_count_on(guide_open, 1, "guide_open"), 1)
  let (_, walk_mode) = update_non_form_message(
    dispatch,
    ToggleWalkMode,
    guide_open,
  )
  assert_eq(analytics_count_on(walk_mode, 1, "walk_mode"), 1)
  let (_, metro) = update_non_form_message(dispatch, ToggleMetro, walk_mode)
  assert_eq(analytics_count_on(metro, 1, "metro_toggle"), 1)
  let (_, ops) = ops_toggle_update(metro)
  assert_eq(analytics_count_on(ops, 1, "ops_open"), 1)
}

///|
test "a synchronous offline phone reply records send and receive" {
  let model = {
    ..init_model(),
    analytics: [],
    tick: 0,
    phone_contact: "mayor",
    phone_draft: "你好",
    phone_log: [],
  }
  let next = phone_send_model(model)
  assert_eq(next.phone_log.length(), 2)
  assert_eq(analytics_count_on(next, 1, "phone_send"), 1)
  assert_eq(analytics_count_on(next, 1, "phone_receive"), 1)
}

///|
test "ops runtime metrics preserve live versus stale snapshot truth" {
  let live = energy_valley_runtime_state_from_text(
    energy_valley_runtime_test_projection_text(
      "1970-01-01T00:01:40.000Z", "live",
    ),
    1,
    110000.0,
  )
  let live_metrics = ops_runtime_metrics({
    ..init_model(),
    energy_valley_runtime: live,
  })
  assert_eq(live_metrics.phase, "实时")
  assert_eq(live_metrics.agents, 1)
  assert_eq(live_metrics.tasks, 1)
  assert_eq(live_metrics.active, 1)
  let stale = energy_valley_runtime_state_at(live, 175000.0)
  let stale_metrics = ops_runtime_metrics({
    ..init_model(),
    energy_valley_runtime: stale,
  })
  assert_eq(stale_metrics.phase, "过期快照")
  assert_eq(stale_metrics.agents, 1)
  assert_eq(stale_metrics.tasks, 1)
}

///|
test "ops overview exposes five accessible truthful views" {
  let dispatch : Dispatch[Msg] = Emit(fn(_msg) { @rabbita.none })
  let model = {
    ..init_model(),
    ops_open: true,
    ops_tab: 0,
    analytics: [],
    energy_valley_runtime: energy_valley_runtime_loading_state(),
  }
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_ops_center(dispatch, model)),
  )
  assert_true(html.contains("视图 1 · 本机活动"))
  assert_true(html.contains("视图 2 · 本日行为构成"))
  assert_true(html.contains("视图 3 · 当前角色旅程"))
  assert_true(html.contains("视图 4 · 真实运行时快照"))
  assert_true(html.contains("视图 5 · 本地知识资产"))
  assert_true(html.contains("role=\"img\""))
  assert_true(html.contains("<title>本机最近七个游戏日活动</title>"))
  assert_true(html.contains("事件条数，不是 DAU"))
  assert_true(html.contains("本机档案，不是留存率"))
  assert_true(html.contains("演示内容"))
  assert_true(!html.contains("含演示基线"))
}

///|
test "ops report copy states local persistence without delivery claims" {
  let dispatch : Dispatch[Msg] = Emit(fn(_msg) { @rabbita.none })
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_ops_reports(dispatch, init_model())),
  )
  assert_true(html.contains("随本机小镇生活存档保存"))
  assert_true(
    html.contains("不会冒充 DAU、留存或已送达的外部日报"),
  )
}

///|
test "scheduled ops report is emitted once per simulated day" {
  let day_one = {
    ..init_model(),
    tick: 100,
    energy_time_scale: 60,
    last_report_tick: 24,
    ops_reports: [],
  }
  assert_eq(energy_valley_sim_day(day_one), 1)
  assert_eq(ops_maybe_scheduled_report(day_one).ops_reports.length(), 0)
  let day_two = { ..day_one, tick: 888 }
  assert_eq(energy_valley_sim_day(day_two), 2)
  let reported = ops_maybe_scheduled_report(day_two)
  assert_eq(reported.ops_reports.length(), 1)
  assert_true(reported.ops_reports[0].has_prefix("第1天"))
  assert_true(!reported.ops_reports[0].has_prefix("第2天"))
  assert_eq(reported.last_report_tick, 888)
  assert_eq(ops_maybe_scheduled_report(reported).ops_reports.length(), 1)
}

///|
test "scheduled ops reports catch up each completed day with day-local counts" {
  let day_three = {
    ..init_model(),
    tick: 2328,
    energy_time_scale: 60,
    last_report_tick: 0,
    analytics: [
      "1|phone_send|mayor", "1|phone_receive|mayor", "2|build_place|实验室",
    ],
    ops_reports: [],
  }
  assert_eq(energy_valley_sim_day(day_three), 3)
  let reported = ops_maybe_scheduled_report(day_three)
  assert_eq(reported.ops_reports.length(), 2)
  assert_true(reported.ops_reports[0].contains("第1天 · 本机活动 2 条"))
  assert_true(reported.ops_reports[0].contains("发送1/回复1"))
  assert_true(reported.ops_reports[1].contains("第2天 · 本机活动 1 条"))
  assert_true(reported.ops_reports[1].contains("建造 1 次"))
}

///|
test "talent examples do not expose a no-op invitation" {
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_ops_growth()),
  )
  assert_true(html.contains("邀请通道未接入"))
  assert_true(html.contains("disabled"))
  assert_true(html.contains("邀请未开放"))
  assert_true(!html.contains("发出邀请"))
  assert_true(html.contains("演示机构卡"))
}
