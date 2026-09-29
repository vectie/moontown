# Preserved 3D studies → calibrated town map

2026-09-29. Work stays on `main`; this change does not commit or push.

## What is preserved

The original four exterior models, G3 interior, and five-scale data-center
models remain in `src/ui/landmark-studio/src/models`. No geometry, reference
image, original viewer, or material definition was replaced for map integration.
The map adapter consumes the same compiled MoonBit model data and generic
Three.js scene adapter. All three standalone viewers remain independently usable.

`scripts/package-town-landmarks.mbtx` copies the studio into generated product
assets. `scripts/build-rabbita-ui.sh` builds and packages it before the existing
hashed static-product assembly. Generated copies are ignored by Git; sources are
not. The asset manifest includes the nested pinned Three.js modules and license.
The product budget increases from 69 to 72 MiB (measured release: 71.2 MiB).

## Placement evidence and limits

| Asset | Geographic evidence | Registration |
| --- | --- | --- |
| 未来科学城路桥 | Saved OSM way 328596924, south node 3354163950, north node 3354163962 | Road-derived axis; WGS84 center 116.46230, 40.12282 |
| 未来科学城东路桥 | Saved OSM way 395533857, south node 3983803697, north node 3983803696 | Road-derived axis; WGS84 center 116.46967, 40.12128 |
| 未来中心 | Official project description and 英才南一街 address; Amap E-building listing | Approximate campus center 116.4701, 40.1147; not a surveyed footprint |
| 未来视界 | Official project/contact address 滨河大道3号院, Future Science City Group listing | Approximate campus center 116.4754, 40.1245; not a surveyed footprint |

Sources:

- [Future Center official project](https://www.kechuangfuwu.com/vue/parkService/project?id=31)
- [Future Vision official project](https://www.kechuangfuwu.com/vue/parkService/project?id=36)
- [Official Future Vision C-seat contact address](https://www.kechuangfuwu.com/vue/intoPark/contactUs)
- [Center E-building Amap listing](https://ditu.amap.com/place/B0JRSUEJZ9)
- [Group / Vision address Amap listing](https://www.amap.com/place/B0H37ZC4JI)
- Checked-in `docs/project/wenyu-lower-perspective.json`, retaining OSM way/node
  identity and the geometry used by the accepted unshifted road overlay.

The Amap coordinates are GCJ-02, not WGS84. Do not paste those values into OSM
registration. The campus anchors above are approximate inferred WGS84 centers,
not a claim of exact coordinate conversion or surveyed parcel boundaries. A
surveyed footprint/entrance remains a refinement gate. Bridge studies also retain
their original interpretive geometry and cropped 352 m decks; their source total
bridge lengths and main-span references are not interchangeable.

The G3 and data-center interiors are **design portals hosted at Future Center**.
This association is a product-design decision, not evidence that these exact
rooms, racks or machines exist beneath that real building.

## Projection and visual ownership

`main/town_landmarks.mbt` owns stable IDs, origins, local metre axes, footprint
reservations and navigation state. It calls the existing geographic registration
(`town_bearing_geo_to_ground`) without changing the terrain or calibrated roads.
Buildings use geographic east/south; bridges rotate those axes onto their source
road alignment. Vertical height stays vertical.

`web/town-map.js` is a browser rendering/UI boundary. It applies the MoonBit basis
to the original 3D geometry, renders transparent orthographic tiles once, then
releases its WebGL context. The normal Canvas2D town compositor draws those tiles
with the same camera/zoom as the ground. It does not rotate a pre-rendered picture.
Bridge deck height is normalized to the registered road plane; piers extend below
that plane. A separate near-side rail/rib render handles crossing-agent occlusion.
The study's rectangular terrain, roads, river and banks are not imported.

Only generated lots and generated public-realm pieces overlapping the new
footprints are suppressed, at draw time and only after all model tiles load.
UserDelta buildings/installations remain. No persisted town entity is deleted.
On renderer failure, the old map is retained and an error notice is shown.

## Walking and authority

The packaged graph has 788 vertices and 847 edges in the landmark district.
Positions come from the exact source `pathGrid` plus the accepted gentle
projection. Junctions use **shared OSM node IDs**, never screen proximity.
Motorways, proposed roads, tunnels, private/no-access and explicitly no-foot ways
are excluded. Bridges are retained as explicit graph edges. Included ordinary
roads are a navigation visualization, not certification of pedestrian safety or
legal access. OSM attribution/ODbL provenance remains in the generated JSON.

The new pure MoonBit `landmark_routes` package provides bounded endpoint snapping
and shortest paths. Unconnected routes fail closed instead of drawing a straight
line over water. A selected bridge can be traversed between its actual OSM way
endpoints. The local navigation agent moves at constant arc-length speed, supports
pause/resume/stop, and reports arrival. It is explicitly labeled as a simulation;
it does not claim that Codex/DeepSeek/GLM/Kimi performed a task.

Building journeys currently stop at a nearby road node (maximum four map units),
then expose an explicit design-space portal. An unverified door spur is not
silently declared walkable. The existing live `CompiledTownWorld` agent graph is
not replaced: consuming these landmark IDs/routes in authoritative work journeys
and verifying surveyed door connections are still required for live-agent use.

## Verification

- Original studio: 17 tests passed without changing original geometry.
- Routing/bearing regression suite: 9 tests passed, including shared-node
  shortest paths, disconnected crossings and existing geographic-bearing tests.
- Registration: four bounded anchors, non-degenerate bearings and bridge axis
  agreement with its source endpoints.
- Browser checks: model loading, Future Center focus, inter-campus route start,
  arch bridge start/arrival, wave bridge traversal with pause/resume controls,
  G3 interior rendering and return, data-center portal to board-level geometry
  with its planning report visible. The walking preview reuses the town's
  existing researcher sprite renderer and is labeled “导航预览”.
- Static assembly verifies all generated assets/hashes and release size.

Build from repository root:

```sh
./scripts/build-rabbita-ui.sh
```

The town opens preserved studios in a modal with an explicit return-to-town
button. Closing restores the existing town camera; no reload or new tab is needed.

## Map refinement — campus setbacks and bridge readability

The initial map review showed three presentation problems: approximate campus
centers put the western wings close to the street; the original 352 m study decks
looked undersized in the town; fine lattice and mullions aliased when a large
cached render was reduced directly to town zoom.

The source studies remain unchanged. The map-only calibration is now:

| Asset | Local change | Constraint |
| --- | --- | --- |
| Future Center | 40 nominal metres north, 20 west of the inferred campus anchor | Keep geographic bearing; move door and clearance together |
| Future Vision | 55 nominal metres north, 30 west | Set buildings back within the road block; not a surveyed correction |
| East bridge | Center 116.46990605, 40.1217185; bearing from the straight portion of way 395533857 | Center inferred between opposing carriageways; exclude curved southern approach from bearing |
| Arch bridge | Center 116.46234725, 40.12283585; bearing between the two inner way nodes | Main-span fit rather than approach-to-approach bearing |
| Both bridges | Length ×1.14, width ×1.28, vertical silhouette ×1.18 | Presentation scale only, deck still on the registered road plane |

The local-metre offsets use the existing calibrated geographic basis; they are
not raw screen-pixel nudges or changes to the global map registration. The
nominal 263 × 151 m inner courtyard from each original study is retained to ground
the buildings. The much larger studio terrain, road rectangles and banks remain
excluded. Footprint reservations include the courtyards and bridge shoulders.

Bridge toes have short tapered, feathered shoulders (model X 168–204) to soften
the transition from the deck to the existing road. These are visual transitions,
not new graph edges. The original road SVG, terrain, graph nodes and 847 graph
edges are unchanged. Near-side bridge occlusion uses the same published enlarged
footprint as the map reservation rather than a separate hard-coded hit box.

Tiles now bake at up to 4× (2048 px cap), with progressive 2:1 downsample levels.
Canvas compositing chooses a level for the current zoom and backing-store scale,
explicitly enables high-quality smoothing, then restores the canvas state so
pixel-art characters keep their own rendering treatment. This addresses thin
detail shimmer without blurring the entire town or running continuous WebGL.

Regression coverage: 11 registration/bearing/routing tests, including coupled
door/setback movement, courtyard reservation, main-span axis and enlargement;
the unchanged original studio retains its 17 passing tests. Calibration is still
reference-led design fitting, not surveyed placement or an as-built bridge model.

Final browser checks: both campus setbacks/courtyard edges inspected at focus
zoom; full-town reduction inspected; Center → Vision reached arrival; wave bridge
reached arrival; arch bridge paused at 84% on the deck, resumed and reached
arrival. Original wave study still opens in the map portal. Browser error log was
empty; model/navigation readiness were `ready`, and `wenyuRiversideShiftsApplied`
remained `false`. Release assembly verified 303 files / 71.2 MiB. No commit or push.
