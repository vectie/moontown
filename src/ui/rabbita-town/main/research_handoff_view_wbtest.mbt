///|
fn research_handoff_test_request() -> ResearchHandoffRequest {
  {
    handoff_url: "http://127.0.0.1:4313/api/v1/moontown/handoff",
    handoff_contract: "moontown.civic.communication.handoff.v1",
    handoff_id: "moonfind-run-42-research-salon",
  }
}

///|
fn research_handoff_test_reply(handoff_id : String) -> String {
  (
    $|{"contract_version":"moontown.research-handoff-inspection.reply.v1","ok":true,"requested_url":"http://127.0.0.1:4313/api/v1/moontown/handoff","upstream_status":200,"handoff":{"contract_version":"moontown.civic.communication.handoff.v1","handoff_id":"\{handoff_id}","producer":"moonfind","producer_run_id":"run-42","scenario":{"id":"moonfind-run-42","title":"Humanoid Cross-Paper Research Salon","communication_pattern_id":"research-salon","building_book_id":"moonfind-synthesis-book","topic":"Humanoid robotics","skill_description":"Challenge claims across participant books and preserve contradictions.","protocol_channel":"moonfind.research.cross-paper.v1","reduction_kind":"evidence-backed-idea-synthesis","output_channel":"moonfind.research.ideas.v1","review_gate":"named-human","review_owner":"moonbook.bookkeeper","review_reason":"Novel claims require evidence and named-human technical review.","quality_rules":["Every bridge must cite at least two participant books.","Every proposed experiment needs a falsifier."],"participants":[{"book_id":"paper-a","title":"Paper A","focus_area":"control","current_question":"Which assumption fails first?","contribution":"A control-policy result.","next_artifact":"a.md"},{"book_id":"paper-b","title":"Paper B","focus_area":"hardware","current_question":"Can the hardware reproduce it?","contribution":"A hardware constraint.","next_artifact":"b.md"}]}},"error":""}
  )
}

///|
fn render_research_handoff_test_html(state : ResearchHandoffState) -> String {
  let dispatch : Dispatch[Msg] = fn(_message) { @rabbita.none }
  @rabbita.render_to_string(
    @rabbita.static_cell(
      render_research_handoff_panel(dispatch, {
        ..init_model(),
        research_handoff: state,
      }),
    ),
  )
}

///|
test "typed research handoff fixture is visibly pending with all boundaries" {
  let request = research_handoff_test_request()
  let state = resolve_research_handoff_response(
    request,
    research_handoff_test_reply(request.handoff_id),
  )
  assert_true(state is ReadyResearchHandoff(_, _))
  let html = render_research_handoff_test_html(state)
  assert_true(html.contains("PENDING · NOT EXECUTED"))
  assert_true(html.contains("run-42"))
  assert_true(html.contains("Participant boundary"))
  assert_true(html.contains("Paper A"))
  assert_true(html.contains("Paper B"))
  assert_true(html.contains("Challenge boundary"))
  assert_true(html.contains("Review boundary"))
  assert_true(html.contains("moonbook.bookkeeper"))
  assert_true(html.contains("Start governed salon"))
  assert_true(html.contains("immutable Flow attempt"))
  assert_true(!html.contains("Synthesis completed"))
  assert_true(!html.contains("Execution completed"))
}

///|
test "artifact identity mismatch renders a visible fail-closed state" {
  let state = resolve_research_handoff_response(
    research_handoff_test_request(),
    research_handoff_test_reply("different-handoff"),
  )
  assert_true(state is BlockedResearchHandoff(_))
  let html = render_research_handoff_test_html(state)
  assert_true(html.contains("Research handoff blocked"))
  assert_true(html.contains("artifact id does not match"))
  assert_true(html.contains("no research-salon execution has started"))
}

///|
test "retained result exposes reconciliation without claiming review acceptance" {
  let request = research_handoff_test_request()
  let state = resolve_research_handoff_response(
    request,
    research_handoff_test_reply(request.handoff_id),
  )
  guard state is ReadyResearchHandoff(_, handoff) else {
    fail("expected a ready handoff")
  }
  let reply : ResearchHandoffExecutionReply = {
    contract_version: "moontown.research-handoff-execution.reply.v1",
    ok: false,
    action: "start",
    requested_url: request.handoff_url,
    handoff_id: request.handoff_id,
    execution_status: "completed",
    review_status: "pending",
    callback_status: "pending-reconcile",
    callback_http_status: 0,
    package: None,
    error: "MoonFind is temporarily unavailable.",
  }
  let html = render_research_handoff_test_html(
    SettledResearchHandoff(request, handoff, reply),
  )
  assert_true(html.contains("RESULT RETAINED"))
  assert_true(html.contains("Reconcile same attempt"))
  assert_true(html.contains("pending"))
  assert_true(!html.contains("accepted synthesis"))
}
