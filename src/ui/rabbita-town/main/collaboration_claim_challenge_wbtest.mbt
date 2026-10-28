///|
fn claim_challenge_ui_fixture() -> @collaboration.Client raise {
  let input : @collaboration.ClaimChallenge = @json.from_json(
    @json.parse(source_claim_fixture_input()),
  )
  let base : @collaboration.Client = {
    ..collaboration_test_state(),
    books: [
      { book_id: "water", title: "Water", },
      { book_id: "mobility", title: "Mobility", },
    ],
  }
  let mut state = base
    .edit("claim_mode", "compose")
    .edit("claim_report", source_claim_fixture_report())
    .edit("claim_group", "0")
  for
    (key, value) in [
      ("id", input.draft_id),
      ("title", input.title),
      ("question", input.question),
      ("falsifier", input.falsifier),
      ("reviewer_id", input.reviewer_id),
      ("reviewer_name", input.reviewer_name),
      ("objection", input.objection),
      ("objection_reviewer_id", input.objection_reviewer_id),
      ("objection_reviewer_name", input.objection_reviewer_name),
    ] {
    state = state.edit("claim_" + key, value)
  }
  for i, mapping in input.mappings {
    state = state
      .edit("claim_book_" + i.to_string(), mapping.book_id)
      .edit("claim_path_" + i.to_string(), mapping.source_path)
      .edit("claim_challenge_" + i.to_string(), mapping.challenge)
  }
  state
}

///|
test "claim challenge actual report renders selected group quotes values digests and explicit mappings" {
  let state = claim_challenge_ui_fixture()
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_collaboration_composer(dispatch, state)),
  )
  for
    expected in [
      "Selected: wait", "week A", "Wait: 12", "Wait: 18", "Imported Water", "export/water.txt",
      "Exact labelled value: 18", "sha256:", "Mapped Book: water", "raw/nested/source.bin",
      "保存并编辑研究", "取消继续研究", "准备任务",
    ] {
    assert_true(html.contains(expected), msg=expected)
  }
  let input : @collaboration.ClaimChallenge = @json.from_json(
    @json.parse(source_claim_fixture_input()),
  )
  assert_eq(state.claim_challenge_input(), Ok(input))
  let started = state.begin("claim-challenge", input.draft_id)
  let request = @json.parse(
    collaboration_payload(started, "claim-challenge", input.draft_id, "", ""),
  )
  guard request
    is { "payload": payload, "draft": Null, "action": "claim-challenge", .. } else {
    fail("Expected typed claim save request")
  }
  assert_eq(payload, input.to_json())
  let injected = state
    .edit(
      "claim_report",
      source_claim_fixture_report().replace_all(
        old="Imported Water",
        new="<script>not authority</script>",
      ),
    )
    .edit("claim_group", "0")
  let escaped = @rabbita.render_to_string(
    @rabbita.static_cell(render_claim_challenge(dispatch, injected)),
  )
  assert_true(escaped.contains("&lt;script&gt;"))
  assert_false(escaped.contains("<script>"))
}

///|
test "claim selection repeated clicks group changes cancellation and stale callbacks preserve ordinary draft" {
  let state = claim_challenge_ui_fixture()
  assert_eq(state.edit("claim_group", "0").claim_fields, state.claim_fields)
  let changed = state.edit("claim_group", "1")
  assert_eq(changed.claim_fields.get("claim_book_0"), None)
  assert_eq(changed.claim_fields.get("claim_question"), None)
  assert_eq(changed.draft, state.draft)
  let started = state.begin("claim-challenge", "source-challenge")
  assert_eq(
    started.begin("claim-challenge", "source-challenge").generation,
    started.generation,
  )
  let saved : @collaboration.SavedDraft = @json.from_json(
    @json.parse(source_claim_fixture_saved()),
  )
  let reply : @collaboration.Reply = {
    contract_version: "moontown.collaboration.reply.v1",
    request_id: started.generation.to_string(),
    action: "claim-challenge",
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
  let cancelled = started.edit("claim_mode", "off")
  assert_false(cancelled.busy())
  assert_true(cancelled.claim_fields.is_empty())
  assert_eq(
    cancelled.settle(started.generation, "claim-challenge", raw).draft,
    state.draft,
  )
  assert_eq(
    started.dismiss().settle(started.generation, "claim-challenge", raw).draft,
    state.draft,
  )
  let settled = started.settle(started.generation, "claim-challenge", raw)
  assert_eq(settled.draft, saved.draft)
  assert_false(settled.dirty)
  assert_true(settled.claim_fields.is_empty())
  assert_true(settled.work is None)
  assert_true(settled.prepared is None)
  assert_true(settled.begin("prepare", saved.draft.draft_id).busy())
  let invalid = started.settle(
    started.generation,
    "claim-challenge",
    {
      ..reply,
      saved: Some({
        ..saved,
        draft: { ..saved.draft, question: "Unexpected changed question", },
      }),
    }
    .to_json()
    .stringify(),
  )
  assert_eq(invalid.draft, state.draft)
  assert_true(invalid.notice.contains("identity"))
}
