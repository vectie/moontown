///|
test "watch repeated submit issues one command and preserves pending progress" {
  let dispatch : Dispatch[Msg] = Emit(_ => @rabbita.none)
  let commands = Ref(0)
  let submit = fn(_dispatch, _pending) {
    commands.val += 1
    @rabbita.none
  }
  let model = {
    ..init_model(),
    request_title: "Original watch",
    request_prompt: "Watch official sources",
  }
  let (_, pending) = submit_operator_request_update(dispatch, model, submit~)
  let (_, repeated) = submit_operator_request_update(dispatch, pending, submit~)
  let (_, repeated) = submit_operator_request_update(
    dispatch,
    repeated,
    submit~,
  )
  assert_eq(commands.val, 1)
  assert_true(repeated.request_submitting)
  assert_false(operator_request_ready(repeated))
  assert_eq(repeated.request_submission_id, 1)
  assert_eq(repeated.request_status, pending.request_status)
}

///|
test "watch draft stays frozen through edits close reopen and other entry points" {
  let dispatch : Dispatch[Msg] = Emit(_ => @rabbita.none)
  let pending = operator_request_submitting_model({
    ..init_model(),
    request_title: "Original watch",
    request_prompt: "Original prompt",
    request_book_id: "original-book",
    request_cadence: "60",
    request_quality_threshold: "85",
    energy_request_open: true,
  })
  let edits = [
    OperatorRequestTitle("New title"),
    OperatorRequestPrompt("New prompt"),
    OperatorRequestBookId("new-book"),
    OperatorRequestCadence("3"),
    OperatorRequestQualityThreshold("99"),
  ]
  for edit in edits {
    let edited = update_operator_request_form(pending, edit)
    assert_eq(edited.request_title, pending.request_title)
    assert_eq(edited.request_prompt, pending.request_prompt)
    assert_eq(edited.request_book_id, pending.request_book_id)
    assert_eq(edited.request_cadence, pending.request_cadence)
    assert_eq(
      edited.request_quality_threshold,
      pending.request_quality_threshold,
    )
  }
  let (_, closed) = update(dispatch, CloseEnergyRequest, pending)
  assert_false(closed.energy_request_open)
  assert_true(closed.request_submitting)
  let (_, reopened) = update(dispatch, OpenEnergyRequest, closed)
  let (_, from_agent) = update(
    dispatch,
    OpenEnergyRequestForAgent("other-agent"),
    closed,
  )
  let from_indoor = spatial_start_work_model(closed)
  for model in [reopened, from_agent, from_indoor] {
    assert_true(model.energy_request_open)
    assert_true(model.request_submitting)
    assert_eq(model.request_title, "Original watch")
    assert_eq(model.request_prompt, "Original prompt")
    assert_eq(model.request_submission_id, pending.request_submission_id)
    assert_eq(model.request_status, pending.request_status)
  }
}

///|
test "watch matching success unlocks once and stale results cannot attach to a newer attempt" {
  let pending = operator_request_submitting_model({
    ..init_model(),
    energy_request_open: true,
    request_composer: StandingWatchComposer,
  })
  let accepted = "{\"ok\":true,\"request_id\":\"request-first\",\"standing_goal_id\":\"goal-first\",\"status\":\"accepted\"}"
  let (_, saved) = operator_request_result_update(
    pending.request_submission_id,
    accepted,
    pending,
  )
  assert_false(saved.request_submitting)
  assert_eq(saved.spatial_request_id, "request-first")
  let edited = update_operator_request_form(
    saved,
    OperatorRequestTitle("Second watch"),
  )
  assert_eq(edited.request_title, "Second watch")
  let second = operator_request_submitting_model(edited)
  let (_, stale) = operator_request_result_update(
    pending.request_submission_id,
    accepted,
    second,
  )
  assert_true(stale.request_submitting)
  assert_eq(stale.request_submission_id, second.request_submission_id)
  assert_eq(stale.request_status, second.request_status)
  let (_, duplicate) = operator_request_result_update(
    pending.request_submission_id,
    "bad",
    saved,
  )
  assert_eq(duplicate.request_status, saved.request_status)
}

///|
test "watch uncertain responses unlock without retry or claiming a failed save" {
  let pending = operator_request_submitting_model(init_model())
  for
    raw in [
      "{bad json", "{\"ok\":true}", "{\"ok\":true,\"request_id\":\"\",\"standing_goal_id\":\"goal\"}",
      "{\"ok\":false,\"error\":\"Network response lost\"}",
    ] {
    let (_, uncertain) = operator_request_result_update(
      pending.request_submission_id,
      raw,
      pending,
    )
    assert_false(uncertain.request_submitting)
    assert_eq(uncertain.request_submission_id, pending.request_submission_id)
    assert_true(uncertain.request_status.contains("may already be saved"))
    assert_true(uncertain.request_status.contains("Check accepted watches"))
    assert_eq(uncertain.spatial_request_id, pending.spatial_request_id)
    let edited = update_operator_request_form(
      uncertain,
      OperatorRequestTitle("Editable again"),
    )
    assert_eq(edited.request_title, "Editable again")
  }
}

///|
test "watch completion after dismissal preserves newer work selection" {
  let pending = operator_request_submitting_model({
    ..init_model(),
    energy_request_open: false,
    spatial_request_id: "newer-request",
    spatial_selected_work_id: "newer-work",
  })
  let (_, saved) = operator_request_result_update(
    pending.request_submission_id,
    "{\"ok\":true,\"request_id\":\"request-first\",\"standing_goal_id\":\"goal-first\"}",
    pending,
  )
  assert_false(saved.energy_request_open)
  assert_false(saved.request_submitting)
  assert_eq(saved.spatial_request_id, "newer-request")
  assert_eq(saved.spatial_selected_work_id, "newer-work")
}

///|
test "watch rendered save and fields disable while pending and cadence names ticks" {
  let dispatch : Dispatch[Msg] = Emit(_ => @rabbita.none)
  let pending = operator_request_submitting_model(init_model())
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_request_composer(dispatch, pending)),
  )
  assert_true(html.contains("Saving watch..."))
  assert_eq(html.split(" disabled").to_array().length(), 7)
  assert_true(html.contains("Check interval (ticks)"))
  assert_true(html.contains(operator_request_cadence_help()))
  assert_true(html.contains("for=\"request-check-frequency\""))
  let ready = @rabbita.render_to_string(
    @rabbita.static_cell(render_request_composer(dispatch, init_model())),
  )
  assert_false(ready.contains("disabled"))
  assert_true(ready.contains("Save Watch"))
}

///|
test "watch success preserves explicit work selection while composer stays open" {
  let dispatch : Dispatch[Msg] = Emit(_ => @rabbita.none)
  let pending = operator_request_submitting_model({
    ..init_model(),
    energy_request_open: true,
    request_composer: StandingWatchComposer,
    spatial_request_id: "previous-request",
  })
  let (_, selected) = update(dispatch, SelectSpatialWork("newer-work"), pending)
  assert_true(selected.energy_request_open)
  assert_true(selected.request_submitting)
  let (_, saved) = operator_request_result_update(
    pending.request_submission_id,
    "{\"ok\":true,\"request_id\":\"saved-request\",\"standing_goal_id\":\"saved-goal\"}",
    selected,
  )
  assert_false(saved.request_submitting)
  assert_eq(saved.spatial_selected_work_id, "newer-work")
  assert_eq(saved.spatial_request_id, "previous-request")
  assert_true(saved.request_status.contains("Watch accepted"))
}
