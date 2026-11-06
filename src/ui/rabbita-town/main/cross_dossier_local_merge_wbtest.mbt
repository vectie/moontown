///|
fn local_cross_dossier_ui_fixture() -> @collaboration.Client raise {
  let first = retained_inquiry_ui_fixture().edit("inquiry_add_dossier", "add")
  let original = first.outcome.unwrap()
  let key = {
    ..original.key,
    draft_id: "second-question",
    revision: "r-second",
    result_digest: "sha256:second",
    review_digest: "sha256:second-review",
  }
  let second = {
    ..original,
    key,
    saved: {
      ..original.saved,
      revision: key.revision,
      draft: {
        ..original.saved.draft,
        draft_id: key.draft_id,
        question: "A second historical question",
        objection: "Conflicting periods",
      },
    },
    work: {
      ..original.work,
      draft_id: key.draft_id,
      revision: key.revision,
      result_digest: key.result_digest,
    },
  }
  { ..first.select_outcome(key), outcome: Some(second), }
  .edit("inquiry_include_forest", "yes")
  .edit("inquiry_quote_forest", "Exact contribution 水 café 🚲")
  .edit(
    "inquiry_challenge_forest", "Check this different district independently",
  )
  .edit("inquiry_add_dossier", "add")
}

///|
test "cross dossier inquiry save preserves local unsaved draft guard and advances only its matching reply" {
  let source = local_cross_dossier_ui_fixture()
  let state = { ..source, dirty: false, }.begin(
    "cross-dossier-inquiry", "research-next",
  )
  assert_true(state.busy())
  let retained : @collaboration.SavedDraft = @json.from_json(
    @json.parse(retained_inquiry_fixture_saved()),
  )
  let saved = {
    ..retained,
    draft: source.cross_dossier_inquiry_preview().unwrap(),
  }
  let reply : @collaboration.Reply = {
    contract_version: "moontown.collaboration.reply.v1",
    request_id: state.generation.to_string(),
    action: "cross-dossier-inquiry",
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
    "cross-dossier-inquiry",
    reply.to_json().stringify(),
  )
  assert_true(next.request_composer == CollaborationComposer)
  assert_eq(next.collaboration.draft, saved.draft)
  assert_false(next.collaboration.dirty)
  let (_, stale) = collaboration_settle_reply(
    model,
    state.generation - 1,
    "cross-dossier-inquiry",
    reply.to_json().stringify(),
  )
  assert_true(stale.request_composer == ResultsComposer)
  assert_eq(stale.collaboration.draft, state.draft)
  let (_, failed) = collaboration_settle_reply(
    model,
    state.generation,
    "cross-dossier-inquiry",
    { ..reply, ok: false, error: "Source changed", saved: None, }
    .to_json()
    .stringify(),
  )
  assert_true(failed.request_composer == ResultsComposer)
  assert_eq(failed.collaboration.draft, state.draft)
}

///|
test "cross dossier inquiry renderer preserves local Chinese title and provenance disclosure" {
  let state = local_cross_dossier_ui_fixture()
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let html = disclosure_test_html(
    render_collaboration_outcomes(dispatch, state),
  )
  assert_true(html.contains("继续研究"))
  assert_true(html.contains("所选成果的来源版本"))
  assert_true(html.contains("<details"))
  assert_true(html.contains("跨记录研究"))
  assert_true(html.contains("保存跨记录研究"))
  assert_false(html.contains("保存并编辑研究"))
  assert_false(html.contains("Ready to save"))
}
