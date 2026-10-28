///|
test "work routes resolve to actionable panels without a second workflow" {
  assert_true(request_composer_for_route("watch") == StandingWatchComposer)
  assert_true(request_composer_for_route("book") == EvidenceBookComposer)
  assert_true(
    request_composer_for_route("collaboration") == CollaborationComposer,
  )
  assert_true(request_composer_for_route("outcomes") == ResultsComposer)
  assert_true(request_composer_for_route("review") == AttentionComposer)
  assert_true(request_composer_for_route("unknown") == RequestShortcuts)
  let dispatch : Dispatch[Msg] = Emit(_ => @rabbita.none)
  let (_, next) = open_work_workspace(dispatch, init_model(), ResultsComposer)
  assert_true(next.energy_request_open)
  assert_false(next.energy_intro_open)
  assert_true(next.request_composer == ResultsComposer)
  assert_true(next.collaboration.busy())
}

///|
test "results and pending work are primary navigation with scoped details" {
  let dispatch : Dispatch[Msg] = Emit(_ => @rabbita.none)
  let model = { ..init_model(), request_composer: ResultsComposer, }
  let html = disclosure_test_html(
    render_energy_valley_request_dialog(dispatch, model),
  )
  assert_true(html.contains("aria-label=\"工作与成果\""))
  assert_true(html.contains(">成果<"))
  assert_true(html.contains(">待我处理<"))
  assert_true(html.contains("collaboration-results"))
  let visitor = disclosure_test_html(
    render_account_navigation(visitor_account_experience()),
  )
  assert_true(visitor.contains("request=watch"))
  assert_true(visitor.contains("request=outcomes"))
  assert_true(visitor.contains("layer=compute"))
  assert_false(visitor.contains("panel=agent"))
  assert_true(visitor.contains("https://suanli.kechuangfuwu.com:8443/user/"))
}

///|
test "town navigation preserves an edited draft in place" {
  let dispatch : Dispatch[Msg] = Emit(_ => @rabbita.none)
  let state = @collaboration.Client::new().edit(
    "title", "尚未保存的研究",
  )
  let model = {
    ..init_model(),
    collaboration: state,
    request_composer: CollaborationComposer,
  }
  for
    event in [
      OpenWorkWorkspace(ResultsComposer),
      OpenSecretComputeRoom,
      OpenTownWorkspace,
    ] {
    let (_, next) = update(dispatch, event, model)
    assert_eq(next.collaboration.draft.title, "尚未保存的研究")
    assert_true(next.collaboration.dirty)
  }
  let html = disclosure_test_html(
    render_account_navigation(visitor_account_experience(), dispatch~),
  )
  assert_true(html.contains("<button"))
  assert_false(html.contains("href=\"./index.html?request=outcomes"))
  assert_true(html.contains("target=\"_blank\""))
}
