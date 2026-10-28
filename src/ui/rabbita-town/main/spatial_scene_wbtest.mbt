///|
fn scene_test_selection(key : String, scope : String, id : String) -> String {
  let selection : SpatialSceneSelection = {
    key,
    scope,
    id,
    view: "hall",
    title: "测试对象",
    detail: "示意",
    visit: "rack",
  }
  ToJson::to_json(selection).stringify()
}

///|
test "design inspection never becomes a runtime machine assignment" {
  let model = { ..init_model(), town_spatial_layer: Underground(None), }
  let next = spatial_scene_select(
    model,
    scene_test_selection("compute", "design", "A1"),
  )
  assert_eq(
    next.secret_compute_room_selected_id,
    model.secret_compute_room_selected_id,
  )
  assert_eq(spatial_scene_selected(next).map(s => s.id), Some("A1"))
  assert_true(
    spatial_scene_context(next) is { "selection": { "id": "A1", .. }, .. },
  )
  assert_true(spatial_scene_context(model) is { "selection": Null, .. })
  assert_eq(
    spatial_scene_selected(
      spatial_scene_select(next, scene_test_selection("other", "design", "A2")),
    ).map(s => s.id),
    Some("A1"),
  )
  assert_eq(
    spatial_scene_selected(
      spatial_scene_select(
        next,
        scene_test_selection("compute", "runtime", "phantom-machine"),
      ),
    ).map(s => s.id),
    Some("A1"),
  )
}

///|
test "G3 reference has a distinct route and preserves compute return context" {
  assert_true(
    town_spatial_layer_for_route("indoor", "future-center-g3")
    is ReferenceInterior,
  )
  let dispatch : Dispatch[Msg] = Emit(_ => @rabbita.none)
  let reference = {
    ..init_model(),
    town_spatial_layer: ReferenceInterior,
    spatial_selected_work_id: "keep-work",
    spatial_request_id: "keep-request",
  }
  let (_, compute) = update(dispatch, OpenSecretComputeRoom, reference)
  assert_true(compute.spatial_compute_return_reference)
  let selected = spatial_scene_select(
    compute,
    scene_test_selection("compute", "design", "A4"),
  )
  let (_, returned) = update(dispatch, CloseSecretComputeRoom, selected)
  assert_true(returned.town_spatial_layer is ReferenceInterior)
  assert_eq(returned.spatial_selected_work_id, "keep-work")
  assert_eq(returned.spatial_request_id, "keep-request")
  let (_, again) = update(dispatch, OpenSecretComputeRoom, returned)
  assert_eq(spatial_scene_selected(again).map(s => s.id), Some("A4"))
  let html = disclosure_test_html(render_reference_interior(dispatch, returned))
  assert_true(html.contains("G 座 · 三层"))
  assert_false(html.contains("policy-hall-question"))
  assert_false(html.contains("<iframe"))
}

///|
test "3D furniture identity uses the same semantic slots as the inspector" {
  let building = golden_valley_buildings(active_energy_valley_seed())[0]
  let model = { ..init_model(), town_spatial_layer: Indoor(building), }
  let snapshot = ecosystem_contract_town_snapshot(
    model,
    active_energy_valley_seed(),
  )
  guard town_snapshot_place_for_building_view(model, snapshot, building)
    is Some(place) else {
    fail("missing place")
  }
  guard place.interaction_slots.get(0) is Some(slot) else {
    fail("missing slot")
  }
  let selected = spatial_scene_select(
    model,
    scene_test_selection(
      spatial_scene_key(model),
      "runtime",
      slot.id.local_key(),
    ),
  )
  assert_eq(selected.indoor_selected_slot_id, slot.id.local_key())
  let html = disclosure_test_html(
    render_indoor_spatial_stage(selected, snapshot, place),
  )
  assert_true(html.contains(slot.id.local_key()))
  assert_true(html.contains(slot.label))
  let invalid = spatial_scene_select(
    selected,
    scene_test_selection(spatial_scene_key(model), "runtime", "not-a-slot"),
  )
  assert_eq(invalid.indoor_selected_slot_id, selected.indoor_selected_slot_id)
}
