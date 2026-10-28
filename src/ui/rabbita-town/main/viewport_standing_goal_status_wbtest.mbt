///|
fn standing_goal_work_fixture(
  enabled~ : Bool = true,
  next_due_tick~ : Int32 = 50,
) -> StandingGoalSnapshot {
  {
    id: "watch-test",
    title: "研究动态",
    prompt: "检查资料并记录变化",
    target_book_id: None,
    cadence_ticks: 30,
    next_due_tick,
    last_run_tick: None,
    enabled,
    source_policy: "saved sources",
    quality_threshold: 80,
  }
}

///|
test "standing goal summary distinguishes configuration from execution" {
  assert_eq(
    standing_goal_work_status(standing_goal_work_fixture(), Some(10)),
    "已启用",
  )
  assert_eq(
    standing_goal_work_status(standing_goal_work_fixture(), Some(50)),
    "待检查",
  )
  assert_eq(
    standing_goal_work_status(standing_goal_work_fixture(), Some(70)),
    "待检查",
  )
  assert_eq(
    standing_goal_work_status(standing_goal_work_fixture(), None),
    "待同步",
  )
  assert_eq(
    standing_goal_work_status(
      standing_goal_work_fixture(enabled=false),
      Some(70),
    ),
    "已暂停",
  )
}

///|
test "standing goal summary never calls missing runtime live" {
  let model = { ..init_model(), state_source: StateSourceKind::DemoSimulation, }
  assert_true(standing_goal_work_source(model) != "已保存的任务")
}

///|
test "automatic task card keeps schedule internals behind closed details" {
  let model = {
    ..init_model(),
    state_source: StateSourceKind::DemoSimulation,
    standing_goals: [standing_goal_work_fixture()],
  }
  let html = disclosure_test_html(render_standing_goal_work_panel(model))
  let primary = html.split("<details").to_array()[0]
  assert_true(primary.contains("自动任务"))
  assert_true(primary.contains("演示配置"))
  assert_true(primary.contains("1 已启用"))
  assert_false(primary.contains("watch-test"))
  assert_false(primary.contains("tick"))
  assert_false(html.contains(" open"))
  assert_true(html.contains("watch-test"))
  assert_true(html.contains("查看任务"))
}
