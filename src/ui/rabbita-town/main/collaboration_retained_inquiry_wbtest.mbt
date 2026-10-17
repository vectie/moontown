///|
fn retained_inquiry_ui_fixture() -> @collaboration.Client raise {
  let input : @collaboration.RetainedInquiry = @json.from_json(
    @json.parse(retained_inquiry_fixture_input()),
  )
  let outcome : @collaboration.RetainedOutcome = @json.from_json(
    @json.parse(retained_inquiry_fixture_origin()),
  )
  let base = {
    ..collaboration_test_state(),
    outcome: Some(outcome),
    outcome_key: Some(outcome.key),
  }
  let mut state = base.edit("inquiry_mode", "compose")
  for
    (key, value) in [
      ("id", input.draft_id),
      ("title", input.title),
      ("question", input.question),
      ("falsifier", input.falsifier),
      ("dissent", input.dissent),
      ("assumptions", input.assumptions),
      ("reviewer_id", input.reviewer_id),
      ("reviewer_name", input.reviewer_name),
      ("objection_reviewer_id", input.objection_reviewer_id),
      ("objection_reviewer_name", input.objection_reviewer_name),
    ] {
    state = state.edit("inquiry_" + key, value)
  }
  for c in input.contributions {
    state = state
      .edit("inquiry_include_" + c.book_id, "yes")
      .edit("inquiry_quote_" + c.book_id, c.quote)
      .edit("inquiry_challenge_" + c.book_id, c.challenge)
  }
  state
}

///|
test "retained inquiry native fixture renders historical evidence editable fields selection gaps and exact save payload" {
  let state = retained_inquiry_ui_fixture()
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_collaboration_composer(dispatch, state)),
  )
  for
    expected in [
      "New inquiry from this historical dossier", "New scoped research question",
      "Selected: water", "Selected: forest", "Select: energy", "mobility", "Attributed fixture failure",
      "Exact retained excerpt from water", "Independent challenge for forest", "New inquiry human reviewer",
      "Objection decision owner", "Save new inquiry and open in composer", "Prepare one-off handoff",
      "Cancel new inquiry", "sha256:", "&lt;script&gt;",
    ] {
    assert_true(html.contains(expected), msg=expected)
  }
  assert_false(html.contains("Select: mobility"))
  assert_false(html.contains("<script>"))
  let input : @collaboration.RetainedInquiry = @json.from_json(
    @json.parse(retained_inquiry_fixture_input()),
  )
  let saved : @collaboration.SavedDraft = @json.from_json(
    @json.parse(retained_inquiry_fixture_saved()),
  )
  assert_eq(state.retained_inquiry_input(), Ok(input))
  assert_eq(state.retained_inquiry_preview(), Ok(saved.draft))
  let started = state.begin("retained-inquiry", input.draft_id)
  let request = @json.parse(
    collaboration_payload(started, "retained-inquiry", input.draft_id, "", ""),
  )
  guard request
    is {
      "action": "retained-inquiry",
      "draft_id": String(id),
      "revision": "",
      "draft": Null,
      "payload": payload,
      ..
    } else {
    fail("Expected ordinary API inquiry request")
  }
  assert_eq(id, input.draft_id)
  assert_eq(payload, input.to_json())
  let removed = state.edit("inquiry_include_water", "no")
  assert_true(removed.retained_inquiry_preview() is Err(_))
  assert_eq(
    removed.edit("inquiry_include_water", "yes").retained_inquiry_input(),
    Ok(input),
  )
  assert_eq(
    state.edit("inquiry_mode", "compose").inquiry_fields,
    state.inquiry_fields,
  )
}

///|
test "retained inquiry native saved reply opens ordinary editing and Prepare while interrupted callbacks cannot replace draft" {
  let state = retained_inquiry_ui_fixture()
  let started = state.begin("retained-inquiry", "research-next")
  let saved : @collaboration.SavedDraft = @json.from_json(
    @json.parse(retained_inquiry_fixture_saved()),
  )
  let reply : @collaboration.Reply = {
    contract_version: "moontown.collaboration.reply.v1",
    request_id: started.generation.to_string(),
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
  let raw = reply.to_json().stringify()
  for
    interrupted in [
      started.dismiss(),
      started.edit("inquiry_mode", "off"),
      started.reset(),
      started.edit("review_filter", "accepted"),
      started.select_outcome({
        ..state.outcome_key.unwrap(),
        review_version: 1,
      }),
    ] {
    assert_eq(
      interrupted.settle(started.generation, "retained-inquiry", raw).draft,
      interrupted.draft,
    )
  }
  let settled = started.settle(started.generation, "retained-inquiry", raw)
  assert_eq(settled.draft, saved.draft)
  assert_eq(settled.sources, saved.sources)
  assert_true(settled.work is None)
  assert_true(settled.prepared is None)
  assert_false(settled.dirty)
  assert_true(settled.begin("prepare", saved.draft.draft_id).busy())
  let edited = settled.edit_participant(
    "water", "perspective", "A revised independent challenge",
  )
  assert_true(edited.dirty)
  assert_eq(
    edited.draft.participants[0].perspective,
    "A revised independent challenge",
  )
  assert_false(edited.begin("prepare", saved.draft.draft_id).busy())
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let closed = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_collaboration_outcomes(dispatch, state.edit("inquiry_mode", "off")),
    ),
  )
  assert_true(
    closed.contains(
      "Use retained contributions in a new research-salon inquiry",
    ),
  )
  assert_false(closed.contains("New scoped research question"))
}
