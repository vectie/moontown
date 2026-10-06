///|
fn material_watch_form_fixture() -> Model {
  let fields = [
    SetRequestWatchMode(LocalMaterialWatch),
    SetRequestTitle("Customer assumption"),
    SetRequestPrompt("Keep the customer launch assumption current"),
    SetRequestBookId("research-material"),
    SetRequestCadence("10"),
    SetRequestQualityThreshold("85"),
    SetRequestMaterialSources("sources/customer.txt\nsources/market.txt"),
    SetRequestMaterialAcceptance(
      "Show exact changed source and retain review pending",
    ),
    SetRequestMaterialNextAction(
      "Founder: review whether the launch date should change",
    ),
  ]
  for field in fields; model = init_model() {
    continue operator_request_form_model_for_msg(model, field).unwrap()
  } nobreak {
    model
  }
}

///|
test "material watch readiness requires complete explicit plan while legacy stays default" {
  let legacy = init_model()
  assert_true(legacy.request_watch_mode == CadenceWatch)
  assert_true(operator_request_ready(legacy))
  let empty = update_operator_request_form(
    legacy,
    OperatorRequestWatchMode(LocalMaterialWatch),
  )
  assert_false(operator_request_ready(empty))
  let complete = material_watch_form_fixture()
  assert_true(operator_request_ready(complete))
  for
    field in [
      OperatorRequestTitle(" "),
      OperatorRequestPrompt("\n"),
      OperatorRequestBookId(" "),
      OperatorRequestMaterialSources("\n"),
      OperatorRequestMaterialAcceptance(" "),
      OperatorRequestMaterialNextAction(" "),
    ] {
    assert_false(
      operator_request_ready(update_operator_request_form(complete, field)),
    )
  }
  assert_false(
    operator_request_ready(operator_request_submitting_model(complete)),
  )
}

///|
test "material watch source paths reject traversal absolute duplicates and empty lists" {
  for
    text in [
      "", "\n ", "/sources/a.txt", "../a.txt", "sources/../a.txt", "sources/./a.txt",
      "sources//a.txt", "sources\\a.txt", "sources/a.txt\nsources/a.txt",
    ] {
    assert_false(material_watch_source_paths_ready(text))
  }
  assert_true(
    material_watch_source_paths_ready(
      " sources/a.txt\r\n sources/客户.txt \n",
    ),
  )
  assert_eq(
    material_watch_source_paths(" sources/a.txt\r\n sources/客户.txt \n"),
    ["sources/a.txt", "sources/客户.txt"],
  )
}

///|
test "material watch draft survives mode toggles frozen edits repeated saves and failure" {
  let complete = material_watch_form_fixture()
  let cadence = update_operator_request_form(
    complete,
    OperatorRequestWatchMode(CadenceWatch),
  )
  let restored = update_operator_request_form(
    cadence,
    OperatorRequestWatchMode(LocalMaterialWatch),
  )
  assert_eq(
    restored.request_material_sources,
    complete.request_material_sources,
  )
  assert_eq(
    restored.request_material_acceptance,
    complete.request_material_acceptance,
  )
  assert_eq(
    restored.request_material_next_action,
    complete.request_material_next_action,
  )
  assert_eq(restored.request_prompt, complete.request_prompt)
  let dispatch : Dispatch[Msg] = Emit(_ => @rabbita.none)
  let commands = Ref(0)
  let submit = fn(_dispatch, _pending) {
    commands.val += 1
    @rabbita.none
  }
  let (_, pending) = submit_operator_request_update(dispatch, restored, submit~)
  let (_, duplicate) = submit_operator_request_update(
    dispatch,
    pending,
    submit~,
  )
  assert_eq(commands.val, 1)
  assert_true(duplicate.request_submitting)
  for
    field in [
      OperatorRequestWatchMode(CadenceWatch),
      OperatorRequestMaterialSources("other.txt"),
      OperatorRequestMaterialAcceptance("Other"),
      OperatorRequestMaterialNextAction("Other"),
    ] {
    let frozen = update_operator_request_form(pending, field)
    assert_true(frozen.request_watch_mode == LocalMaterialWatch)
    assert_eq(
      frozen.request_material_sources,
      complete.request_material_sources,
    )
    assert_eq(
      frozen.request_material_acceptance,
      complete.request_material_acceptance,
    )
    assert_eq(
      frozen.request_material_next_action,
      complete.request_material_next_action,
    )
  }
  let (_, failed) = operator_request_result_update(
    pending.request_submission_id,
    "{\"ok\":false,\"error\":\"source unavailable\"}",
    pending,
  )
  assert_false(failed.request_submitting)
  assert_true(failed.request_watch_mode == LocalMaterialWatch)
  assert_eq(failed.request_material_sources, complete.request_material_sources)
  assert_eq(
    failed.request_material_acceptance,
    complete.request_material_acceptance,
  )
  assert_eq(
    failed.request_material_next_action,
    complete.request_material_next_action,
  )
  assert_true(operator_request_ready(failed))
}

///|
test "material watch form explains real source selection and pending fields are frozen" {
  let dispatch : Dispatch[Msg] = Emit(_ => @rabbita.none)
  let complete = material_watch_form_fixture()
  let rendered = @rabbita.render_to_string(
    @rabbita.static_cell(render_request_composer(dispatch, complete)),
  )
  assert_true(rendered.contains("Local material changes"))
  assert_true(
    rendered.contains("existing UTF-8 file paths relative to the target Book"),
  )
  assert_true(rendered.contains("one per line"))
  assert_true(rendered.contains("watch-material-sources"))
  assert_true(rendered.contains("watch-material-acceptance"))
  assert_true(rendered.contains("watch-material-next-action"))
  let pending = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_request_composer(
        dispatch,
        operator_request_submitting_model(complete),
      ),
    ),
  )
  assert_eq(pending.split(" disabled").to_array().length(), 10)
  assert_true(pending.contains("Mode is locked while saving"))
}
