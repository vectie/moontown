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
  assert_true(
    packet.decision is Assigned(plan) &&
    plan.worker_id == "claw-review" &&
    packet.output_contract == "mayor.dispatch.packet.v1",
  )
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
