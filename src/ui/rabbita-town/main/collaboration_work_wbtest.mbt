///|
test "oneoff rendered form exposes explicit run retained contributions independent named owners and Book return" {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let base = collaboration_test_state()
  let work = {
    ..@collaboration.empty_work(base.draft.draft_id, "r-fixture"),
    status: "completed",
    result_digest: "sha256:result",
    review_status: "accepted",
    operator_id: "alex",
    participants: [
      {
        book_id: "water",
        packet_id: "p",
        proposal_id: "proposal-p",
        run_id: "run-p",
        status: "completed",
        detail: "Production fixture contribution",
        output_ref: "report.md",
        output_digest: "sha256:output",
        output_text: "Exact retained contribution 水 <unsafe>",
      },
    ],
    decisions: [
      {
        decision_id: "review-result",
        reviewer_id: "alex",
        reviewer_name: "Alex Reviewer",
        prompt: "Accept the actual result?",
        decision: "approve",
        rationale: "Fixture only",
      },
      {
        decision_id: "resolve-objection",
        reviewer_id: "sam",
        reviewer_name: "Sam Reviewer",
        prompt: "Resolve objection",
        decision: "approve",
        rationale: "Preserve limits",
      },
    ],
    package_digest: "sha256:outcome",
    book_status: "deliverable_review_required",
  }
  let state = {
    ..base,
    dirty: false,
    revision: "r-fixture",
    previous_revision: "r-prior",
    work: Some(work),
  }
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_collaboration_work(dispatch, state)),
  )
  for
    expected in [
      "Exact retained contribution", "&lt;unsafe&gt;", "Alex Reviewer", "Sam Reviewer",
      "提交我的决定", "提交到知识册", "刷新知识册状态", "查看上一来源版本",
      "这是上次读取的状态", "collaboration-work_information_severity",
    ] {
    assert_true(html.contains(expected), msg=expected)
  }
  assert_false(html.contains("开始执行"))
  assert_false(html.contains("恢复原任务"))
  let payload = collaboration_work_payload(
    state.edit("work_book_id", "water").edit("work_rationale", "Exact review"),
  )
  assert_true(
    payload
    is {
      "result_digest": "sha256:result",
      "review_version": 0,
      "book_id": "water",
      "rationale": "Exact review",
      ..
    },
  )
  assert_false(payload.stringify().contains("operator_id"))
}

///|
test "oneoff unconfigured authority renders an ordinary blocker and cannot pretend a plan is an outcome" {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let state = collaboration_test_state()
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(render_collaboration_work(dispatch, state)),
  )
  assert_false(html.contains("开始执行"))
  assert_true(html.contains("保存草稿或准备任务不会启动执行"))
  assert_false(html.contains("提交到知识册"))
  let result = {
    ..@collaboration.empty_work(state.draft.draft_id, "r-fixture"),
    status: "partial",
    result_digest: "sha256:partial",
  }
  let pending = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_collaboration_work(dispatch, { ..state, work: Some(result), }),
    ),
  )
  assert_true(pending.contains("请以指定审阅人登录后审核"))
  assert_false(pending.contains("提交到知识册"))
}
