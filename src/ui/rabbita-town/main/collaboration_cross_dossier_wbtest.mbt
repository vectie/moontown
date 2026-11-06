///|
test "cross dossier UI retains added excerpts across inspection and sends the exact ordinary save request" {
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
  let state = { ..first.select_outcome(key), outcome: Some(second), }
    .edit("inquiry_include_forest", "yes")
    .edit("inquiry_quote_forest", "Exact contribution 水 café 🚲")
    .edit(
      "inquiry_challenge_forest", "Check this different district independently",
    )
    .edit("inquiry_add_dossier", "add")
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_collaboration_outcomes(dispatch, state)),
  )
  for
    expected in [
      "跨记录研究",
      original.key.draft_id,
      "second-question",
      "Check this different district independently",
      "移除此记录",
      "保存跨记录研究",
    ] {
    assert_true(html.contains(expected), msg=expected)
  }
  let input = state.cross_dossier_inquiry_input().unwrap()
  assert_eq(input.additional.length(), 1)
  let started = state.begin("cross-dossier-inquiry", input.inquiry.draft_id)
  assert_true(started.busy())
  let request = @json.parse(
    collaboration_payload(
      started,
      "cross-dossier-inquiry",
      input.inquiry.draft_id,
      "",
      "",
    ),
  )
  guard request
    is {
      "action": "cross-dossier-inquiry",
      "revision": "",
      "payload": payload,
      ..
    } else {
    fail("Expected cross-dossier save API request")
  }
  assert_eq(payload, input.to_json())
  let removed = state.edit(
    "inquiry_remove_dossier",
    original.key.to_json().stringify(),
  )
  assert_eq(removed.inquiry_dossiers.length(), 1)
  assert_true(removed.cross_dossier_inquiry_preview() is Err(_))
}
