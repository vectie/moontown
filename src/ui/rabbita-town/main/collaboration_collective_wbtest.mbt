///|
test "collective UI exposes connected experiment fields and explicit new-round action with escaped evidence" {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let base = collaboration_test_state()
  let work = {
    ..@collaboration.empty_work(base.draft.draft_id, "r-fixture"),
    status: "completed",
    result_digest: "sha256:result",
    participants: ["water", "mobility"].map(id => {
      book_id: id,
      packet_id: "packet-" + id,
      proposal_id: "proposal-" + id,
      run_id: "run-" + id,
      status: "completed",
      detail: "fixture",
      output_ref: "report-" + id,
      output_digest: "sha256:" + id,
      output_text: "Exact " + id + " evidence <script>",
    }),
  }
  let state = { ..base, dirty: false, revision: "r-fixture", work: Some(work), }
  let entry = @rabbita.render_to_string(
    @rabbita.static_cell(render_collective_experiment(dispatch, state, work)),
  )
  assert_true(entry.contains("验证新假设"))
  let opened = state.edit("work_collective_mode", "compose")
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_collective_experiment(dispatch, opened, work)),
  )
  for
    expected in [
      "Combined hypothesis", "Connect water", "Connect mobility", "Exact supporting passage",
      "What observable result would disprove", "Contradictions and dissent", "新草稿标识",
      "保存并编辑研究", "取消继续研究", "&lt;script&gt;",
    ] {
    assert_true(html.contains(expected), msg=expected)
  }
  assert_false(html.contains("<script>"))
  let request = @json.parse(
    collaboration_payload(
      opened,
      "oneoff-followup",
      state.draft.draft_id,
      state.revision,
      "",
    ),
  )
  assert_true(
    request
    is {
      "action": "oneoff-followup",
      "draft": Null,
      "payload": { "collective_result_digest": "sha256:result", .. },
      ..
    },
  )
}
