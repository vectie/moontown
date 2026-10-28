///|
test "civic town does not manufacture business metrics from animation" {
  let model = { ..init_model(), tick: 20, }
  assert_eq(resident_count(model), resident_sims(model).length())
  assert_eq(valley_points_redeemed(model), 0)
  assert_eq(valley_points_issued(model), 0)
  assert_eq(robot_service_count(model), 0)
  assert_eq(events_today(model), 0)
  assert_eq(achievement_broadcast_count(model), 0)
  assert_eq(service_response_minutes(model), 0)
  assert_eq(agent_action_count(model), 0)
  assert_eq(retention_signal(model), 0)
}
