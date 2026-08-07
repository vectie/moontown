///|
fn authored_building_test_value(
  name : String,
  x : Int,
  authored_id : String?,
) -> GoldenValleyBuilding {
  {
    authored_id,
    module_key: None,
    name,
    style: "custom-lab",
    x,
    y: 24,
    width: 6,
    depth: 6,
    entrance_x: None,
    entrance_y: None,
    floors: 2,
  }
}

///|
test "authored identity survives coordinate and style changes" {
  let candidate = authored_building_test_value("稳定实验室", 20, None)
  let (identified, next_sequence) = golden_valley_assign_authored_building_id(
    [],
    1,
    candidate,
  )
  assert_eq(identified.authored_id, Some("authored-building-1"))
  assert_eq(next_sequence, 2)
  let place_id = ecosystem_custom_place_id(identified)
  let profile_id = ecosystem_place_profile_for_building(identified).id
  let changed = {
    ..identified,
    x: 83,
    y: 91,
    style: "custom-tower",
    name: "重新装修的研发塔",
  }
  assert_eq(changed.authored_id, identified.authored_id)
  assert_eq(ecosystem_custom_place_id(changed), place_id)
  assert_eq(ecosystem_place_profile_for_building(changed).id, profile_id)
  assert_true(
    golden_valley_building_for_identity(
      [changed],
      identified.authored_id.unwrap(),
    )
    is Some(_),
  )
}

///|
test "legacy authored buildings migrate deterministically and round-trip" {
  let legacy_json = @json.parse(
    (
      #|{
      #|  "budget": 1730,
      #|  "buildings": [
      #|    {"name":"旧版工坊","style":"custom-hall","x":21,"y":24,"width":6,"depth":6,"floors":2},
      #|    {"name":"旧版实验室","style":"custom-lab","x":33,"y":30,"width":6,"depth":6,"floors":2}
      #|  ],
      #|  "roads": ["19:24"],
      #|  "parks": []
      #|}
    ),
  )
  let decoded : EnergyValleySave = @json.from_json(legacy_json) catch {
    error => fail("legacy save must remain readable: \{error}")
  }
  assert_eq(decoded.next_authored_building_sequence, None)
  assert_eq(decoded.buildings[0].authored_id, None)
  let migrated = golden_valley_migrate_energy_save(decoded)
  assert_eq(migrated.buildings.map(building => building.authored_id.unwrap()), [
    "authored-building-1", "authored-building-2",
  ])
  assert_eq(migrated.next_authored_building_sequence, Some(3))
  let persisted = ToJson::to_json(migrated)
  let restored : EnergyValleySave = @json.from_json(persisted) catch {
    error => fail("identified save must round-trip: \{error}")
  }
  let restored = golden_valley_migrate_energy_save(restored)
  assert_eq(
    restored.buildings.map(building => building.authored_id.unwrap()),
    migrated.buildings.map(building => building.authored_id.unwrap()),
  )
  assert_eq(restored.next_authored_building_sequence, Some(3))
}

///|
test "authored allocation repairs collisions and never reuses the counter" {
  let first = authored_building_test_value(
    "一号楼",
    20,
    Some("authored-building-1"),
  )
  let duplicate = authored_building_test_value(
    "重复编号楼",
    30,
    Some("authored-building-1"),
  )
  let (migrated, next_sequence) = golden_valley_migrate_authored_buildings(
    [first, duplicate],
    Some(5),
  )
  assert_eq(migrated.map(building => building.authored_id.unwrap()), [
    "authored-building-1", "authored-building-5",
  ])
  assert_eq(next_sequence, 6)
  let candidate = authored_building_test_value("新楼", 40, None)
  let (created, following) = golden_valley_assign_authored_building_id(
    migrated, next_sequence, candidate,
  )
  assert_eq(created.authored_id, Some("authored-building-6"))
  assert_eq(following, 7)
}

///|
test "legacy migration reserves later explicit identities before filling gaps" {
  let legacy = authored_building_test_value("待迁移旧楼", 18, None)
  let identified = authored_building_test_value(
    "已有稳定身份",
    42,
    Some("authored-building-1"),
  )
  let (migrated, next_sequence) = golden_valley_migrate_authored_buildings(
    [legacy, identified],
    None,
  )
  assert_eq(migrated[0].authored_id, Some("authored-building-2"))
  assert_eq(migrated[1].authored_id, Some("authored-building-1"))
  assert_eq(next_sequence, 3)
}
