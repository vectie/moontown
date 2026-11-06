# Deterministic frontier scenery

`world_frontier` is an opt-in MoonTown experiment, not geographic evidence or
an authorization source. Its current `city` generator clips globally planned
geographic-axis streets into 32-unit loading chunks, with bridge flags,
scenery lots with frontage, and plants. `generate` is the earlier experimental
chunk-centred generator, retained for comparison and regression tests.
Renderers and navigation adapters must use the same road geometry.

The seed and `version` define a layout. This prototype supports chunk
coordinates from -32768 through 32768; it does not yet implement Int64 world
coordinates, origin rebasing, city-scale hydrology, or edit persistence.
The UI adapter connects verified existing Wenyu road exits without editing
the core graph. Arrays are caller-readable
descriptors and must not be mutated after generation or while cached.

```mbt check
///|
test "neighboring chunks share road portals" {
  let west = @world_frontier.generate(20261028, 0, 0)
  let east = @world_frontier.generate(20261028, 1, 0)
  assert_eq(west.roads[23].b, east.roads[0].a)
  assert_eq(west.hub, { x: 14.0, y: 14.0, })
  assert_eq(@world_frontier.generate(20261028, 0, 0), west)
}

///|
test "one streaming window retains at most nine chunks" {
  let window = @world_frontier.Window::new(20261028)
  let _ = window.around({ x: 16.0, y: 16.0, })
  let _ = window.around({ x: -10000.0, y: 10000.0, })
  assert_eq(window.count(), 9)
  assert_eq(@world_frontier.coordinate(-0.1), -1)
}
```

The browser keeps a bounded viewport cache separate from the visitor's 3×3
navigation window and fixed exit chunks. Looking elsewhere cannot evict the
visitor's navigation. No complete exploration history is retained.

`generate(..., organic=true)` varies shared portals, street hierarchy and
district density. Its `arms` bit mask controls which of the four 12-segment
arms are active. `exterior` applies that mask, protects an authored `Rect`,
reserves gate clearances and derives water/bridges from inherited river mouths.
It is no longer the browser's active exterior generator.

```mbt check
///|
test "exterior leaves the authored core empty" {
  let core : @world_frontier.Rect = {
    min_x: 0,
    min_y: 0,
    max_x: 256,
    max_y: 144,
  }
  let base = @world_frontier.generate(20261028, 3, 2, organic=true)
  let c = @world_frontier.exterior(base, core, [], [])
  assert_eq(c.roads.length(), 0)
  assert_eq(c.lots.length(), 0)
}
```

`CityFrame` comes from the existing map's calibrated geographic east/south
axes. One street retains its global coordinate across loading chunks; street
spacing and hierarchy vary without adding per-chunk bends. `city_gate` joins
a verified exit to an actual street node. `Mouth.drift` preserves the incoming
river direction while `radius` retains its exact cross-boundary span.

```mbt check
///|
test "city planning preserves the authored core" {
  let frame : @world_frontier.CityFrame = {
    origin: { x: 128, y: 72, },
    east: { x: 1, y: 0.3, },
    south: { x: -0.3, y: 0.9, },
  }
  let core : @world_frontier.Rect = {
    min_x: 0,
    min_y: 0,
    max_x: 256,
    max_y: 144,
  }
  let c = @world_frontier.city(20261028, 3, 2, frame, core, [], [])
  assert_eq(c.roads.length(), 0)
  assert_eq(c.lots.length(), 0)
  assert_eq(c.plants.length(), 0)
}
```
