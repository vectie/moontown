///|
test "Policy Hall alone exposes the contextual question action" {
  let buildings = golden_valley_buildings(20260727)
  let dispatch = moonclaw_guide_test_dispatch()
  let policy_html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_policy_hall_question_action(dispatch, buildings[1]),
    ),
  )
  assert_true(policy_html.contains("问昌平青创政策"))
  assert_true(policy_html.contains("询问政策 →"))
  assert_true(policy_html.contains("官网、OCR 与待复核项"))
  assert_true(
    policy_html.contains(
      "aria-label=\"打开 Moonclaw，询问昌平青年创新创业政策\"",
    ),
  )
  assert_eq(
    @rabbita.render_to_string(
      @rabbita.static_cell(
        render_policy_hall_question_action(dispatch, buildings[0]),
      ),
    ),
    "",
  )
}

///|
test "Policy Hall publication has a keyboard-operable map entry" {
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_policy_hall_map_entry(moonclaw_guide_test_dispatch(), init_model()),
    ),
  )
  assert_true(html.contains("昌平青创政策"))
  assert_true(html.contains("进入政策大厅"))
  assert_true(
    html.contains(
      "aria-label=\"进入政策大厅，查看并询问昌平青年创新创业政策\"",
    ),
  )
  let selected = {
    ..init_model(),
    energy_selected_building: Some(golden_valley_buildings(20260727)[1]),
  }
  assert_eq(
    @rabbita.render_to_string(
      @rabbita.static_cell(
        render_policy_hall_map_entry(moonclaw_guide_test_dispatch(), selected),
      ),
    ),
    "",
  )
}

///|
test "selected Policy Hall sends the strict allowlisted guide context" {
  let buildings = golden_valley_buildings(20260727)
  let generic = init_model()
  assert_false(policy_hall_question_selected(generic))
  assert_eq(moonclaw_guide_context(generic), "before-avatar")
  let policy = { ..generic, energy_selected_building: Some(buildings[1]) }
  assert_true(policy_hall_question_selected(policy))
  assert_eq(
    moonclaw_guide_context(policy),
    "policy-hall:changping-youth-entrepreneurship-policy",
  )
}

///|
test "Policy Hall guide explains evidence boundaries and gathers intake facts" {
  let buildings = golden_valley_buildings(20260727)
  let model = {
    ..init_model(),
    phone_open: true,
    phone_contact: moonclaw_guide_contact_id,
    energy_selected_building: Some(buildings[1]),
  }
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_phone_panel(moonclaw_guide_test_dispatch(), model),
    ),
  )
  assert_true(html.contains("Policy Hall · 昌平青创政策问答"))
  assert_true(html.contains("答复边界"))
  assert_true(html.contains("信息导航不等于审批意见"))
  assert_true(html.contains("年龄、学历或出站情况"))
  assert_true(html.contains("还缺哪些资格信息"))
  assert_true(html.contains("需要准备哪些材料"))
  assert_true(html.contains("必须向主管部门复核"))
  assert_true(html.contains("描述你的情况，询问昌平青创政策"))
  assert_true(
    html.contains("我 29 岁，硕士，在昌注册公司 8 个月"),
  )
  assert_true(
    html.contains("aria-label=\"发送昌平青年创新创业政策问题\""),
  )
  assert_false(html.contains("我现在应该先做什么？"))
}
