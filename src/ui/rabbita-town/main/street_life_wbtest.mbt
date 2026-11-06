///|
fn street_life_test_base() -> @landmark_routes.Graph {
  let center = town_landmark_find("center").unwrap()
  {
    nodes: [
      { id: "a", x: center.door.x - 2, y: center.door.y, },
      { id: "b", x: center.door.x + 2, y: center.door.y, },
    ],
    edges: [{ a: "a", b: "b", bridge: false, }],
  }
}

///|
test "street life compiles bounded private routines without changing accepted routes" {
  town_landmarks_init()
  let old = town_landmark_graph.get("active")
  let base = street_life_test_base()
  town_landmark_graph["active"] = base
  street_life_plan_key.val = ""
  street_life_prepare()
  let graph = street_life_graph(base)
  assert_eq(street_life_plans.length(), 4)
  assert_eq(base.nodes.length(), 2)
  assert_eq(base.edges.length(), 1)
  assert_eq(graph.nodes.length(), 15)
  assert_eq(graph.edges.length(), 13)
  let stops : Array[(Double, Double)] = []
  let center = town_landmark_find("center").unwrap()
  let determinant = center.east.x * center.south.y -
    center.east.y * center.south.x
  for plan in street_life_plans {
    assert_true(plan.period > 0 && plan.legs.length() <= 4)
    for i, leg in plan.legs {
      let next = plan.legs[(i + 1) % plan.legs.length()]
      assert_eq(leg.path.last().unwrap(), next.path[0])
      assert_true(leg.pause >= 9)
      assert_false(stops.contains(leg.path[0]))
      stops.push(leg.path[0])
      for p in leg.path {
        assert_true(street_road_point(graph, p, 0.001) is Some(_))
      }
    }
    // Cycles loop at the same location, not a new spawn. Sampled motion is
    // bounded by the walking speed and cannot cross through an unconnected lot.
    for i in 0..<1600 {
      let t = i.to_double() * 0.1
      let a = street_life_sample(plan, t, None)
      let b = street_life_sample(plan, t + 0.1, None)
      let d = player_path_length([a.point, b.point])
      assert_true(d <= 0.052001)
      assert_true(street_road_point(graph, a.point, 0.001) is Some(_))
      if a.pose == "walk" {
        let dx = a.point.0 - center.origin.x
        let dy = a.point.1 - center.origin.y
        let x = (dx * center.south.y - dy * center.south.x) / determinant
        let z = (dy * center.east.x - dx * center.east.y) / determinant
        // Physical table, benches, kiosk and boards, in the same local basis
        // as street_courtyard_art. Readers may sit; walking actors may not.
        for
          (left, right, back, front) in [
            (-10.0, 10.0, 110.0, 130.0),
            (-29.0, -1.0, 135.0, 145.0),
            (81.0, 109.0, 142.0, 152.0),
            (-93.0, -57.0, 101.0, 128.0),
            (43.0, 67.0, 116.0, 124.0),
            (88.0, 112.0, 116.0, 124.0),
          ] {
          assert_false(x > left && x < right && z > back && z < front)
        }
      }
    }
  }
  match old {
    Some(g) => town_landmark_graph["active"] = g
    None => town_landmark_graph.remove("active")
  }
  street_life_plans.clear()
  street_life_plan_key.val = ""
}

///|
test "nearby attention changes facing not route or player state" {
  let leg : StreetLifeLeg = {
    path: [(1.0, 2.0), (3.0, 2.0)],
    travel: 2.0 / 0.52,
    pause: 12,
    pose: "coffee",
  }
  let plan : StreetLifePlan = {
    sprite: 8,
    offset: 0,
    legs: [leg],
    period: leg.pause + leg.travel,
  }
  let idle = street_life_sample(plan, 3, None)
  let greeted = street_life_sample(plan, 3, Some((1.0, 2.6)))
  assert_true(greeted.attentive)
  assert_eq(greeted.point, idle.point)
  assert_eq(greeted.facing, (1.0, 2.6))
  assert_eq(greeted.pose, "coffee")
  assert_false(street_life_sample(plan, 3, Some((100.0, 100.0))).attentive)
  let moving = street_life_sample(plan, 13, Some((1.5, 2.1)))
  assert_eq(moving.pose, "walk")
  assert_false(moving.attentive)
}

///|
test "scenery clock freezes and does not catch up after hidden tabs or reduced motion" {
  let clock : StreetLifeClock = { last: -1, elapsed: 0, }
  assert_eq(clock.advance(100, true), 0)
  assert_true((clock.advance(100.05, true) - 0.05).abs() < 0.00001)
  let before = clock.elapsed
  assert_eq(clock.advance(200, false), before)
  assert_eq(clock.advance(300, false), before)
  assert_true(clock.advance(800, true) - before <= 0.120001)
  let resumed = clock.elapsed
  assert_eq(clock.advance(799, true), resumed)
}

///|
extern "js" fn street_life_test_pause(
  reduced : Bool,
  hidden : Bool,
  modal : Bool,
) -> Unit =
  #| (reduced,hidden,modal)=>{globalThis.matchMedia().matches=reduced;document.hidden=hidden;document.querySelector=()=>modal?{}:null;}

///|
test "scenery frame respects reduced motion and pauses behind panels" {
  canvas_frame_test_install_harness(true)
  town_landmarks_init()
  let old_graph = town_landmark_graph.get("active")
  town_landmark_graph["active"] = street_life_test_base()
  street_life_plan_key.val = ""
  let old_time = street_life_clock.elapsed
  let old_last = street_life_clock.last
  street_life_clock.elapsed = 7
  street_life_clock.last = browser_now_ms() / 1000 - 1
  prepare_street_living_room_camera(true)
  street_life_test_pause(true, false, false)
  assert_eq(street_life_frame(None, 96, 64).length(), 4)
  assert_eq(street_life_clock.elapsed, 7)
  street_life_test_pause(false, false, false)
  street_life_clock.last = browser_now_ms() / 1000 - 0.05
  assert_eq(street_life_frame(None, 96, 64).length(), 4)
  assert_true(street_life_clock.elapsed > 7)
  let before = street_life_clock.elapsed
  street_life_test_pause(false, true, false)
  assert_eq(street_life_frame(None, 96, 64).length(), 4)
  assert_eq(street_life_clock.elapsed, before)
  street_life_test_pause(false, false, true)
  assert_eq(street_life_frame(None, 96, 64).length(), 4)
  assert_eq(street_life_clock.elapsed, before)
  street_life_clock.elapsed = old_time
  street_life_clock.last = old_last
  match old_graph {
    Some(g) => town_landmark_graph["active"] = g
    None => town_landmark_graph.remove("active")
  }
  street_life_plans.clear()
  street_life_plan_key.val = ""
  prepare_street_living_room_camera(false)
  canvas_frame_test_remove_harness()
}

///|
test "bird flight is bounded and continuous across perch and loop boundaries" {
  for bird in 0..<2 {
    for i in 0..<1500 {
      let t = i.to_double() * 0.1
      let (x, y, z) = street_life_bird_position(t, bird)
      let (nx, ny, nz) = street_life_bird_position(t + 0.1, bird)
      assert_true(x >= -91.00001 && x <= 30.00001)
      assert_true(y >= 145 && y <= 162.00001)
      assert_true(z >= 0 && z <= 20.00001)
      assert_true(
        (x - nx).abs() < 2.421 && (y - ny).abs() < 1 && (z - nz).abs() < 1.3,
      )
    }
  }
}

///|
extern "js" fn street_life_test_camera(z : Double, transition : Bool) -> Unit =
  #| (z,transition)=>{const c=globalThis.__moontownGoldenValleyCamera;c.z=z;delete c.streetTransition;if(transition)c.streetClose={x:c.x,y:c.y,z};}

///|
test "street camera cannot drift to map scale while overview remains available" {
  canvas_frame_test_install_harness(true)
  town_landmarks_init()
  prepare_street_living_room_camera(true)
  street_life_test_camera(0.1, false)
  prepare_street_living_room_camera(true)
  assert_true(golden_valley_camera_zoom() >= 1.8)
  // An actual overview, unlike a wheel zoom, is allowed to use map scale.
  prepare_street_living_room_camera(true, overview=true)
  street_life_test_camera(0.1, false)
  prepare_street_living_room_camera(true, overview=true)
  assert_true(golden_valley_camera_zoom() < 1)
  prepare_street_living_room_camera(false)
  canvas_frame_test_remove_harness()
}
