///|
fn street_test_graph() -> @landmark_routes.Graph {
  {
    nodes: [
      { id: "a", x: 0.0, y: 0.0, },
      { id: "b", x: 10.0, y: 0.0, },
      { id: "c", x: 10.0, y: 10.0, },
      { id: "d", x: 5.0, y: -5.0, },
      { id: "e", x: 5.0, y: 5.0, },
    ],
    edges: [
      { a: "a", b: "b", bridge: true, },
      { a: "b", b: "c", bridge: false, },
      { a: "d", b: "e", bridge: false, },
    ],
  }
}

///|
test "street walk splits an existing edge in both directions without snapping to endpoints" {
  let graph = street_test_graph()
  let forward = street_road_route(graph, (2.0, 0.0), (8.0, 0.2)).unwrap()
  assert_eq(forward[0], (2.0, 0.0))
  assert_eq(forward[forward.length() - 1], (8.0, 0.0))
  assert_eq(player_path_length(forward), 6.0)
  let reverse = street_road_route(graph, (8.0, 0.0), (2.0, 0.0)).unwrap()
  assert_eq(player_path_length(reverse), 6.0)
  assert_eq(graph.nodes.length(), 5)
  assert_eq(graph.edges.length(), 3)
  assert_true(graph.edges[0].bridge)
}

///|
test "street walk follows junctions but never connects a picture crossing or off-road goal" {
  let graph = street_test_graph()
  let route = street_road_route(graph, (2.0, 0.0), (10.0, 8.0)).unwrap()
  assert_eq(player_path_length(route), 16.0)
  assert_true(route.contains((10.0, 0.0)))
  assert_true(street_road_route(graph, (2.0, 0.0), (5.0, 4.0)) is None)
  assert_true(street_road_route(graph, (2.0, 0.0), (20.0, 20.0)) is None)
  assert_true(
    street_road_route(
      graph,
      (5.0, 0.0),
      (8.0, 0.0),
      start_hint=Some((5.0, -0.001)),
    )
    is None,
  )
  assert_true(
    street_road_route(
      graph,
      (5.0, 0.0),
      (5.0, 4.0),
      start_hint=Some((5.0, -0.001)),
    )
    is Some(_),
  )
  let mid = player_point_along(route, 3.4)
  let interrupted = street_road_route(graph, mid, (1.0, 0.0)).unwrap()
  assert_true((player_path_length(interrupted) - 4.4).abs() < 0.000001)
  assert_eq(interrupted[0], mid)
}

///|
test "street overview preserves walk state and is not a second page or identity" {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let model = { ..init_model(), street_living_room: true, player: None, }
  let overview = update(dispatch, StreetOverview, model).1
  assert_true(overview.street_living_room && overview.street_overview)
  assert_true(overview.player is None)
  assert_true(overview.player_position is None)
  assert_true(overview.street_motion is None)
  let returned = update(dispatch, StreetOverview, overview).1
  assert_false(returned.street_overview)
  assert_true(returned.street_living_room)
  assert_eq(returned.neighborhood.generation, model.neighborhood.generation)
}

///|
test "street input is inert behind content and in another spatial layer" {
  let model = { ..init_model(), street_living_room: true, player: None, }
  let panel = { ..model, neighborhood: { ..model.neighborhood, open: true, }, }
  let indoor = { ..model, town_spatial_layer: ReferenceInterior, }
  let authoring = { ..model, street_living_room: false, }
  for before in [panel, indoor, authoring] {
    let after = street_walk_to(before, (1.0, 1.0))
    assert_true(after.street_motion is None)
    assert_true(after.player is None)
    assert_eq(after.life_toast, before.life_toast)
  }
}

///|
extern "js" fn street_test_reduce_motion() -> Unit =
  #| () => { globalThis.__moontownCanvasFrameTimingTest.motion.matches = true; }

///|
test "reduced-motion overview restores the exact close camera without waiting for animation" {
  canvas_frame_test_install_harness(true)
  street_test_reduce_motion()
  prepare_street_living_room_camera(true)
  let close = (
    golden_valley_camera_x(),
    golden_valley_camera_y(),
    golden_valley_camera_zoom(),
  )
  prepare_street_living_room_camera(true, overview=true)
  assert_true(golden_valley_camera_zoom() < close.2)
  prepare_street_living_room_camera(true, overview=false)
  assert_eq(
    (
      golden_valley_camera_x(),
      golden_valley_camera_y(),
      golden_valley_camera_zoom(),
    ),
    close,
  )
  canvas_frame_test_remove_harness()
}
