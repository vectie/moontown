///|
test "mayor keeper packet ids stay compact for long task ids" {
  let task_id = "goal-own-only-the-moonbook-research-lane-build-durable-source-entity-concept-and-synthesis-coverage-for-this-lane-cross-reference-other-lanes-only-through-durable-outputs-global-town-goal-research-moontown-moonbook-and-moonclaw-bootstrap_gather"
  let packet_id = compact_keeper_packet_id("research-moonbook", task_id)
  assert_true(packet_id.has_prefix("keeper-"))
  assert_true(packet_id.length() < 96)
  assert_true(!packet_id.contains(task_id))
}
