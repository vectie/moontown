///|
test "resident and chronicle surfaces are mutually exclusive with town panels" {
  let dispatch : Dispatch[Msg] = Emit(fn(_msg) { @rabbita.none })
  let base = {
    ..init_model(),
    phone_open: true,
    square_open: true,
    ops_open: true,
    energy_request_open: true,
    energy_board_open: true,
    energy_guide_open: true,
    energy_reset_open: true,
    knowledge_dialog_open: true,
  }
  let (_, residents) = update_non_form_message(
    dispatch,
    ToggleResidentExplorer,
    base,
  )
  assert_true(residents.resident_explorer_open)
  assert_true(!residents.town_chronicle_open)
  assert_true(!residents.phone_open)
  assert_true(!residents.square_open)
  assert_true(!residents.ops_open)
  assert_true(!residents.energy_request_open)
  assert_true(!residents.energy_board_open)
  assert_true(!residents.energy_guide_open)
  assert_true(!residents.energy_reset_open)
  assert_true(!residents.knowledge_dialog_open)

  let (_, searched) = update_non_form_message(
    dispatch,
    ResidentSearch("review owl"),
    residents,
  )
  assert_eq(searched.resident_query, "review owl")

  let (_, chronicle) = update_non_form_message(
    dispatch,
    ToggleTownChronicle,
    searched,
  )
  assert_true(chronicle.town_chronicle_open)
  assert_true(!chronicle.resident_explorer_open)
  assert_true(chronicle.selection is Overview)
}

///|
test "selecting a resident closes discovery surfaces without inventing work" {
  let dispatch : Dispatch[Msg] = Emit(fn(_msg) { @rabbita.none })
  let base = {
    ..init_model(),
    resident_explorer_open: true,
    town_chronicle_open: true,
    phone_open: true,
    square_open: true,
    ops_open: true,
    energy_guide_open: true,
    energy_reset_open: true,
    knowledge_dialog_open: true,
  }
  let (_, selected) = update_non_form_message(
    dispatch,
    SelectAgent("runtime-agent-7"),
    base,
  )
  assert_true(selected.selection is Agent("runtime-agent-7"))
  assert_true(!selected.resident_explorer_open)
  assert_true(!selected.town_chronicle_open)
  assert_true(selected.energy_selected_building is None)
  assert_true(!selected.phone_open)
  assert_true(!selected.square_open)
  assert_true(!selected.ops_open)
  assert_true(!selected.energy_guide_open)
  assert_true(!selected.energy_reset_open)
  assert_true(!selected.knowledge_dialog_open)
}

///|
test "resident request carries exact runtime work, run, and book context" {
  let dispatch : Dispatch[Msg] = Emit(fn(_msg) { @rabbita.none })
  let model = {
    ..resident_explorer_test_model(),
    phone_open: true,
    selection: Agent("agent-moon"),
    request_book_id: "wrong-default",
  }
  let (_, next) = update_non_form_message(
    dispatch,
    OpenEnergyRequestForAgent("runtime:agent-moon"),
    model,
  )
  assert_true(next.energy_request_open)
  assert_true(!next.phone_open)
  assert_true(next.selection is Overview)
  assert_eq(next.request_book_id, "research-ai-agents")
  assert_true(next.request_title.contains("月灯"))
  assert_true(next.request_prompt.contains("research-task"))
  assert_true(next.request_prompt.contains("run-parent"))
  assert_true(next.request_prompt.contains("调度策略"))
  assert_true(next.request_prompt.contains("不代表定向派单"))
  assert_false(next.request_prompt.contains("/Users/"))
}

///|
test "missing runtime building preserves resident context and awards nothing" {
  let dispatch : Dispatch[Msg] = Emit(fn(_msg) { @rabbita.none })
  let base = {
    ..init_model(),
    selection: Agent("agent-moon"),
    resident_explorer_open: true,
    quest_done: ["create-avatar", "first-walk"],
  }
  let analytics_before = base.analytics.length()
  let (_, next) = update_non_form_message(
    dispatch,
    OpenEnergyBuilding("missing-runtime-building"),
    base,
  )
  assert_true(next.selection is Agent("agent-moon"))
  assert_true(next.resident_explorer_open)
  assert_true(next.energy_selected_building is None)
  assert_false(next.quest_done.contains("visit-building"))
  assert_eq(next.analytics.length(), analytics_before)
  assert_true(next.energy_toast.contains("not on this map"))
}

///|
test "resolved runtime building records a visit only after selection succeeds" {
  let dispatch : Dispatch[Msg] = Emit(fn(_msg) { @rabbita.none })
  let base = {
    ..init_model(),
    selection: Agent("agent-moon"),
    resident_explorer_open: true,
    quest_done: ["create-avatar", "first-walk"],
  }
  let analytics_before = base.analytics.length()
  let (_, next) = update_non_form_message(
    dispatch,
    OpenEnergyBuilding("town-shell"),
    base,
  )
  assert_true(next.selection is Overview)
  assert_true(!next.resident_explorer_open)
  assert_true(next.energy_selected_building is Some(_))
  assert_true(next.quest_done.contains("visit-building"))
  assert_true(next.analytics.length() > analytics_before)
}
