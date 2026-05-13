///|
test "scheduler plans due standing goals" {
  let goal = @core.StandingGoal::new(
    id="watch-opc-news",
    title="Track OPC news",
    prompt="Research OPC.",
    target_book_id=Some("research-opc"),
    cadence_ticks=6,
    next_due_tick=1,
  )
  let actions = plan_standing_goal_actions([goal], 1)
  assert_eq(actions.length(), 1)
  assert_eq(actions[0].kind, "standing-goal-due")
  assert_true(actions[0].detail.contains("research-opc"))
}

///|
test "daemon tick records active due goal ids" {
  let town = @core.empty_state(
    @core.TownConfig::new(id="town", name="Moontown"),
  )
  let report = @health.inspect_town(town)
  let goal = @core.StandingGoal::new(
    id="watch-opc-news",
    title="Track OPC news",
    prompt="Research OPC.",
    target_book_id=Some("research-opc"),
    next_due_tick=1,
  )
  let (daemon, tick, actions) = plan_daemon_tick(
    DaemonState::new(),
    town,
    report,
    standing_goals=[goal],
  )
  assert_eq(tick.sequence, 1)
  assert_eq(daemon.active_goal_ids, ["watch-opc-news"])
  assert_true(actions.any(fn(action) { action.kind == "standing-goal-due" }))
}
