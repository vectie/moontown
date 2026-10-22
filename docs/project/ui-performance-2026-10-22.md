# Town UI performance — 2026-10-22

## Outcome

Preserved the existing town art, calibrated roads/landmark placement, complete
MoonBit architectural/interior/datacenter models, lighting, and map projection
resolution. No geometry decimation, lower DPR, replacement art, or navigation
graph simplification was used. The independent Three.js studios remain available.

Implemented on `main`, based on `4d39baf2`. Updated the local MoonDesk-managed
preview at `http://127.0.0.1:17842/index.html?landmarks=review`. No git commit or
push was requested for this change.

## Measurements

Same in-app browser, 1105 × 1043 CSS pixels, DPR 2, same local town/save and
whole-map camera. The baseline was rebuilt from the current source with the
same compiler and the same opt-in probe; the older deployed 7.3 MB bundle was
**not** used as the comparison baseline. The rebuilt baseline entry was
8,691,598 bytes. Raw observations: `ui-performance-2026-10-22.json`.

Three page openings per version; idle rendering sampled for 10 seconds starting
one second after both the road overlay and all landmarks report ready.

| Metric | Baseline | Optimized |
| --- | ---: | ---: |
| Map + all landmarks ready, median | 5.445 s | 3.376 s |
| Ready time, individual runs | 5.445 / 7.237 / 4.562 s | 3.540 / 3.376 / 2.936 s |
| Idle paint mean, median of runs | 70.76 ms | 12.90 ms |
| Idle actual paint rate, median | 8.26 fps | 27.15 fps |
| Idle rAF interval p95, median | 82.8 ms | 18.4 ms |
| Idle gaps above 50 ms, per run | 82 / 75 / 38 | 0 / 0 / 0 |
| Fixed-path pan paint rate, one 10 s sample | 11.74 fps | 55.26 fps |
| Fixed-path pan paint mean | 74.51 ms | 14.50 ms |
| Fixed-path pan rAF interval p95 | 149.3 ms | 33.3 ms |
| Fixed-path pan gaps above 50 ms | 118 | 6 |
| Main JS network body, full transfer | 8,691,598 bytes | 557,433 bytes (gzip) |
| Main JS decoded size | 8,691,598 bytes | 2,670,954 bytes |
| Complete distribution, including all 3D | 72.6 MiB | 70.2 MiB |

This is about 38% less ready-time, 82% less idle paint work, and 94% less main
bundle transfer. Idle animation intentionally retains the existing 30 fps energy
budget; interaction painting is not limited to that cadence.

### Limits of the comparison

- These are local repeat-navigation measurements, not a throttled Internet or
  guaranteed cold-cache benchmark. Baseline responses used `no-store`; optimized
  repeated resources revalidate with ETags. The first final optimized main bundle
  observation was a full 557,433-byte transfer, subsequent openings reused it.
- Same viewport and application data, but this was a shared development Mac,
  not an isolated benchmark machine. Background system load varied. Our own
  long-running test process was paused during final measurements and resumed
  afterward. Treat single-run numbers as observations, not universal promises.
- Paint timings measure CPU-side render invocation, not GPU completion. rAF
  intervals and >50 ms gaps provide a separate responsiveness signal.
- `canvasMs` in the raw data is canvas mount observation, **not** LCP/FCP. The
  table uses the stricter road-and-landmark-ready milestone instead.
- The fixed-path pan is identical in both versions: ten seconds of sinusoidal
  camera movement with 180 world-pixel amplitude. It is not a mouse-latency or
  every-possible-zoom benchmark. Native drag and close-up navigation were also
  checked visually, without claiming a separate measured speedup.
- Original 3D studios were functionally rechecked; no before/after standalone
  3D GPU-performance claim is made.

## What changed

1. **Static ground cache.** One bounded overscanned canvas reuses terrain,
   flowers, lots and calibrated roads during idle/pan. World identity, map key,
   viewport/DPR/zoom, landmark/road readiness and review mode invalidate it.
   Actors and depth-ordered buildings stay dynamic. At zoom ≥ 0.55 the existing
   animated-water path is retained. The extra surface is limited to 16M pixels.
2. **Original-model projections shipped as assets.** Four lossless PNG model
   renders plus two front bridge-rail occlusion layers replace six expensive
   WebGL bakes at each visit. Same original geometry, full affine camera,
   lighting, transparent edges, resolution and 2:1 mip filtering. A model/vendor/
   material/baker hash and exact registration matrices prevent stale reuse.
   Missing/stale/corrupt packs lazily invoke the original Three.js baker; its
   result is cached best-effort in browser storage. Full model sources remain
   unchanged under `src/ui/landmark-studio/src`.
3. **Startup critical path.** Preload the compiled MoonBit module while identity
   and map-reference inputs are prepared. Operational reports no longer block
   mount; the normal versioned MoonBit tick consumes their later updates.
   Account/pack UI adapters import after mount. Identity and workspace scope
   checks remain mandatory. Account requests now have bounded deadlines.
4. **Polling and fetch discipline.** Static reference URLs can revalidate;
   operational data stays `no-store`. Snapshot deadlines include response-body
   download. Concurrent polling batches coalesce and hidden tabs skip polling.
5. **Delivery.** Minify generated MoonBit as ESM, bundle CSS without changing
   rule order, generate deterministic gzip and SHA-256 ETag sidecars in MoonBit
   automation. The desktop server negotiates gzip, handles conditional GETs and
   keeps API/runtime/report data uncached. HTML remains uncached. Existing
   73 MiB release ceiling remains intact.
6. **Animation scheduling.** Use start-to-start/rAF timestamps so render work
   does not inadvertently extend every 30 fps interval. Suppress background
   map animation while a 3D studio dialog is open; closing restores it. Existing
   reduced-motion and hidden-tab behavior remains.

## Verification and reproduction

- `moon check`/release builds for the UI and desktop server succeeded.
- Public interfaces regenerated with `moon info`; no `.mbti` API changes.
- Relevant source/scripts formatted; unrelated formatter churn was excluded.
- Ground cache regression: 1 test (pan bounds, world/key changes, resize,
  close-up animation and memory cap).
- Desktop delivery: 3 tests (encoding negotiation, private-data cache boundary,
  weak/list ETag matching).
- Browser runtime/asset boundary: 15 tests, including stalled-body cancellation
  and presence of every projection layer.
- Landmark registration: 3 tests; original studio/model suite: 17 tests.
- Canvas lifecycle: 3 tests. Total focused checks above: **42 passed**.
- The complete UI package suite was also attempted but did not finish during
  this session. Its last progress output was `WORLD_HISTORICAL_REPLAY pairs=20`;
  the test process continued consuming CPU after resuming. It was stopped,
  rather than left running. No claim of full-suite success or attribution of
  that stall to a particular change is made. Log retained at
  `/tmp/moontown-performance.5tzMbO/ui-tests.log`.
- HTTP checked live: gzip `200`, matching ETag `304`, `gzip;q=0` identity
  response, and `secret-compute-room.json` still `Cache-Control: no-store`.
- Production manifest verifier passed: all hashes, assets and private-reference
  exclusions; 739 files, 70.2 MiB.
- Browser: packaged tile source confirmed; no Three.js/models requests in town
  startup. Architecture opens and drag-orbits; interior displays rooms/furniture;
  datacenter reaches PCB, plays network flows and opens capacity reports.
- Agent bridge journey completed (`landmarkRoute=arrived`, progress 1). Close
  zoom selected the animated-water path, and the packaged bridge-front layer
  remained available for correct actor occlusion.

To reproduce browser timings, open `index.html?landmarks=review&perf=1`, wait for
the automatic ten-second idle phase, then click **性能复测 · 10 秒平移**. The
local-only report is exposed in `document.documentElement.dataset.performanceReport`.
Normal visits do not run the probe or send telemetry.

Build prerequisites: `npm ci --prefix src/ui/rabbita-town` installs the pinned
esbuild dependency. The existing assembly entry invokes
`scripts/optimize-town-ui.mbtx`; standalone studios and their models remain
separately buildable.

Projection regeneration: build/package the original studio, open the local town
with `bake-tiles=1`, save the JSON from the `town-projection-export` DOM element,
then run `moon run scripts/import-town-projections.mbtx /absolute/export.json`.
Rebuild the production artifact. The importer preserves PNG bytes and requires
the four known landmark IDs. Do not hand-edit matrices or generate substitute art.

Local rollback copies of the previous service executable and UI are at
`/tmp/moontown-performance.5tzMbO/desktop_server-original` and
`/tmp/moontown-performance.5tzMbO/deployed-original`. The LaunchAgent configuration,
workspace, schedules and runtime data were not changed.
