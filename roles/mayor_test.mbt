///|
test "mayor runtime is strategic planner only with constrained tools" {
  let mayor = Mayor::new()
  let runtime = mayor.runtime()
  assert_eq(runtime.role_id, "mayor")
  assert_eq(runtime.planning_layer.to_string(), "Strategic")
  assert_eq(runtime.runtime_mode.to_string(), "PlannerOnly")
  assert_eq(runtime.tool_access.to_string(), "Limited")
  assert_eq(runtime.memory_scope.to_string(), "Global")
  assert_true(!runtime.allow_execution_tools)
  assert_true(!runtime.allow_workspace_write)
}

///|
test "mayor dispatch delegates to town routing logic" {
  let mayor = Mayor::new()
  let state = @moontown.demo_state()
  let packet = mayor.decide_dispatch(state, state.tasks[0])
  ignore(packet.decision)
  assert_eq(packet.output_contract, "mayor.dispatch.packet.v1")
  assert_true(!packet.rationale.is_blank())
}

///|
test "mayor handoff targets keeper role" {
  let mayor = Mayor::new()
  let state = @moontown.demo_state()
  let handoff = mayor.handoff_to_keeper(
    state.books[0],
    "hydrate coding context",
    "coding book planning and memory scope",
  )
  assert_eq(handoff.target_role_id, "keeper:coding")
  assert_eq(handoff.kind.to_string(), "StrategicToDomain")
}

///|
test "mayor plans parallel research lanes for multi-subject goal" {
  let mayor = Mayor::new()
  let plan = mayor.plan_goal(
    @moonbook.default_catalog(),
    "research moontown, moonbook, and moonclaw",
  )
  assert_true(plan.parallelizable)
  assert_eq(plan.lanes.length(), 3)
  assert_eq(plan.lanes[0].entry.id, "research-moontown")
  assert_eq(plan.lanes[1].entry.id, "research-moonbook")
  assert_eq(plan.lanes[2].entry.id, "research-moonclaw")
  assert_true(plan.lanes[0].objective.contains("Own only the"))
}

///|
test "mayor supervision marks stale executions for recovery" {
  let mayor = Mayor::new()
  let state = @moontown.demo_state()
  let current = state.executions[0]
  let execution = @core.TaskExecutionRecord::new(
    task_id=current.task_id,
    book_id=current.book_id,
    packet_id=current.packet_id,
    packet_path=current.packet_path,
    proposal_id=current.proposal_id,
    run_id=current.run_id,
    status=@core.TaskExecutionStatus::Running,
    summary=current.summary,
    output_contract=current.output_contract,
    context_pages=current.context_pages,
    skill_paths=current.skill_paths,
    last_command=current.last_command,
    assigned_worker_id=current.assigned_worker_id,
    attempt=1,
    heartbeat_tick=current.heartbeat_tick,
    stale_after_tick=1,
    next_retry_tick=current.next_retry_tick,
    requires_review=current.requires_review,
    notify_town=current.notify_town,
  )
  state.replace_execution(execution)
  let packet = mayor.supervise(state, 3)
  assert_eq(packet.output_contract, "mayor.supervision.packet.v1")
  assert_true(packet.directives.length() >= 1)
  assert_true(packet.directives[0].kind.contains("stale"))
}
