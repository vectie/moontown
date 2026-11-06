///|
test "forecourt paths extend a copy of the exact entrance edge without changing OSM" {
  town_landmarks_init()
  let center = town_landmark_find("center").unwrap()
  let old = town_landmark_graph.get("active")
  let graph : @landmark_routes.Graph = {
    nodes: [
      { id: "a", x: center.door.x - 2.0, y: center.door.y, },
      { id: "b", x: center.door.x + 2.0, y: center.door.y, },
    ],
    edges: [{ a: "a", b: "b", bridge: false, }],
  }
  town_landmark_graph["active"] = graph
  let expanded = street_courtyard_graph(graph)
  assert_eq(graph.nodes.length(), 2)
  assert_eq(graph.edges.length(), 1)
  assert_eq(expanded.nodes.length(), 8)
  assert_eq(expanded.edges.length(), 7)
  assert_eq(street_courtyard_graph(expanded).nodes.length(), 8)
  for place in ["seat", "cafe", "stories", "events", "interior"] {
    let goal = street_courtyard_point(place).unwrap()
    let path = street_road_route(expanded, street_spawn().unwrap(), goal).unwrap()
    assert_true(player_path_length(path) > 0)
    let end = path[path.length() - 1]
    assert_true((end.0 - goal.0).abs() + (end.1 - goal.1).abs() < 0.00001)
  }
  match old {
    Some(g) => town_landmark_graph["active"] = g
    None => town_landmark_graph.remove("active")
  }
}

///|
test "arrival is fenced by generation layer and proximity and seating does not touch identity" {
  town_landmarks_init()
  let goal = street_courtyard_point("seat").unwrap()
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let base = {
    ..init_model(),
    street_living_room: true,
    street_visit: "seat",
    street_visit_generation: 8,
    street_motion: Some({
      from_x: goal.0,
      from_y: goal.1,
      to_x: goal.0,
      to_y: goal.1,
      started_seconds: 0,
      path: [goal],
    }),
  }
  let stale = street_visit_arrive(dispatch, base, 7).1
  assert_false(stale.street_seated)
  assert_eq(stale.street_visit, "seat")
  let indoors = street_visit_arrive(
      dispatch,
      { ..base, town_spatial_layer: ReferenceInterior, },
      8,
    ).1
  assert_false(indoors.street_seated)
  let panel = street_visit_arrive(
      dispatch,
      { ..base, neighborhood: { ..base.neighborhood, open: true, }, },
      8,
    ).1
  assert_false(panel.street_seated)
  let seated = street_visit_arrive(dispatch, base, 8).1
  assert_true(seated.street_seated)
  assert_eq(seated.street_visit, "")
  assert_eq(seated.street_memories, ["seat"])
  assert_eq(seated.neighborhood.actor_id, base.neighborhood.actor_id)
  assert_eq(seated.neighborhood.generation, base.neighborhood.generation)
  let stood = street_visit_begin(dispatch, seated, "seat").1
  assert_false(stood.street_seated)
  assert_eq(stood.street_memories, ["seat"])
  assert_true(street_courtyard_point("fake") is None)
}

///|
test "daylight keeps distinct water path and canopy materials" {
  assert_eq(town_daylight_color("water"), "#319fc8")
  assert_eq(town_daylight_color("path"), "#eeddb8")
  assert_true(town_daylight_color("leaf") != town_daylight_color("grass"))
  assert_true(town_daylight_color("paper") != town_daylight_color("path"))
}

///|
extern "js" fn daylight_test_fill(c : @dom.CanvasRenderingContext2D) -> String =
  #| c=>String(c.fillStyle)

///|
test "daylight ground is world-stable and never recolors water or the calibration view" {
  canvas_frame_test_install_harness(true)
  prepare_street_living_room_camera(true)
  let c = calibration_test_context()
  assert_true(town_paint_daylight_ground(c, "grass", 10, 20, 2, 20, 25))
  let color = daylight_test_fill(c)
  assert_true(town_paint_daylight_ground(c, "grass", 550, 100, 0.3, 20, 25))
  assert_eq(daylight_test_fill(c), color)
  assert_false(town_paint_daylight_ground(c, "water", 10, 20, 2, 20, 25))
  assert_false(town_paint_daylight_ground(c, "plaza", 10, 20, 2, 20, 25))
  prepare_street_living_room_camera(false)
  assert_false(town_paint_daylight_ground(c, "grass", 10, 20, 2, 20, 25))
  canvas_frame_test_remove_harness()
}
