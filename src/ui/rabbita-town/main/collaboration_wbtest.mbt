///|
fn collaboration_test_state() -> @collaboration.Client {
  let empty = @collaboration.Client::new()
  let state = {
    ..empty,
    books: [
      { book_id: "water", title: "Water Book", },
      { book_id: "mobility", title: "Mobility Book", },
    ],
  }
  state
  .toggle_book("water")
  .toggle_book("mobility")
  .edit("title", "River planning")
  .edit("question", "Which observations should we compare?")
  .edit("reviewer_id", "alex")
  .edit("reviewer_name", "Alex Reviewer")
  .edit("objection", "Compare the observation windows")
  .edit("objection_reviewer_id", "sam")
  .edit("objection_reviewer_name", "Sam Reviewer")
}

///|
test "collaboration composer renders authored question Books exact sources reviewers and local actions" {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let state = collaboration_test_state()
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_collaboration_composer(dispatch, state)),
  )
  for
    text in [
      "协作研究", "Which observations should we compare?", "Water Book", "Mobility Book",
      "Exact source paths in water", "Perspective for mobility", "Alex Reviewer",
      "Sam Reviewer", "保存草稿", "准备交接", "Reuse saved question as a fresh draft",
    ] {
    assert_true(html.contains(text), msg=text)
  }
  assert_false(html.contains("Synthesis completed"))
  assert_false(html.contains("Start governed salon"))
  assert_true(html.contains("collaboration-water-source_paths"))
  assert_true(html.contains("collaboration-mobility-source_paths"))
}

///|
test "collaboration prepare and export have no additional acknowledgment gate" {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let fixture = collaboration_test_state()
  let prepared : @collaboration.Prepared = {
    contract_version: "moontown.collaboration-prepared.v1",
    draft_id: fixture.draft.draft_id,
    revision: "r-example",
    review_status: "pending_review",
    artifacts: [
      {
        path: "revisions/r-example/handoff.json",
        digest: "sha256:fixture",
        size_bytes: 100,
      },
      {
        path: "revisions/r-example/briefs/water.md",
        digest: "sha256:fixture",
        size_bytes: 100,
      },
    ],
  }
  let state : @collaboration.Client = {
    ..fixture,
    dirty: false,
    revision: "r-example",
    prepared: Some(prepared),
  }
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_collaboration_composer(dispatch, state)),
  )
  assert_true(html.contains("Download prepared plan package (.tar)"))
  assert_true(html.contains("Download handoff.json"))
  assert_true(html.contains("Download water.md"))
  assert_false(html.contains("I acknowledge"))
  assert_true(state.begin("export", state.draft.draft_id).busy())
}

///|
test "collaboration newer surface and close invalidate pending replies without clearing authored fields" {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let state = collaboration_test_state().begin("save", "collaboration")
  let model = {
    ..init_model(),
    request_composer: CollaborationComposer,
    energy_request_open: true,
    collaboration: state,
  }
  for
    event in [
      CloseEnergyRequest,
      SetRequestComposer(StandingWatchComposer),
      ToggleResidentExplorer,
    ] {
    let (_, next) = update(dispatch, event, model)
    assert_true(next.collaboration.generation > state.generation)
    assert_false(next.collaboration.busy())
    let (_, stale) = update(
      dispatch,
      CollaborationReply(state.generation, "save", "{}"),
      next,
    )
    assert_eq(stale.collaboration.draft, state.draft)
    assert_eq(stale.collaboration.revision, "")
  }
}

///|
test "collaboration request desk routing uses the real third composer" {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let model = { ..init_model(), request_composer: CollaborationComposer, }
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_request_desk_workspace(dispatch, model)),
  )
  assert_true(html.contains("协作研究"))
  let buttons = @rabbita.render_to_string(
    @rabbita.static_cell(render_request_shortcuts(dispatch, model)),
  )
  assert_true(buttons.contains("协作"))
}
