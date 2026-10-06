///|
test "approved book reviews keep synthesis acceptance pending instead of goal ready" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="acceptance", name="Acceptance"),
  )
  let plan = @roles.Mayor::new().plan_goal(
    @moonbook.default_catalog(),
    "research moontown, moonbook, and moonclaw",
  )
  assert_true(plan.lanes.length() > 0)
  for lane in plan.lanes {
    state.register_execution(
      @core.TaskExecutionRecord::new(
        task_id="acceptance-\{lane.entry.id}",
        book_id=lane.entry.id,
        packet_id="packet-\{lane.entry.id}",
        packet_path="packet.json",
        status=AwaitingAcceptance,
        summary="Book review approved; goal acceptance remains unevaluated",
        output_contract="wenyu.build.native-result.v1",
      ),
    )
    assert_eq(lane_research_status(state, lane.entry.id), "acceptance pending")
  }
  assert_false(town_synthesis_ready(state, plan))
  assert_eq(town_synthesis_execution_status(state, plan), AwaitingAcceptance)
  assert_eq(town_synthesis_task_status(state, plan), Blocked)
  let decision = town_synthesis_decision(state, plan)
  assert_true(decision.contains("acceptance remains unevaluated"))
  assert_false(decision.contains("goal as complete"))
  let report = render_town_status_and_trajectory(state, plan)
  assert_true(report.contains("acceptance pending"))
  assert_true(report.contains("interim rather than final"))
  assert_false(report.contains("strong enough for a town-level report"))
  assert_true(
    render_wenyu_executive_summary(state, plan).contains("acceptance pending"),
  )
}

///|
test "unaccepted result prevents completed result from making a lane ready" {
  let state = @core.empty_state(@core.TownConfig::new(id="mixed", name="Mixed"))
  let execution = @core.TaskExecutionRecord::new(
    task_id="accepted-task",
    book_id="book",
    packet_id="packet",
    packet_path="packet.json",
    status=Completed,
    summary="Previously complete",
    output_contract="test",
  )
  state.register_execution(execution)
  assert_eq(lane_research_status(state, "book"), "complete")
  state.register_execution(
    @core.TaskExecutionRecord::new(
      task_id="pending-task",
      book_id="book",
      packet_id="pending-packet",
      packet_path="pending-packet.json",
      status=AwaitingAcceptance,
      summary="Book review approved; goal acceptance remains unevaluated",
      output_contract="test",
    ),
  )
  assert_eq(lane_research_status(state, "book"), "acceptance pending")
}
