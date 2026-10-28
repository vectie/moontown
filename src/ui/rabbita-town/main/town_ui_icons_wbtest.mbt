///|
test "compact icons are decorative and controls retain accessible names" {
  let icon = disclosure_test_html(town_ui_icon("close"))
  assert_true(icon.contains("aria-hidden=\"true\""))
  assert_true(icon.contains("viewBox=\"0 0 24 24\""))
  let dispatch : Dispatch[Msg] = Emit(_ => @rabbita.none)
  let dialog = disclosure_test_html(
    render_energy_valley_request_dialog(dispatch, init_model()),
  )
  assert_true(dialog.contains("aria-label=\"关闭工作面板\""))
  assert_true(dialog.contains("title=\"关闭\""))
  assert_false(dialog.contains("✕"))
}

///|
test "service menu keeps daily actions short and infrastructure tools secondary" {
  let dispatch : Dispatch[Msg] = Emit(_ => @rabbita.none)
  let html = disclosure_test_html(
    render_town_action_rail(dispatch, init_model(), false, 7),
  )
  let primary = html.split("<details class=\"town-advanced\"").to_array()[0]
  assert_true(primary.contains("aria-label=\"创建工作请求\""))
  assert_true(
    primary.contains(
      "aria-label=\"进入政策大厅，查看并询问昌平政策\"",
    ),
  )
  assert_true(primary.contains(">成果<"))
  assert_true(primary.contains(">待我处理<"))
  assert_false(primary.contains("aria-label=\"Imported outputs\""))
  assert_true(html.contains("aria-label=\"Imported outputs\""))
  assert_false(primary.contains("地铁 17 号线图层"))
  assert_false(primary.contains("能源谷运营中心"))
  assert_true(html.contains("地铁 17 号线图层"))
  assert_true(html.contains("能源谷运营中心"))
}

///|
test "request labels are compact without changing stable field ids" {
  assert_eq(request_field_id("Target book"), "watch-target-book")
  assert_eq(request_display_label("Target book"), "目标知识册")
  let dispatch : Dispatch[Msg] = Emit(_ => @rabbita.none)
  let html = disclosure_test_html(
    render_request_composer(dispatch, init_model()),
  )
  let before_submit = html.split("request-submit-row").to_array()[0]
  assert_true(before_submit.contains("watch-request"))
  assert_false(html.contains("Saves a durable watch"))
  assert_false(html.contains("NEW REQUEST"))
}

///|
test "quiet readiness never hides actionable status" {
  assert_eq(
    disclosure_test_html(
      render_request_status_line("Ready to submit a standing watch request."),
    ),
    "",
  )
  let error = disclosure_test_html(
    render_request_status_line("Could not save: choose a target Book"),
  )
  assert_true(error.contains("choose a target Book"))
  assert_true(error.contains("role=\"status\""))
}

///|
test "collaboration keeps results reachable and folds technical source tools" {
  let dispatch : Dispatch[Msg] = Emit(_ => @rabbita.none)
  let html = disclosure_test_html(
    render_collaboration_composer(dispatch, @collaboration.Client::new()),
  )
  let primary = html.split("<details").to_array()[0]
  assert_true(primary.contains("collaboration-title"))
  assert_true(primary.contains("collaboration-question"))
  assert_false(html.contains("collaboration-results"))
  let workspace = disclosure_test_html(
    render_request_desk(dispatch, {
      ..init_model(),
      request_composer: CollaborationComposer,
    }),
  )
  let workspace_primary = workspace.split("<details").to_array()[0]
  assert_true(workspace_primary.contains(">成果<"))
  assert_true(workspace_primary.contains(">待我处理<"))
  assert_true(html.contains("来源记录与草稿复用"))
  assert_true(html.contains(">草稿选项<"))
  assert_true(html.contains(">来源记录<"))
  assert_true(html.contains(">导入比较<"))
}
