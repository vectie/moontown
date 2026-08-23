///|
test "three-layer journey returns underground agents to the same interior" {
  let dispatch : Dispatch[Msg] = Emit(fn(_message) { @rabbita.none })
  let building = golden_valley_buildings(active_energy_valley_seed())[0]
  let indoor = {
    ..init_model(),
    energy_intro_open: false,
    town_spatial_layer: TownSpatialLayer::Indoor(building),
  }
  let (_, underground) = update(dispatch, OpenSecretComputeRoom, indoor)
  match underground.town_spatial_layer {
    Underground(Some(origin)) => assert_eq(origin.name, building.name)
    _ => fail("indoor lift should preserve its return building")
  }
  let (_, returned) = update(dispatch, CloseSecretComputeRoom, underground)
  match returned.town_spatial_layer {
    Indoor(origin) => assert_eq(origin.name, building.name)
    _ => fail("secured lift should return to the originating interior")
  }
}

///|
test "building interior is a complete layer with Agent work and compute lift" {
  let dispatch : Dispatch[Msg] = Emit(fn(_message) { @rabbita.none })
  let model = { ..init_model(), energy_intro_open: false }
  let snapshot = ecosystem_contract_town_snapshot(
    model,
    active_energy_valley_seed(),
  )
  let building = golden_valley_buildings(active_energy_valley_seed())[0]
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_energy_valley_building_interior(
        dispatch, model, snapshot, building,
      ),
    ),
  )
  assert_true(html.contains("building-interior-layer"))
  assert_true(html.contains("indoor-graphical-scene"))
  assert_true(html.contains("indoor-world-canvas"))
  assert_true(html.contains("indoor-world-hotspot"))
  assert_true(html.contains("InteractionSlot 家具"))
  assert_true(html.contains("ActorPresence Agent"))
  assert_true(html.contains("MOONTOWN · LAYER 0 · INDOOR"))
  assert_true(html.contains(building.name))
  assert_true(html.contains("正在室内的 Agent"))
  assert_true(html.contains("楼内工作与跨楼交接"))
  assert_true(html.contains("楼内 Agent"))
  assert_true(html.contains("MoonGate"))
  assert_true(html.contains("乘安全电梯前往地下"))
  assert_true(html.contains("返回地面"))
  match town_snapshot_place_for_building_view(model, snapshot, building) {
    Some(place) => {
      assert_true(html.contains("PLACE · \{place.id.local_key()}"))
      if !place.interaction_slots.is_empty() {
        assert_true(
          html.contains("SLOT · \{place.interaction_slots[0].id.local_key()}"),
        )
      }
    }
    None => fail("building should compile to a semantic Place")
  }
}

///|
test "outdoor indoor and underground render as mutually exclusive planes" {
  let dispatch : Dispatch[Msg] = Emit(fn(_message) { @rabbita.none })
  let base = { ..init_model(), energy_intro_open: false }
  let building = golden_valley_buildings(active_energy_valley_seed())[0]
  let indoor_html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_energy_valley_page(dispatch, {
        ..base,
        town_spatial_layer: TownSpatialLayer::Indoor(building),
      }),
    ),
  )
  let underground_html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_energy_valley_page(dispatch, {
        ..base,
        town_spatial_layer: TownSpatialLayer::Underground(Some(building)),
      }),
    ),
  )
  assert_true(indoor_html.contains("building-interior-layer"))
  assert_true(!indoor_html.contains("secret-compute-room"))
  assert_true(underground_html.contains("secret-compute-room"))
  assert_true(!underground_html.contains("building-interior-layer"))
  assert_true(underground_html.contains("返回 \{building.name}"))
}

///|
test "indoor semantic kinds map to distinct authored furniture cells" {
  assert_eq(
    indoor_scene_kind_asset_index(@energy_valley_contract.Workstation),
    0,
  )
  assert_eq(
    indoor_scene_kind_asset_index(@energy_valley_contract.MeetingPoint),
    1,
  )
  assert_eq(
    indoor_scene_kind_asset_index(@energy_valley_contract.ExchangeDesk),
    2,
  )
  assert_eq(
    indoor_scene_kind_asset_index(@energy_valley_contract.ServicePoint),
    3,
  )
  assert_eq(indoor_scene_kind_asset_index(@energy_valley_contract.Exhibit), 4)
  assert_eq(indoor_scene_kind_asset_index(@energy_valley_contract.Bench), 5)
  assert_eq(indoor_scene_kind_asset_index(@energy_valley_contract.Stage), 6)
  assert_eq(
    indoor_scene_kind_asset_index(@energy_valley_contract.TransitGate),
    7,
  )
}

///|
test "indoor atlas kinds keep calibrated floor-contact baselines" {
  assert_eq(
    indoor_scene_kind_asset_baseline(@energy_valley_contract.Workstation),
    0.91,
  )
  assert_eq(
    indoor_scene_kind_asset_baseline(@energy_valley_contract.ServicePoint),
    0.87,
  )
  assert_eq(
    indoor_scene_kind_asset_baseline(@energy_valley_contract.Exhibit),
    0.74,
  )
  assert_eq(
    indoor_scene_kind_asset_baseline(@energy_valley_contract.Bench),
    0.72,
  )
  assert_eq(
    indoor_scene_kind_asset_baseline(@energy_valley_contract.TransitGate),
    0.76,
  )
}
