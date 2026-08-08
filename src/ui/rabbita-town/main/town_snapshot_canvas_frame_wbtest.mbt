///|
test "accepted Canvas frame keeps building identity until a new frame is accepted" {
  let rendered = ecosystem_contract_town_snapshot(init_model(), 20260727)
  let projected = town_snapshot_canvas_buildings(rendered)
  assert_true(!projected.is_empty())
  let visible = town_snapshot_canvas_building_at_tile(
    rendered,
    projected[0].x,
    projected[0].y,
  ).unwrap()
  golden_valley_accept_canvas_frame(rendered)
  let accepted = golden_valley_canvas_frame_building_at_tile(
    visible.x,
    visible.y,
  ).unwrap()
  assert_eq(accepted.place_id, visible.place_id)
  golden_focus_building_camera(
    visible.x.to_double() + 0.5,
    visible.y.to_double() + 0.5,
  )
  let viewport_width = golden_valley_canvas_width("energy-valley-canvas")
  let viewport_height = golden_valley_canvas_height("energy-valley-canvas")
  let pointer_x = golden_screen_x(
      visible.x.to_double() + 0.5,
      visible.y.to_double() + 0.5,
      viewport_width,
    )
    .floor()
    .to_int()
  let pointer_y = golden_screen_y(
      visible.x.to_double() + 0.5,
      visible.y.to_double() + 0.5,
      viewport_height,
    )
    .floor()
    .to_int()
  let selected = energy_valley_canvas_click_model(
    init_model(),
    pointer_x,
    pointer_y,
  )
  let selected_place_id = match selected.energy_selected_building {
    Some(building) =>
      town_snapshot_place_for_visual_building(rendered, building).map(place => {
        place.id
      })
    None => None
  }
  assert_eq(selected_place_id, Some(visible.place_id))

  // A newer semantic value may already exist in application code, but it is
  // not pointer truth until Canvas accepts it as the displayed frame.
  let newer = {
    ..rendered,
    tick: rendered.tick + 1,
    world: { ..rendered.world, places: [] },
  }
  assert_true(
    town_snapshot_canvas_building_at_tile(newer, visible.x, visible.y) is None,
  )
  assert_eq(
    golden_valley_canvas_frame_building_at_tile(visible.x, visible.y).map(building => {
      building.place_id
    }),
    Some(visible.place_id),
  )

  golden_valley_accept_canvas_frame(newer)
  assert_true(
    golden_valley_canvas_frame_building_at_tile(visible.x, visible.y) is None,
  )
  // The Model still describes the original town. Inspect must nevertheless
  // observe the accepted empty frame, because that is what the pointer sees.
  assert_true(
    energy_valley_canvas_click_model(init_model(), pointer_x, pointer_y).energy_selected_building
    is None,
  )
  // Leave the cache useful for any later white-box probe in this process.
  golden_valley_accept_canvas_frame(rendered)
}

///|
test "accepted Canvas frame keeps actor records from the displayed snapshot" {
  let live_model = runtime_map_routing_live_model()
  let live = ecosystem_contract_town_snapshot(live_model, 20260727)
  let runtime_id = ecosystem_contract_scoped_id(
    "runtime-agent", "routing-agent",
  )
  assert_true(
    town_snapshot_canvas_actor_records(live, 0.0, true, None).any(record => {
      record.actor_id == runtime_id
    }),
  )
  let runtime_record = town_snapshot_canvas_actor_records(live, 0.0, true, None).filter(record => {
        record.actor_id == runtime_id
      },
    )[0]
  golden_focus_building_camera(runtime_record.agent.x, runtime_record.agent.y)
  let viewport_width = golden_valley_canvas_width("energy-valley-canvas")
  let viewport_height = golden_valley_canvas_height("energy-valley-canvas")
  let live_positions = golden_valley_runtime_agent_map_positions_from_snapshot(
    live,
    None,
    viewport_width,
    viewport_height,
  )
  let runtime_position = live_positions.filter(position => {
      position.agent_id == "routing-agent"
    })[0]
  let pointer_x = runtime_position.screen_x.floor().to_int()
  let pointer_y = runtime_position.screen_y.floor().to_int()
  golden_valley_accept_canvas_frame(live)
  let stale_model = {
    ..live_model,
    energy_valley_runtime: { ..live_model.energy_valley_runtime, phase: Stale },
  }
  // Eligibility belongs to the frame that completed drawing. A newer stale
  // application Model must not disable a still-visible live Agent.
  assert_eq(
    golden_valley_runtime_agent_at_canvas_point(
      stale_model, pointer_x, pointer_y,
    ),
    Some("routing-agent"),
  )

  let newer = {
    ..live,
    tick: live.tick + 1,
    actor_profiles: [],
    actor_presences: [],
  }
  assert_true(
    town_snapshot_canvas_actor_records(newer, 0.0, true, None).is_empty(),
  )
  assert_eq(
    golden_valley_runtime_agent_hit_test_from_snapshot(
      newer,
      None,
      viewport_width,
      viewport_height,
      pointer_x,
      pointer_y,
      golden_valley_camera_zoom(),
    ),
    None,
  )
  let accepted = golden_valley_canvas_frame().unwrap()
  assert_eq(accepted.tick, live.tick)
  assert_true(
    town_snapshot_canvas_actor_records(accepted, 0.0, true, None).any(record => {
      record.actor_id == runtime_id
    }),
  )

  golden_valley_accept_canvas_frame(newer)
  // The live Model remains unchanged. Pointer truth follows the newly
  // accepted empty frame, so a now-invisible Agent cannot be selected.
  assert_eq(
    golden_valley_runtime_agent_at_canvas_point(
      runtime_map_routing_live_model(),
      pointer_x,
      pointer_y,
    ),
    None,
  )
  assert_true(
    town_snapshot_canvas_actor_records(
      golden_valley_canvas_frame().unwrap(),
      0.0,
      true,
      None,
    ).is_empty(),
  )
  golden_valley_accept_canvas_frame(live)
}

///|
extern "js" fn canvas_frame_test_install_harness(with_canvas : Bool) -> Unit =
  #| withCanvas => {
  #|   const names = [
  #|     "document",
  #|     "HTMLCanvasElement",
  #|     "CanvasRenderingContext2D",
  #|     "requestAnimationFrame",
  #|     "addEventListener",
  #|     "__moontownGoldenValleyCamera",
  #|     "__moontownGoldenValleyCameraArtVersion",
  #|     "__moontownGoldenValleyCanvasSchedule",
  #|     "__moontownGoldenValleyRender",
  #|     "__moontownGoldenValleyKeys",
  #|     "__moontownGoldenValleyAnimation",
  #|     "__moontownPlayerWalkKeys",
  #|   ];
  #|   const descriptors = new Map(
  #|     names.map(name => [name, Object.getOwnPropertyDescriptor(globalThis, name)]),
  #|   );
  #|   const callbacks = [];
  #|   const gradient = { addColorStop() {} };
  #|   class TestContext {
  #|     createLinearGradient() { return gradient; }
  #|     createRadialGradient() { return gradient; }
  #|     measureText() { return { width: 24 }; }
  #|   }
  #|   const context = new Proxy(new TestContext(), {
  #|     get(target, key) {
  #|       if (key in target) return target[key];
  #|       return () => {};
  #|     },
  #|     set(target, key, value) { target[key] = value; return true; },
  #|   });
  #|   class TestCanvas {
  #|     constructor() {
  #|       this.clientWidth = 96;
  #|       this.clientHeight = 64;
  #|       this.width = 96;
  #|       this.height = 64;
  #|       this.dataset = {};
  #|     }
  #|     getContext(kind) { return kind === "2d" ? context : null; }
  #|     addEventListener() {}
  #|   }
  #|   const canvas = withCanvas ? new TestCanvas() : null;
  #|   Object.defineProperty(globalThis, "HTMLCanvasElement", {
  #|     configurable: true,
  #|     writable: true,
  #|     value: TestCanvas,
  #|   });
  #|   Object.defineProperty(globalThis, "CanvasRenderingContext2D", {
  #|     configurable: true,
  #|     writable: true,
  #|     value: TestContext,
  #|   });
  #|   Object.defineProperty(globalThis, "document", {
  #|     configurable: true,
  #|     writable: true,
  #|     value: {
  #|       getElementById(id) {
  #|         return id === "energy-valley-canvas" ? canvas : null;
  #|       },
  #|       querySelector() { return null; },
  #|       addEventListener() {},
  #|     },
  #|   });
  #|   Object.defineProperty(globalThis, "requestAnimationFrame", {
  #|     configurable: true,
  #|     writable: true,
  #|     value(callback) { callbacks.push(callback); return callbacks.length; },
  #|   });
  #|   Object.defineProperty(globalThis, "addEventListener", {
  #|     configurable: true,
  #|     writable: true,
  #|     value() {},
  #|   });
  #|   Object.defineProperty(globalThis, "__moontownGoldenValleyCamera", {
  #|     configurable: true,
  #|     writable: true,
  #|     value: { x: 1792, y: 3200, z: 0.5 },
  #|   });
  #|   Object.defineProperty(
  #|     globalThis,
  #|     "__moontownGoldenValleyCameraArtVersion",
  #|     { configurable: true, writable: true, value: 3 },
  #|   );
  #|   delete globalThis.__moontownGoldenValleyCanvasSchedule;
  #|   delete globalThis.__moontownGoldenValleyRender;
  #|   delete globalThis.__moontownGoldenValleyKeys;
  #|   delete globalThis.__moontownGoldenValleyAnimation;
  #|   delete globalThis.__moontownPlayerWalkKeys;
  #|   globalThis.__moontownCanvasFrameTimingTest = { descriptors, callbacks };
  #| }

///|
extern "js" fn canvas_frame_test_flush_next_animation_frame() -> Bool =
  #| () => {
  #|   const callback = globalThis.__moontownCanvasFrameTimingTest?.callbacks.shift();
  #|   if (!callback) return false;
  #|   callback(0);
  #|   return true;
  #| }

///|
extern "js" fn canvas_frame_test_pending_animation_frames() -> Int =
  #| () => globalThis.__moontownCanvasFrameTimingTest?.callbacks.length ?? 0

///|
extern "js" fn canvas_frame_test_remove_harness() -> Unit =
  #| () => {
  #|   const harness = globalThis.__moontownCanvasFrameTimingTest;
  #|   if (!harness) return;
  #|   for (const [name, descriptor] of harness.descriptors) {
  #|     if (descriptor) {
  #|       Object.defineProperty(globalThis, name, descriptor);
  #|     } else {
  #|       delete globalThis[name];
  #|     }
  #|   }
  #|   delete globalThis.__moontownCanvasFrameTimingTest;
  #| }

///|
fn canvas_frame_test_snapshot(
  tick : Int,
) -> @energy_valley_contract.TownSnapshot {
  let world = @energy_valley_contract.compiled_town_world(
    "moontown.test.canvas-frame.v1",
    ecosystem_contract_scoped_id("blueprint", "canvas-frame-test"),
    "canvas-frame-test",
    1,
    @energy_valley_contract.world_bounds(
      @energy_valley_contract.world_point(0.0, 0.0),
      @energy_valley_contract.world_point(1.0, 1.0),
    ),
    [],
    @energy_valley_contract.road_network([], [], []),
    [],
    [],
    [],
    [],
  )
  @energy_valley_contract.town_snapshot(world, tick, [], [])
}

///|
fn canvas_frame_test_view(tick : Int) -> TownCanvasViewState {
  {
    tick,
    weather: Sunny,
    hour: 12.0,
    metro_visible: false,
    selected_place_id: None,
    selected_actor_id: None,
    runtime_agent_interaction_enabled: false,
    follow_enabled: false,
    player_idle_position: None,
    player_motion: None,
  }
}

///|
test "Canvas accepts a semantic frame only after its scheduled draw succeeds" {
  let dispatch : Dispatch[Msg] = Emit(fn(_message) { @rabbita.none })
  let visible = canvas_frame_test_snapshot(1)
  let pending = canvas_frame_test_snapshot(2)
  golden_valley_accept_canvas_frame(visible)

  canvas_frame_test_install_harness(false)
  ignore(
    render_golden_valley_canvas(
      dispatch,
      pending,
      canvas_frame_test_view(pending.tick),
    ),
  )
  assert_eq(golden_valley_canvas_frame().unwrap().tick, visible.tick)
  assert_true(canvas_frame_test_flush_next_animation_frame())
  assert_eq(golden_valley_canvas_frame().unwrap().tick, visible.tick)
  canvas_frame_test_remove_harness()

  canvas_frame_test_install_harness(true)
  ignore(
    render_golden_valley_canvas(
      dispatch,
      pending,
      canvas_frame_test_view(pending.tick),
    ),
  )
  // Merely scheduling requestAnimationFrame does not change pointer truth.
  assert_eq(golden_valley_canvas_frame().unwrap().tick, visible.tick)
  assert_true(canvas_frame_test_flush_next_animation_frame())
  assert_eq(golden_valley_canvas_frame().unwrap().tick, pending.tick)
  canvas_frame_test_remove_harness()
  golden_valley_accept_canvas_frame(visible)
}

///|
test "Canvas scheduling retains only the latest semantic frame before paint" {
  let dispatch : Dispatch[Msg] = Emit(fn(_message) { @rabbita.none })
  let visible = canvas_frame_test_snapshot(10)
  let superseded = canvas_frame_test_snapshot(11)
  let latest = canvas_frame_test_snapshot(12)
  golden_valley_accept_canvas_frame(visible)
  canvas_frame_test_install_harness(true)
  ignore(
    render_golden_valley_canvas(
      dispatch,
      superseded,
      canvas_frame_test_view(superseded.tick),
    ),
  )
  ignore(
    render_golden_valley_canvas(
      dispatch,
      latest,
      canvas_frame_test_view(latest.tick),
    ),
  )
  assert_eq(canvas_frame_test_pending_animation_frames(), 1)
  assert_eq(golden_valley_canvas_frame().unwrap().tick, visible.tick)
  assert_true(canvas_frame_test_flush_next_animation_frame())
  assert_eq(golden_valley_canvas_frame().unwrap().tick, latest.tick)
  canvas_frame_test_remove_harness()
  golden_valley_accept_canvas_frame(visible)
}

///|
fn canvas_frame_page_test_player() -> PlayerAvatar {
  {
    name: "同页快照测试居民",
    persona: "researcher",
    color: 0,
    sprite_index: 0,
    title: "测试居民",
  }
}

///|
test "one page render threads the exact same TownSnapshot through its surfaces" {
  let base = {
    ..init_model(),
    tick: 18,
    player: Some(canvas_frame_page_test_player()),
    quest_done: town_quest_chain().map(quest => quest.id),
    energy_status_open: true,
  }
  let compiled = ecosystem_contract_town_snapshot(base, 20260727)
  assert_true(!compiled.active_signals().is_empty())
  assert_true(!compiled.active_presences().is_empty())
  let bridge = ecosystem_cached_world_snapshot(base, 20260727)
  let occupied = golden_valley_buildings(20260727).filter(building => {
    match ecosystem_canvas_place_for_building(bridge, building) {
      Some(place) =>
        !compiled.presences_at(ecosystem_contract_id(place.id)).is_empty()
      None => false
    }
  })
  assert_true(!occupied.is_empty())
  let model = { ..base, energy_selected_building: Some(occupied[0]) }
  let supplied = @energy_valley_contract.town_snapshot(
    compiled.world,
    compiled.tick,
    [],
    [],
  )
  let dispatch : Dispatch[Msg] = Emit(fn(_message) { @rabbita.none })
  canvas_frame_test_install_harness(false)
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_energy_valley_page_with_snapshot(dispatch, model, supplied),
    ),
  )
  canvas_frame_test_remove_harness()
  assert_true(
    html.contains(
      "统一语义快照 · 0 个有效信号 · 0 个在途/在场主体 · 0 条场所交换",
    ),
  )
  assert_true(
    html.contains(
      "此刻无人入内；到达与在场仅以语义快照为准。",
    ),
  )
}
