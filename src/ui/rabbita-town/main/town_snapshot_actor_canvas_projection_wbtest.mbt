///|
fn snapshot_actor_test_player() -> PlayerAvatar {
  {
    name: "星河",
    persona: "researcher",
    color: 4,
    sprite_index: 3,
    title: "能源研究员",
  }
}

///|
test "route positions retain their authoritative road segment and endpoints" {
  let model = init_model()
  let world = ecosystem_contract_world_for_model(model, 20260727)
  let segment = world.road_network.segments.filter(segment => {
      segment.supports(@energy_valley_contract.Pedestrian)
    })[0]
  let origin = world.road_network.find_node(segment.from_node_id).unwrap()
  let destination = world.road_network.find_node(segment.to_node_id).unwrap()
  let midpoint = (
    (origin.position.x + destination.position.x) / 2.0,
    (origin.position.y + destination.position.y) / 2.0,
  )
  let route = ecosystem_contract_actor_route_position(
    world,
    [
      (origin.position.x, origin.position.y),
      (destination.position.x, destination.position.y),
    ],
    midpoint,
    500,
  )
  assert_eq(route.road_segment_id, Some(segment.id))
  assert_eq(route.origin_node_id, Some(origin.id))
  assert_eq(route.destination_node_id, Some(destination.id))
  assert_eq(
    route.position,
    @energy_valley_contract.world_point(midpoint.0, midpoint.1),
  )
}

///|
test "ambient residents project from TownSnapshot without the activity model" {
  let seed = 20260727
  let mut witnessed_route_segment = false
  let mut witnessed_inside_slot = false
  for tick in 0..<160 {
    let snapshot = ecosystem_contract_town_snapshot(
      { ..init_model(), tick, },
      seed,
    )
    let records = town_snapshot_canvas_actor_records(snapshot, 2.0, false, None)
    for record in records {
      let profile = snapshot.find_actor_profile(record.actor_id).unwrap()
      if profile.source_kind is @energy_valley_contract.AmbientSimulation {
        assert_true(record.agent.preview)
        assert_true(record.agent.activity_label.contains(profile.display_name))
        let presence = snapshot.actor_presences.filter(presence => {
            presence.actor_id == record.actor_id
          })[0]
        match presence.route_position {
          Some(route) if route.road_segment_id is Some(_) =>
            witnessed_route_segment = true
          _ => ()
        }
      }
    }
    for presence in snapshot.actor_presences {
      if presence.phase is @energy_valley_contract.Inside &&
        presence.interaction_slot_id is Some(slot_id) {
        let slot = snapshot.world.find_interaction_slot(slot_id).unwrap()
        assert_eq(presence.render_position(snapshot.world), Some(slot.position))
        witnessed_inside_slot = true
      }
    }
    if witnessed_route_segment && witnessed_inside_slot {
      break
    }
  }
  assert_true(witnessed_route_segment)
  assert_true(witnessed_inside_slot)
}

///|
test "runtime and local player appearance survive the snapshot boundary" {
  let seed = 20260727
  let runtime_model = runtime_map_routing_live_model()
  let runtime_snapshot = ecosystem_contract_town_snapshot(runtime_model, seed)
  let runtime_records = town_snapshot_canvas_actor_records(
    runtime_snapshot,
    3.0,
    false,
    town_snapshot_selected_actor_id(Agent("routing-agent")),
  )
  let live = runtime_records.filter(record => {
      runtime_snapshot
      .find_actor_profile(record.actor_id)
      .map(profile => {
        profile.source_kind is @energy_valley_contract.RuntimeEvidence
      })
      .unwrap_or(false)
    })[0]
  assert_false(live.agent.preview)
  assert_true(live.agent.selected)
  assert_eq(live.agent.work_color, "#6ee7b7")
  assert_true(
    runtime_snapshot.actor_presences.any(presence => {
      presence.actor_id == live.actor_id && presence.route_position is Some(_)
    }),
  )

  let player = snapshot_actor_test_player()
  let player_model = { ..init_model(), player: Some(player) }
  let player_snapshot = ecosystem_contract_town_snapshot(player_model, seed)
  let player_id = ecosystem_contract_scoped_id("player", "local")
  let player_profile = player_snapshot.find_actor_profile(player_id).unwrap()
  assert_eq(player_profile.avatar_variant, player.sprite_index)
  assert_eq(player_profile.palette_variant, player.color)
  let player_record = town_snapshot_canvas_actor_records(
      player_snapshot,
      4.0,
      false,
      None,
    ).filter(record => record.actor_id == player_id)[0]
  assert_eq(
    player_record.agent.sprite_path,
    golden_valley_agent_sprite_path("resident", player.sprite_index),
  )
  assert_eq(player_record.agent.work_color, player_avatar_colors[player.color])
  assert_eq(player_record.agent.activity_glyph, "★")
  assert_eq(player_record.agent.activity_label, player.name)
}

///|
test "reduced motion is a projection input, not a second movement truth" {
  let model = { ..init_model(), tick: 1 }
  let snapshot = ecosystem_contract_town_snapshot(model, 20260727)
  let still = town_snapshot_canvas_agents(snapshot, 99.0, true, None)
  assert_true(still.all(agent => agent.bob == 0.0))
}
