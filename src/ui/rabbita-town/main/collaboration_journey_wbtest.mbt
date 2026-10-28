///|
test "research replacement actions preserve an unsaved ordinary draft and inline followup notes" {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let state = collaboration_test_state().edit(
    "work_collective_hypothesis", "Keep this hypothesis",
  )
  let model = {
    ..init_model(),
    collaboration: state,
    request_composer: ResultsComposer,
  }
  for
    action in [
      "load", "reuse", "retained-inquiry", "claim-challenge", "oneoff-followup",
    ] {
    let (_, next) = collaboration_action(
      dispatch, model, action, "other", "r-other",
    )
    assert_eq(next.collaboration.draft, state.draft)
    assert_eq(next.collaboration.work_fields, state.work_fields)
    assert_eq(next.collaboration.generation, state.generation)
    assert_false(next.collaboration.busy())
    assert_true(next.collaboration.notice.contains("请先保存"))
  }
  let saved = { ..state, dirty: false, revision: "r-saved", }
  assert_false(collaboration_has_unsaved_draft(saved))
  assert_false(collaboration_has_unsaved_draft(@collaboration.Client::new()))
}

///|
test "opening review loads only a saved revision and never collects or executes implicitly" {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let (_, next) = collaboration_review_open(
    dispatch,
    init_model(),
    "historical",
    "r-selected",
  )
  assert_true(next.request_composer == AttentionComposer)
  assert_true(next.energy_request_open)
  assert_eq(next.collaboration.pending_action, "load")
  assert_eq(next.collaboration.pending_id, "historical")
  assert_true(next.collaboration.work is None)
  let edited = { ..init_model(), collaboration: collaboration_test_state(), }
  let (_, blocked) = collaboration_review_open(
    dispatch, edited, "historical", "r-selected",
  )
  assert_eq(blocked.collaboration.draft, edited.collaboration.draft)
  assert_false(blocked.collaboration.busy())
}

///|
test "review counts require exact signed in decision owner rather than historical names" {
  let work = {
    ..@collaboration.empty_work("research", "r-source"),
    decisions: [
      {
        decision_id: "review",
        reviewer_id: "owner-a",
        reviewer_name: "Same Name",
        prompt: "Review",
        decision: "pending",
        rationale: "",
      },
      {
        decision_id: "objection",
        reviewer_id: "owner-b",
        reviewer_name: "Same Name",
        prompt: "Objection",
        decision: "defer",
        rationale: "Need evidence",
      },
    ],
  }
  assert_eq(collaboration_my_pending_reviews(work), 0)
  assert_eq(
    collaboration_my_pending_reviews({ ..work, operator_id: "owner-a", }),
    1,
  )
  assert_eq(
    collaboration_my_pending_reviews({ ..work, operator_id: "owner-b", }),
    1,
  )
  assert_eq(
    collaboration_my_pending_reviews({ ..work, operator_id: "Same Name", }),
    0,
  )
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let html = disclosure_test_html(
    render_collaboration_attention(dispatch, @collaboration.Client::new()),
  )
  assert_true(html.contains("工作区待处理"))
  assert_false(html.contains("待我审核 · 0"))
  assert_true(html.contains("不代表你的个人待办数量"))
}

///|
test "running tasks collect explicitly and keep recovery evidence in advanced" {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let base = collaboration_test_state()
  let work = {
    ..@collaboration.empty_work(base.draft.draft_id, "r-source"),
    status: "running",
    detail: "Original execution is unresolved",
  }
  let state = { ..base, dirty: false, revision: "r-source", work: Some(work), }
  let html = disclosure_test_html(render_collaboration_work(dispatch, state))
  let sections = html.split("<details").to_array()
  assert_true(sections[0].contains("刷新进度"))
  assert_false(sections[0].contains("开始执行"))
  assert_false(sections[0].contains("恢复原任务"))
  assert_true(html.contains("恢复原任务 · 不创建新执行"))
  assert_true(html.contains("Original execution is unresolved"))
  assert_false(html.contains("提交到知识册"))
  let terminal = disclosure_test_html(
    render_collaboration_work(dispatch, {
      ..state,
      work: Some({ ..work, status: "partial", result_digest: "sha256:result", }),
    }),
  )
  assert_false(terminal.contains("开始执行"))
  assert_false(terminal.contains("恢复原任务"))
  assert_true(terminal.contains("审核结果"))
  assert_false(terminal.contains("提交到知识册"))
}

///|
test "verified followup save returns to one editor while stale replies keep their surface" {
  let source = retained_inquiry_ui_fixture()
  let state = { ..source, dirty: false, }.begin(
    "retained-inquiry", "research-next",
  )
  let saved : @collaboration.SavedDraft = @json.from_json(
    @json.parse(retained_inquiry_fixture_saved()),
  )
  let reply : @collaboration.Reply = {
    contract_version: "moontown.collaboration.reply.v1",
    request_id: state.generation.to_string(),
    action: "retained-inquiry",
    ok: true,
    error: "",
    books: [],
    drafts: [],
    saved: Some(saved),
    prepared: None,
    work: None,
    outcomes: [],
    outcome: None,
    source_listing: None,
  }
  let model = {
    ..init_model(),
    collaboration: state,
    request_composer: ResultsComposer,
  }
  let (_, next) = collaboration_settle_reply(
    model,
    state.generation,
    "retained-inquiry",
    reply.to_json().stringify(),
  )
  assert_true(next.request_composer == CollaborationComposer)
  assert_eq(next.collaboration.draft, saved.draft)
  assert_false(next.collaboration.dirty)
  assert_true(next.collaboration.work is None)
  assert_true(next.collaboration.prepared is None)
  let (_, stale) = collaboration_settle_reply(
    model,
    state.generation - 1,
    "retained-inquiry",
    reply.to_json().stringify(),
  )
  assert_true(stale.request_composer == ResultsComposer)
  assert_eq(stale.collaboration.draft, state.draft)
  let (_, failed) = collaboration_settle_reply(
    model,
    state.generation,
    "retained-inquiry",
    { ..reply, ok: false, error: "Source changed", saved: None, }
    .to_json()
    .stringify(),
  )
  assert_true(failed.request_composer == ResultsComposer)
  assert_eq(failed.collaboration.draft, state.draft)
}

///|
test "endpoint failures give a short actionable notice with HTTP details in advanced" {
  let state = @collaboration.Client::new().begin("outcome-list", "")
  let reply : @collaboration.Reply = {
    contract_version: "moontown.collaboration.reply.v1",
    request_id: state.generation.to_string(),
    action: "outcome-list",
    ok: false,
    error: "HTTP 404: collaboration endpoint did not return a valid reply. Check the workspace connection and retry.",
    books: [],
    drafts: [],
    saved: None,
    prepared: None,
    work: None,
    outcomes: [],
    outcome: None,
    source_listing: None,
  }
  let raw = reply.to_json().stringify()
  let settled = state.settle(state.generation, "outcome-list", raw)
  assert_false(settled.busy())
  let html = disclosure_test_html(render_collaboration_notice(settled))
  let primary = html.split("<details").to_array()[0]
  assert_true(primary.contains("请确认已登录工作区"))
  assert_false(primary.contains("HTTP"))
}

///|
test "required Book assessment opens until genuine values are supplied" {
  let mut state = @collaboration.Client::new()
  assert_true(collaboration_book_assessment_needs_attention(state))
  for name in ["information", "recognition", "decisiveness"] {
    state = state
      .edit("work_" + name + "_severity", "0")
      .edit(
        "work_" + name + "_summary",
        "已核对现有证据，无此缺口。",
      )
  }
  assert_false(collaboration_book_assessment_needs_attention(state))
  state = state.edit("work_information_severity", "2")
  assert_true(collaboration_book_assessment_needs_attention(state))
  state = state
    .edit("work_capability_id", "research.next")
    .edit("work_capability_version", "1")
    .edit("work_capability_summary", "补充缺失资料的研究建议")
  assert_false(collaboration_book_assessment_needs_attention(state))
  assert_true(
    collaboration_book_assessment_needs_attention(
      state.edit("work_information_severity", "6"),
    ),
  )
}

///|
test "routine refresh stays quiet and empty results have no idle filters" {
  let state = {
    ..@collaboration.Client::new(),
    notice: "Retained revisions loaded",
  }
  let notice = disclosure_test_html(render_collaboration_notice(state))
  assert_true(notice.contains("成果列表已更新"))
  assert_false(notice.contains("<details"))
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let html = disclosure_test_html(
    render_collaboration_outcomes(dispatch, state),
  )
  assert_false(html.contains("筛选成果"))
  assert_true(html.contains("导入成果"))
  assert_true(html.contains("aria-label=\"刷新成果\""))
}

///|
test "disconnected research offers a next step without an unusable composer" {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let state = {
    ..@collaboration.Client::new(),
    notice: "Directory is missing or contains a symlink",
  }
  let html = disclosure_test_html(
    render_collaboration_composer(dispatch, state),
  )
  assert_true(html.contains("重试连接"))
  assert_true(html.contains("创建资料研究"))
  assert_false(html.contains("id=\"collaboration-title\""))
  assert_false(html.split("<details").to_array()[0].contains("symlink"))
  let edited = state.edit("title", "保留未保存的研究")
  assert_true(
    disclosure_test_html(render_collaboration_composer(dispatch, edited)).contains(
      "保留未保存的研究",
    ),
  )
}
