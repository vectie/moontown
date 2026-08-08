///|
extern "js" fn install_simulation_tick_lifecycle_harness() -> Unit =
  #| () => {
  #|   const names = [
  #|     "setTimeout", "clearTimeout", "__moontownSimulationTickLifecycle",
  #|   ];
  #|   const descriptors = new Map(names.map(name => [
  #|     name, Object.getOwnPropertyDescriptor(globalThis, name),
  #|   ]));
  #|   const harness = {
  #|     descriptors, active: new Map(), cancelled: [], nextId: 1,
  #|   };
  #|   globalThis.__moontownSimulationTickLifecycleHarness = harness;
  #|   Object.defineProperty(globalThis, "setTimeout", {
  #|     configurable: true,
  #|     writable: true,
  #|     value: callback => {
  #|       const id = harness.nextId++;
  #|       harness.active.set(id, callback);
  #|       return id;
  #|     },
  #|   });
  #|   Object.defineProperty(globalThis, "clearTimeout", {
  #|     configurable: true,
  #|     writable: true,
  #|     value: id => {
  #|       const callback = harness.active.get(id);
  #|       if (callback) harness.cancelled.push(callback);
  #|       harness.active.delete(id);
  #|     },
  #|   });
  #|   delete globalThis.__moontownSimulationTickLifecycle;
  #| }

///|
extern "js" fn simulation_tick_harness_active_count() -> Int =
  #| () => globalThis.__moontownSimulationTickLifecycleHarness?.active.size ?? 0

///|
extern "js" fn simulation_tick_harness_cancelled_count() -> Int =
  #| () => globalThis.__moontownSimulationTickLifecycleHarness?.cancelled.length ?? 0

///|
extern "js" fn simulation_tick_harness_fire_active() -> Unit =
  #| () => {
  #|   const harness = globalThis.__moontownSimulationTickLifecycleHarness;
  #|   const next = harness?.active.entries().next().value;
  #|   if (!next) return;
  #|   harness.active.delete(next[0]);
  #|   next[1]();
  #| }

///|
extern "js" fn simulation_tick_harness_fire_cancelled() -> Unit =
  #| () => {
  #|   const harness = globalThis.__moontownSimulationTickLifecycleHarness;
  #|   harness?.cancelled.shift()?.();
  #| }

///|
extern "js" fn restore_simulation_tick_lifecycle_harness() -> Unit =
  #| () => {
  #|   const harness = globalThis.__moontownSimulationTickLifecycleHarness;
  #|   if (!harness) return;
  #|   for (const [name, descriptor] of harness.descriptors) {
  #|     if (descriptor) Object.defineProperty(globalThis, name, descriptor);
  #|     else delete globalThis[name];
  #|   }
  #|   delete globalThis.__moontownSimulationTickLifecycleHarness;
  #| }

///|
test "simulation tick lifecycle coalesces and invalidates cancelled callbacks" {
  install_simulation_tick_lifecycle_harness()
  let delivered : Array[String] = []
  browser_schedule_simulation_tick(fn() { delivered.push("first") })
  browser_schedule_simulation_tick(fn() { delivered.push("latest") })
  assert_eq(simulation_tick_harness_active_count(), 1)
  simulation_tick_harness_fire_active()
  assert_eq(delivered, ["latest"])
  assert_eq(simulation_tick_harness_active_count(), 0)

  browser_schedule_simulation_tick(fn() { delivered.push("stale") })
  browser_cancel_simulation_tick()
  assert_eq(simulation_tick_harness_active_count(), 0)
  assert_eq(simulation_tick_harness_cancelled_count(), 1)
  browser_schedule_simulation_tick(fn() { delivered.push("resumed") })
  simulation_tick_harness_fire_cancelled()
  assert_eq(delivered, ["latest"])
  assert_eq(simulation_tick_harness_active_count(), 1)
  simulation_tick_harness_fire_active()
  assert_eq(delivered, ["latest", "resumed"])
  assert_eq(simulation_tick_harness_active_count(), 0)
  restore_simulation_tick_lifecycle_harness()
}

///|
fn lifecycle_test_dispatch() -> Dispatch[Msg] {
  Emit(fn(_message) { @rabbita.none })
}

///|
test "a queued Tick cannot advance a paused model" {
  let model = { ..init_model(), paused: true, tick: 41 }
  let (_, next) = tick_update(lifecycle_test_dispatch(), model)
  assert_eq(next.tick, 41)
  assert_true(next.paused)
}

///|
extern "js" fn install_map_lab_canvas_lifecycle_harness() -> Unit =
  #| () => {
  #|   const names = [
  #|     "requestAnimationFrame", "cancelAnimationFrame", "document",
  #|     "__moontownMapLabCanvasLifecycle", "__moontownMapLabRender",
  #|     "__moontownMapLabObserver",
  #|   ];
  #|   const descriptors = new Map(names.map(name => [
  #|     name, Object.getOwnPropertyDescriptor(globalThis, name),
  #|   ]));
  #|   const canvas = {
  #|     width: 2048, height: 1024, clientWidth: 1024, clientHeight: 512,
  #|   };
  #|   const harness = { descriptors, canvas, active: new Map(), nextId: 1 };
  #|   globalThis.__moontownMapLabCanvasLifecycleHarness = harness;
  #|   Object.defineProperty(globalThis, "requestAnimationFrame", {
  #|     configurable: true,
  #|     writable: true,
  #|     value: callback => {
  #|       const id = harness.nextId++;
  #|       harness.active.set(id, callback);
  #|       return id;
  #|     },
  #|   });
  #|   Object.defineProperty(globalThis, "cancelAnimationFrame", {
  #|     configurable: true,
  #|     writable: true,
  #|     value: id => harness.active.delete(id),
  #|   });
  #|   Object.defineProperty(globalThis, "document", {
  #|     configurable: true,
  #|     writable: true,
  #|     value: {
  #|       getElementById: id => id === "map-lab-canvas" ? canvas : null,
  #|     },
  #|   });
  #|   delete globalThis.__moontownMapLabCanvasLifecycle;
  #|   delete globalThis.__moontownMapLabRender;
  #|   delete globalThis.__moontownMapLabObserver;
  #| }

///|
extern "js" fn map_lab_canvas_harness_active_count() -> Int =
  #| () => globalThis.__moontownMapLabCanvasLifecycleHarness?.active.size ?? 0

///|
extern "js" fn map_lab_canvas_harness_fire_active() -> Unit =
  #| () => {
  #|   const harness = globalThis.__moontownMapLabCanvasLifecycleHarness;
  #|   const next = harness?.active.entries().next().value;
  #|   if (!next) return;
  #|   harness.active.delete(next[0]);
  #|   next[1](16);
  #| }

///|
extern "js" fn map_lab_canvas_harness_retains_callback() -> Bool =
  #| () => typeof globalThis.__moontownMapLabRender === "function"

///|
extern "js" fn map_lab_canvas_harness_has_lifecycle() -> Bool =
  #| () => Boolean(globalThis.__moontownMapLabCanvasLifecycle)

///|
extern "js" fn map_lab_canvas_harness_backing_pixels() -> Int =
  #| () => {
  #|   const canvas = globalThis.__moontownMapLabCanvasLifecycleHarness?.canvas;
  #|   return (canvas?.width ?? 0) * (canvas?.height ?? 0);
  #| }

///|
extern "js" fn restore_map_lab_canvas_lifecycle_harness() -> Unit =
  #| () => {
  #|   const harness = globalThis.__moontownMapLabCanvasLifecycleHarness;
  #|   if (!harness) return;
  #|   for (const [name, descriptor] of harness.descriptors) {
  #|     if (descriptor) Object.defineProperty(globalThis, name, descriptor);
  #|     else delete globalThis[name];
  #|   }
  #|   delete globalThis.__moontownMapLabCanvasLifecycleHarness;
  #| }

///|
test "Map Lab coalesces paint and releases RAF callbacks and backing pixels" {
  install_map_lab_canvas_lifecycle_harness()
  let paints : Array[String] = []
  schedule_map_lab_canvas(fn() { paints.push("old") })
  schedule_map_lab_canvas(fn() { paints.push("latest") })
  assert_eq(map_lab_canvas_harness_active_count(), 1)
  map_lab_canvas_harness_fire_active()
  assert_eq(paints, ["latest"])

  install_map_lab_canvas_renderer(fn() { paints.push("observer") })
  schedule_map_lab_canvas(fn() { paints.push("pending") })
  assert_eq(map_lab_canvas_harness_active_count(), 2)
  assert_true(map_lab_canvas_harness_retains_callback())
  assert_true(map_lab_canvas_harness_has_lifecycle())
  assert_true(map_lab_canvas_harness_backing_pixels() > 0)
  stop_map_lab_canvas_renderer()
  assert_eq(map_lab_canvas_harness_active_count(), 0)
  assert_false(map_lab_canvas_harness_retains_callback())
  assert_false(map_lab_canvas_harness_has_lifecycle())
  assert_eq(map_lab_canvas_harness_backing_pixels(), 0)
  assert_eq(paints, ["latest"])
  restore_map_lab_canvas_lifecycle_harness()
}
