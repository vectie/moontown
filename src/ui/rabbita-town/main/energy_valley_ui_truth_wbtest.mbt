///|
test "status provenance legend separates live evidence from ambient preview" {
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_knowledge_flow_preview_legend(init_model())),
  )
  assert_true(html.contains("地图来源"))
  assert_true(html.contains("● REAL · 运行时证据"))
  assert_true(html.contains("◇ PREVIEW · 环境日程"))
  assert_true(html.contains("虚线菱形"))
  assert_false(html.contains("⌕ 研究中"))
  assert_false(html.contains("↺ 修订中"))
}

///|
test "stale retained projection never claims agents are currently running" {
  let live = energy_valley_runtime_state_from_text(
    energy_valley_runtime_test_projection_text(
      "1970-01-01T00:01:40.000Z", "live",
    ),
    1,
    110000.0,
  )
  let stale = energy_valley_runtime_state_at(live, 175000.0)
  let model = {
    ..init_model(),
    energy_status_open: true,
    energy_valley_runtime: stale,
  }
  let snapshot = ecosystem_contract_town_snapshot(model, 20260727)
  let status_html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_energy_valley_status_panel(
        dashboard_test_dispatch(),
        model,
        snapshot,
      ),
    ),
  )
  assert_true(status_html.contains("town-status-open"))
  assert_true(status_html.contains("town-status-body"))
  assert_true(status_html.contains("快照 · 1"))
  assert_true(status_html.contains("不表示 Agent 当前仍在运行"))
  assert_true(status_html.contains("示意画面 · 0 个实时任务"))
  assert_false(status_html.contains("环境居民与真实 Agent 并行"))

  let inspector_model = {
    ..model,
    knowledge_domain_catalog: None,
    energy_selected_building: Some(golden_valley_buildings(20260727)[1]),
  }
  let inspector_snapshot = ecosystem_contract_town_snapshot(
    inspector_model, 20260727,
  )
  let inspector_html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_energy_valley_inspector(
        dashboard_test_dispatch(),
        inspector_model,
        inspector_snapshot,
      ),
    ),
  )
  assert_true(inspector_html.contains("town-generic-inspector"))
  assert_true(inspector_html.contains("最近真实快照"))
  assert_true(inspector_html.contains("保留记录仅供追溯"))
  assert_true(
    inspector_html.contains("不表示这些 Agent 当前仍在执行"),
  )
}
