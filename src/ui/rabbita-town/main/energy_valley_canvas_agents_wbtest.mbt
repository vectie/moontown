///|
test "Energy Valley canvas agents reuse the animated sprite roster" {
  assert_eq(
    golden_valley_agent_sprite_path("mayor", 0),
    "/tilemap/actors/mayor_walk_strip.png",
  )
  assert_eq(
    golden_valley_agent_sprite_path("keeper", 4),
    "/tilemap/actors/keeper_walk_strip.png",
  )
  assert_eq(
    golden_valley_agent_sprite_path("worker", 8),
    "/tilemap/actors/worker_walk_strip.png",
  )
  assert_eq(
    golden_valley_agent_sprite_path("researcher", 12),
    "/tilemap/actors/researcher_walk_strip.png",
  )
  assert_eq(
    golden_valley_agent_sprite_path("resident", 65),
    "/tilemap/actors/roster/resident_1_walk_strip.png",
  )
}
