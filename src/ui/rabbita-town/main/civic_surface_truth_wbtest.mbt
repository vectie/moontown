///|
fn civic_truth_model(
  source : StateSourceKind,
  health : CivicServiceHealthSnapshot,
) -> Model {
  {
    ..init_model(),
    state_source: source,
    civic_status: Some({
      total: 1,
      operable_count: 1,
      proven_count: if health.proven_by_result {
        1
      } else {
        0
      },
      seeded_count: 0,
      missing_count: 0,
      review_count: health.latest_review_items,
      blocked_count: 0,
      changed_count: 0,
      no_change_count: 0,
      services: [health],
    }),
  }
}

///|
fn civic_truth_html(html : @rabbita.Html) -> String {
  @rabbita.render_to_string(@rabbita.static_cell(html))
}

///|
test "civic truth completion cannot manufacture policy confidence or accepted evidence" {
  let health = {
    ..civic_health_snapshot_fixture(),
    status: "changed",
    proven_by_result: true,
    latest_accepted_facts: 0,
  }
  let model = civic_truth_model(SnapshotFile, health)
  assert_eq(
    civic_surface_status(model, "policy-hall"),
    "记录 · 有结果记录",
  )
  assert_eq(
    civic_surface_evidence(model, "policy-hall"),
    "尚无已审核证据",
  )
  let html = civic_truth_html(render_policy_hall_module_card(model))
  assert_false(html.contains("Confidence"))
  assert_false(html.contains("%"))
  assert_false(html.contains("Checklist ready"))
  assert_true(html.contains("尚无已审核证据"))
  assert_true(html.contains("<details"))
  assert_false(html.contains("<details open"))
  assert_true(html.contains("协议输入"))
  assert_true(html.contains("不是实时设备或服务成功证明"))
}

///|
test "civic truth preserves recorded evidence and pending review without live claims" {
  let model = civic_truth_model(SnapshotFile, {
    ..civic_health_snapshot_fixture(),
    latest_review_items: 2,
    latest_accepted_facts: 3,
    proven_by_result: true,
  })
  assert_eq(civic_surface_status(model, "policy-hall"), "记录 · 待审核")
  assert_eq(
    civic_surface_evidence(model, "policy-hall"),
    "记录中已审核事实 3 条",
  )
  let html = civic_truth_html(render_policy_hall_module_card(model))
  assert_true(html.contains("记录 · 待审核"))
  assert_true(html.contains("记录中已审核事实 3 条"))
  assert_false(html.contains("live"))
}

///|
test "civic truth marks fixture health as example even when it contains accepted counts" {
  let model = civic_truth_model(DemoSimulation, {
    ..civic_health_snapshot_fixture(),
    proven_by_result: true,
    latest_accepted_facts: 99,
  })
  assert_eq(
    civic_surface_status(model, "policy-hall"),
    "示例 · 有结果记录",
  )
  assert_eq(
    civic_surface_evidence(model, "policy-hall"),
    "示例资料 · 不代表真实业务证据",
  )
  let html = civic_truth_html(render_policy_hall_module_card(model))
  assert_true(html.contains("示例业务记录"))
  assert_false(html.contains("记录中已审核事实 99 条"))
}

///|
test "civic truth unavailable snapshots do not look like healthy zero observations" {
  let model = {
    ..init_model(),
    state_source: SnapshotFile,
    civic_status: None,
  }
  assert_eq(civic_surface_status(model, "policy-hall"), "未接入")
  let html = civic_truth_html(render_physical_bridge_module_card(model))
  assert_true(html.contains("未接入设备与遥测"))
  assert_false(html.contains("0 calls"))
  assert_false(html.contains("live telemetry"))
  assert_false(html.contains("%"))
}

///|
test "civic truth example surfaces omit fabricated probabilities and activity metrics" {
  let model = { ..init_model(), tick: 77, }
  let html = civic_truth_html(render_social_talent(model))
  assert_true(html.contains("示例 · 未发送邀请"))
  assert_true(html.contains("示例 · 未认证"))
  assert_false(html.contains("Verified evidence"))
  assert_false(html.contains("Confidence"))
  assert_false(html.contains("%"))
  assert_false(html.contains("Activity brightness"))
  assert_false(html.contains("Route readiness"))
  assert_eq(talent_avenue_verified_card_count(model), 0)
  assert_true(talent_signals(model).all(signal => signal.activity == 0))
  let residents = civic_truth_html(render_resident_agents(model))
  assert_true(residents.contains("非真实账户"))
  assert_false(residents.contains("Visible twins"))
  assert_false(residents.contains("Review queued"))
}

///|
test "civic truth quests defer competition state and never claim offline completion" {
  let model = { ..init_model(), tick: 99, civic_status: None, }
  let html = civic_truth_html(render_civic_quests(model))
  assert_true(html.contains("./hackathon.html"))
  assert_true(html.contains("以赛事工作台为准"))
  assert_true(html.contains("尚未接通真实场地"))
  assert_false(html.contains("Bridge live"))
  assert_false(html.contains("Mock judge scoring"))
  assert_false(html.contains("Valley XP"))
  assert_false(html.contains("%"))
  assert_eq(contest_express_countdown_label(model), "查看赛事日程")
}

///|
test "civic truth district cards show short business context not simulation diagnostics" {
  let model = { ..init_model(), civic_status: None, }
  let html = civic_truth_html(render_civic_modules(model))
  assert_false(html.contains("Queue"))
  assert_false(html.contains("Health"))
  assert_false(html.contains("%"))
  assert_false(html.contains("live telemetry"))
  assert_true(html.contains("打开赛事工作台"))
  assert_true(html.contains("尚未接入真实居民"))
}
