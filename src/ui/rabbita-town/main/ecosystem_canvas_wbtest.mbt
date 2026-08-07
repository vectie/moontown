///|
test "canvas exchanges mirror the authoritative active exchange ledger" {
  let snapshot = ecosystem_contract_town_snapshot(
    { ..init_model(), tick: 18 },
    20260727,
  )
  let exchanges = snapshot.active_exchanges()
  let specs = ecosystem_canvas_active_exchange_specs(snapshot)
  assert_true(exchanges.length() > 0)
  assert_eq(specs.length(), exchanges.length())
  for spec in specs {
    assert_true(spec.progress_per_mille >= 0)
    assert_true(spec.progress_per_mille <= 1000)
  }
}

///|
test "canvas exchange endpoints use semantic slots or entrances" {
  let snapshot = ecosystem_contract_town_snapshot(
    { ..init_model(), tick: 18 },
    20260727,
  )
  let exchanges = snapshot.active_exchanges()
  let specs = ecosystem_canvas_active_exchange_specs(snapshot)
  let mut witnessed_slot = false
  for index, spec in specs {
    let exchange = exchanges[index]
    let source = snapshot.world.find_place(exchange.source_place_id).unwrap()
    let target = snapshot.world.find_place(exchange.target_place_id).unwrap()
    let source_is_slot = source.interaction_slots.any(slot => {
      spec.source_position == (slot.position.x, slot.position.y)
    })
    let source_is_entrance = source.entrances.any(portal => {
      spec.source_position == (portal.position.x, portal.position.y)
    })
    let target_is_slot = target.interaction_slots.any(slot => {
      spec.target_position == (slot.position.x, slot.position.y)
    })
    let target_is_entrance = target.entrances.any(portal => {
      spec.target_position == (portal.position.x, portal.position.y)
    })
    assert_true(source_is_slot || source_is_entrance)
    assert_true(target_is_slot || target_is_entrance)
    witnessed_slot = witnessed_slot || source_is_slot || target_is_slot
  }
  assert_true(witnessed_slot)
}

///|
test "canvas exchange packet phase follows ledger lifetime" {
  let snapshot = ecosystem_contract_town_snapshot(
    { ..init_model(), tick: 18 },
    20260727,
  )
  for exchange in snapshot.active_exchanges() {
    match exchange.expires_tick {
      Some(expires_tick) if expires_tick > exchange.started_tick =>
        assert_eq(
          ecosystem_canvas_exchange_progress(snapshot.tick, exchange),
          ((snapshot.tick - exchange.started_tick).max(0) *
          1000 /
          (expires_tick - exchange.started_tick)).clamp(min=0, max=1000),
        )
      _ => ()
    }
  }
}

///|
test "canvas micro-scenes follow parcel program DNA" {
  let profile = ecosystem_place_profile_for_building(
    golden_valley_buildings(20260727)[0],
  )
  let world = ecosystem_contract_world_for_model(init_model(), 20260727)
  let mut programmed = 0
  for place in world.places {
    match place.program_id {
      None => ()
      Some(program_id) => {
        programmed += 1
        let expected = match program_id.local_key() {
          "research-lab" => "research"
          "research-garden"
          | "park-pavilion"
          | "park-commons"
          | "waterfront-walk" => "garden"
          "street-homes" | "residential-court" => "home"
          "valley-market" | "waterfront-pavilion" => "market"
          "civic-court" | "mixed-court" => "social"
          "transit-hall" | "transit-court" => "infrastructure"
          "civic-hall" => "civic"
          _ => ecosystem_canvas_profile_scene_kind(profile)
        }
        assert_eq(ecosystem_canvas_scene_kind(profile, Some(place)), expected)
      }
    }
  }
  assert_true(programmed > 0)
}
