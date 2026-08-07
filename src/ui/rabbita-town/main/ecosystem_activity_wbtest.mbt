///|
test "resident activity follows consecutive semantic schedule places" {
  let model = init_model()
  let activities = ecosystem_resident_activities(model, 20260727)
  assert_eq(activities.length(), 12)
  for activity in activities {
    assert_false(activity.place_id.is_empty())
    assert_false(activity.source_place_id.is_empty())
    assert_true(activity.transition_tick > activity.started_tick)
    assert_true(activity.progress_per_mille >= 0)
    assert_true(activity.progress_per_mille <= 1000)
  }
}

///|
test "canvas sprites and place occupancy cannot count the same preview resident" {
  let seed = 20260727
  let mut witnessed_travel = false
  for tick in 0..<160 {
    let model = { ..init_model(), tick, }
    let snapshot = ecosystem_contract_town_snapshot(model, seed)
    let expected_sprites = snapshot
      .outdoor_presences()
      .filter(presence => {
        snapshot
        .find_actor_profile(presence.actor_id)
        .map(profile => {
          profile.source_kind is @energy_valley_contract.AmbientSimulation
        })
        .unwrap_or(false)
      })
      .length()
    let preview_sprites = town_snapshot_canvas_agents(
        snapshot,
        0.0,
        false,
        None,
      )
      .filter(agent => agent.preview)
      .length()
    assert_eq(preview_sprites, expected_sprites)
    if expected_sprites > 0 {
      witnessed_travel = true
      break
    }
  }
  assert_true(witnessed_travel)
}

///|
test "ambient residents remain truth-labelled beside live runtime agents" {
  let model = runtime_map_routing_live_model()
  let seed = 20260727
  let snapshot = ecosystem_contract_town_snapshot(model, seed)
  let agents = town_snapshot_canvas_agents(snapshot, 0.0, false, None)
  assert_true(agents.any(agent => !agent.preview))
  assert_eq(
    agents.filter(agent => agent.preview).length(),
    snapshot
    .outdoor_presences()
    .filter(presence => {
      snapshot
      .find_actor_profile(presence.actor_id)
      .map(profile => {
        profile.source_kind is @energy_valley_contract.AmbientSimulation
      })
      .unwrap_or(false)
    })
    .length(),
  )
}
