///|
test "living room is the arrival while explicit overview and calibration stay intact" {
  assert_true(street_living_room_requested("", false))
  assert_true(street_living_room_requested("living-room", false))
  assert_false(street_living_room_requested("town", false))
  assert_false(street_living_room_requested("overview", false))
  assert_false(street_living_room_requested("", true))
  assert_true(
    town_spatial_layer_for_route("indoor", "future-center-g3")
    is ReferenceInterior,
  )
  assert_true(town_spatial_layer_for_route("compute", "") is Underground(_))
}

///|
test "homepage preview reads public content without opening a sheet or reading identity" {
  let (preview, request) = neighborhood_transition(
    initial_neighborhood_state(),
    Preview,
  )
  assert_true(request is Some(PublicLoad(1)))
  assert_false(preview.open)
  assert_true(preview.loading)
  assert_false(preview.mine_loading)
  let public = neighborhood_transition(
      preview,
      Loaded(
        1,
        "public",
        neighborhood_test_reply(
          neighborhood_test_snapshot(actor="must-not-install"),
        ),
      ),
    ).0
  assert_true(public.snapshot is Some(_))
  assert_true(public.mine is None)
  assert_eq(public.actor_id, "")
  let (opened, load) = neighborhood_transition(public, Open)
  assert_true(opened.open && opened.mine_loading)
  assert_true(load is Some(Load(2)))
  assert_eq(
    neighborhood_transition(opened, Loaded(1, "public", "stale")).0.generation,
    2,
  )
}

///|
test "arrival cards never promote drafts or private stories and choose next event" {
  let snapshot : Json = {
    "stories": [
      { "id": "draft", "state": "draft", "title": "private draft" },
      { "id": "published", "state": "published", "title": "公开故事" },
    ],
    "events": [
      { "id": "archive", "state": "ended" },
      { "id": "late", "state": "published", "starts_ms": 3000, "ends_ms": 4000 },
      { "id": "next", "state": "published", "starts_ms": 2000, "ends_ms": 3000 },
      {
        "id": "cancelled",
        "state": "cancelled",
        "starts_ms": 1100,
        "ends_ms": 1500,
      },
    ],
  }
  let state = { ..initial_neighborhood_state(), snapshot: Some(snapshot), }
  assert_eq(
    neighborhood_text(street_featured_item(state, true, 1000).unwrap(), "id"),
    "published",
  )
  assert_eq(
    neighborhood_text(street_featured_item(state, false, 1000).unwrap(), "id"),
    "next",
  )
  assert_eq(
    neighborhood_text(street_featured_item(state, false, 5000).unwrap(), "id"),
    "archive",
  )
  let private_only = { ..initial_neighborhood_state(), mine: Some(snapshot), }
  assert_true(street_featured_item(private_only, true, 1000) is None)
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let html = disclosure_test_html(render_street_notice(dispatch, state, true))
  assert_true(html.contains("公开故事"))
  assert_false(html.contains("private draft"))
  assert_true(html.contains("邻里故事"))
  assert_false(html.contains("street-notice-content"))
}

///|
test "empty and failed arrival content stay truthful and actionable" {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let empty = disclosure_test_html(
    render_street_notice(dispatch, initial_neighborhood_state(), false),
  )
  assert_true(empty.contains("下一场，敬请期待"))
  assert_false(empty.contains("报名中"))
  let error = disclosure_test_html(
    render_street_notice(
      dispatch,
      { ..initial_neighborhood_state(), error: "unavailable", },
      false,
    ),
  )
  assert_true(error.contains("暂未连接"))
  assert_false(error.contains("下一场"))
}

///|
test "overview home and indoor navigation use one world without stacked panels" {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let base = { ..init_model(), energy_request_open: true, }
  let overview = update(dispatch, SetStreetLivingRoom(false), base).1
  assert_false(overview.street_living_room)
  assert_false(overview.energy_request_open)
  assert_true(overview.town_spatial_layer is Outdoor)
  let home = update(dispatch, SetStreetLivingRoom(true), overview).1
  assert_true(home.street_living_room)
  let opened = update(dispatch, OpenStreetContent("stories", "story-a"), home).1
  assert_true(opened.neighborhood.open)
  assert_eq(opened.neighborhood.section, "stories")
  assert_eq(opened.neighborhood.selected_id, "story-a")
  let indoor = update(dispatch, OpenReferenceInterior, opened).1
  assert_true(indoor.town_spatial_layer is ReferenceInterior)
  assert_false(indoor.neighborhood.open)
  let returned = update(dispatch, ExitEnergyBuilding, indoor).1
  assert_true(returned.street_living_room)
  assert_true(returned.town_spatial_layer is Outdoor)
}

///|
test "arrival camera uses registered center and cannot change road calibration" {
  canvas_frame_test_install_harness(true)
  town_landmarks_init()
  let center = town_landmark_find("center").unwrap()
  let before = (center.origin.x, center.origin.y, center.east.x, center.south.y)
  prepare_street_living_room_camera(true)
  let close_zoom = golden_valley_camera_zoom()
  assert_true(close_zoom > 1.0)
  wenyu_gentle_ground_trial_fit_camera(96, 64)
  assert_eq(golden_valley_camera_zoom(), close_zoom)
  calibration_test_gentle_asset(true)
  let context = calibration_test_context()
  wenyu_gentle_ground_overlay(
    context,
    golden_valley_camera_x(),
    golden_valley_camera_y(),
    close_zoom,
    96,
    64,
  )
  let road_x = calibration_test_matrix(context, 0) * center.origin.x +
    calibration_test_matrix(context, 2) * center.origin.y +
    calibration_test_matrix(context, 4)
  assert_true(
    (road_x - golden_screen_x(center.origin.x, center.origin.y, 96)).abs() <
    0.00000001,
  )
  prepare_street_living_room_camera(false)
  wenyu_gentle_ground_trial_fit_camera(1280, 720)
  assert_true(golden_valley_camera_zoom() < close_zoom)
  assert_eq(
    before,
    (center.origin.x, center.origin.y, center.east.x, center.south.y),
  )
  calibration_test_gentle_asset(false)
  canvas_frame_test_remove_harness()
}
