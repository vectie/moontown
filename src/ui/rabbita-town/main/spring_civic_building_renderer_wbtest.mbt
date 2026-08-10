///|
test "spring civic renderer binds all sixteen verified modular cutouts" {
  for
    module_key in [
      "resident-twins", "contest-express", "research-ai-agents", "social-square",
      "ai-garden", "physical-bridge", "town-shell", "policy-hall", "vitality-tower",
      "story-radar", "talent-avenue", "valley-market", "research-embodied-robotics",
      "research-opc", "research-llm-training", "research-ai-hardware",
    ] {
    let path = golden_spring_civic_building_asset_path(Some(module_key)).unwrap()
    assert_eq(
      path,
      "/tilemap/buildings/moontown-spring-civic-v1/\{module_key}.png",
    )
  }
  assert_eq(
    golden_spring_civic_building_asset_path(Some("book-town-shell")),
    Some("/tilemap/buildings/moontown-spring-civic-v1/town-shell.png"),
  )
  assert_eq(
    golden_spring_civic_building_asset_path(Some("wenyu-ai-garden")),
    Some("/tilemap/buildings/moontown-spring-civic-v1/ai-garden.png"),
  )
  assert_eq(
    golden_spring_civic_building_asset_path(Some("vitality-dashboard")),
    Some("/tilemap/buildings/moontown-spring-civic-v1/vitality-tower.png"),
  )
  assert_eq(
    golden_spring_civic_building_asset_path(Some("wenyu-broadcast-tower")),
    Some("/tilemap/buildings/moontown-spring-civic-v1/story-radar.png"),
  )
  assert_eq(
    golden_spring_civic_building_asset_path(Some("unknown-module")),
    None,
  )
  assert_eq(golden_spring_civic_building_asset_path(None), None)
  assert_true(
    (golden_spring_civic_building_top_y(400.0, 8.0, 6.0, 0.5) -
    186.66666666666666).abs() <
    0.000001,
  )
}

///|
test "spring authored sprite visibility uses square anchor and overscan bounds" {
  // (4 + 4) * 32 / 0.84 * 0.5 = 152.381 CSS px. With 32 px
  // overscan, the horizontal reach is 108.191 px; vertical reach is
  // 153.905 px up and 62.476 px down.
  assert_true(
    golden_spring_building_asset_visible(400.0, 300.0, 4.0, 4.0, 0.5, 800, 600),
  )
  assert_true(
    golden_spring_building_asset_visible(
      -108.19047619047619, 300.0, 4.0, 4.0, 0.5, 800, 600,
    ),
  )
  assert_true(
    !golden_spring_building_asset_visible(
      -108.191, 300.0, 4.0, 4.0, 0.5, 800, 600,
    ),
  )
  assert_true(
    golden_spring_building_asset_visible(
      908.1904761904761, 300.0, 4.0, 4.0, 0.5, 800, 600,
    ),
  )
  assert_true(
    !golden_spring_building_asset_visible(
      908.191, 300.0, 4.0, 4.0, 0.5, 800, 600,
    ),
  )
  assert_true(
    golden_spring_building_asset_visible(
      400.0, -62.476190476190474, 4.0, 4.0, 0.5, 800, 600,
    ),
  )
  assert_true(
    !golden_spring_building_asset_visible(
      400.0, -62.477, 4.0, 4.0, 0.5, 800, 600,
    ),
  )
  assert_true(
    golden_spring_building_asset_visible(
      400.0, 753.9047619047619, 4.0, 4.0, 0.5, 800, 600,
    ),
  )
  assert_true(
    !golden_spring_building_asset_visible(
      400.0, 753.905, 4.0, 4.0, 0.5, 800, 600,
    ),
  )
  assert_true(
    !golden_spring_building_asset_visible(400.0, 300.0, 4.0, 4.0, 0.0, 800, 600),
  )
  assert_true(
    !golden_spring_building_asset_visible(400.0, 300.0, 4.0, 4.0, 0.5, 0, 600),
  )
}

///|
test "live procedural map caps persistent work-status pins at three" {
  let selected = golden_status_pin_indices(
    [
      "running", "blocked", "assigned", "failed", "waiting_review", "completed",
      "blocked",
    ],
    ["0", "1", "2", "3", "4", "5", "6"],
  )
  assert_eq(selected, [1, 6, 3])
  assert_eq(
    golden_status_pin_indices(["running", "running", "running", "running"], [
      "5", "0", "3", "2",
    ]),
    [1, 3, 2],
  )
  assert_eq(golden_status_pin_indices(["", "completed"], ["0", "1"]), [1])
}

///|
extern "js" fn install_spring_civic_asset_cache_fixture() -> Unit =
  #| () => {
  #|   const loading = {
  #|     onload: () => {},
  #|     onerror: () => {},
  #|     removed: false,
  #|     removeAttribute(name) { if (name === "src") this.removed = true; },
  #|   };
  #|   const ready = {
  #|     onload: () => {},
  #|     onerror: () => {},
  #|     removed: false,
  #|     removeAttribute(name) { if (name === "src") this.removed = true; },
  #|   };
  #|   globalThis.__moontownSpringCivicAssetTestImages = { loading, ready };
  #|   globalThis.__moontownSpringCivicBuildingAssets = new Map([
  #|     ["loading.png", { image: loading, state: "loading" }],
  #|     ["ready.png", { image: ready, state: "ready" }],
  #|   ]);
  #|   globalThis.__moontownSpringCivicBuildingAssetClock = 7;
  #|   globalThis.__moontownSpringCivicBuildingAssetFrame = {
  #|     id: 3,
  #|     active: true,
  #|   };
  #|   globalThis.__moontownSpringCivicBuildingAssetRepaint = {
  #|     pending: false,
  #|     raf: 0,
  #|   };
  #| }

///|
extern "js" fn spring_civic_asset_cache_fixture_released() -> Bool =
  #| () => {
  #|   const fixture = globalThis.__moontownSpringCivicAssetTestImages;
  #|   const released = !globalThis.__moontownSpringCivicBuildingAssets &&
  #|     !Object.prototype.hasOwnProperty.call(
  #|       globalThis,
  #|       "__moontownSpringCivicBuildingAssetClock",
  #|     ) &&
  #|     !globalThis.__moontownSpringCivicBuildingAssetFrame &&
  #|     !globalThis.__moontownSpringCivicBuildingAssetRepaint &&
  #|     fixture?.loading?.onload === null &&
  #|     fixture?.loading?.onerror === null &&
  #|     fixture?.loading?.removed === true &&
  #|     fixture?.ready?.onload === null &&
  #|     fixture?.ready?.onerror === null &&
  #|     fixture?.ready?.removed === false;
  #|   delete globalThis.__moontownSpringCivicAssetTestImages;
  #|   return Boolean(released);
  #| }

///|
test "spring civic image cache releases listeners and loading requests" {
  install_spring_civic_asset_cache_fixture()
  golden_release_spring_civic_building_assets()
  assert_true(spring_civic_asset_cache_fixture_released())
}

///|
extern "js" fn install_spring_asset_frame_overflow_fixture() -> Unit =
  #| () => {
  #|   globalThis.__moontownSpringCivicBuildingAssetFrame = {
  #|     id: Number.MAX_SAFE_INTEGER,
  #|     active: false,
  #|   };
  #| }

///|
extern "js" fn spring_asset_frame_overflow_fixture_reset() -> Bool =
  #| () => {
  #|   const frame = globalThis.__moontownSpringCivicBuildingAssetFrame;
  #|   return Boolean(frame?.id === 1 && frame?.active === false);
  #| }

///|
test "spring asset frame id resets before unsafe integer overflow" {
  install_spring_asset_frame_overflow_fixture()
  golden_begin_spring_civic_building_asset_frame()
  golden_end_spring_civic_building_asset_frame()
  let reset = spring_asset_frame_overflow_fixture_reset()
  golden_release_spring_civic_building_assets()
  assert_true(reset)
}

///|
extern "js" fn install_spring_building_asset_lru_fixture(
  oldest_state : String,
) -> @dom.CanvasRenderingContext2D =
  #| (oldestState) => {
  #|   const makeImage = () => ({
  #|     onload: () => {},
  #|     onerror: () => {},
  #|     removed: false,
  #|     removeAttribute(name) { if (name === "src") this.removed = true; },
  #|   });
  #|   const keepAliveImage = makeImage();
  #|   const victimImage = makeImage();
  #|   const keepAliveRecord = {
  #|     image: keepAliveImage,
  #|     state: "error",
  #|     lastUsed: 0,
  #|   };
  #|   const victimRecord = {
  #|     image: victimImage,
  #|     state: oldestState,
  #|     lastUsed: 1,
  #|   };
  #|   const records = [
  #|     ["keep-alive.png", keepAliveRecord],
  #|     ["victim.png", victimRecord],
  #|   ];
  #|   for (let index = 2; index < 48; index += 1) {
  #|     records.push([
  #|       `known-${index}.png`,
  #|       { image: makeImage(), state: "error", lastUsed: index },
  #|     ]);
  #|   }
  #|   globalThis.__moontownSpringCivicBuildingAssets = new Map(records);
  #|   globalThis.__moontownSpringCivicBuildingAssetClock = 48;
  #|   delete globalThis.__moontownSpringCivicBuildingAssetFrame;
  #|   delete globalThis.__moontownSpringCivicBuildingAssetRepaint;
  #|   const hadImage = Object.prototype.hasOwnProperty.call(globalThis, "Image");
  #|   const previousImage = globalThis.Image;
  #|   let constructed = 0;
  #|   globalThis.Image = function SpringAssetLruProbe() {
  #|     constructed += 1;
  #|     this.naturalWidth = 0;
  #|     this.naturalHeight = 0;
  #|     this.removed = false;
  #|     this.removeAttribute = function(name) {
  #|       if (name === "src") this.removed = true;
  #|     };
  #|   };
  #|   globalThis.__moontownSpringAssetLruFixture = {
  #|     constructed: () => constructed,
  #|     hadImage,
  #|     previousImage,
  #|     keepAliveRecord,
  #|     victimImage,
  #|     victimRecord,
  #|   };
  #|   return {};
  #| }

///|
extern "js" fn spring_building_asset_lru_fixture_evicted() -> Bool =
  #| () => {
  #|   const fixture = globalThis.__moontownSpringAssetLruFixture;
  #|   const cache = globalThis.__moontownSpringCivicBuildingAssets;
  #|   const replacement = cache?.get("replacement.png");
  #|   const evicted = cache?.size === 48 &&
  #|     cache.has("keep-alive.png") &&
  #|     !cache.has("victim.png") &&
  #|     replacement?.state === "loading" &&
  #|     replacement?.lastUsed === 50 &&
  #|     fixture?.keepAliveRecord?.lastUsed === 49 &&
  #|     fixture?.constructed() === 1 &&
  #|     fixture?.victimRecord?.image === null &&
  #|     fixture?.victimImage?.onload === null &&
  #|     fixture?.victimImage?.onerror === null &&
  #|     fixture?.victimImage?.removed === false;
  #|   if (fixture?.hadImage) globalThis.Image = fixture.previousImage;
  #|   else delete globalThis.Image;
  #|   delete globalThis.__moontownSpringAssetLruFixture;
  #|   return Boolean(evicted);
  #| }

///|
test "spring building image cache evicts the oldest ready or error record" {
  for oldest_state in ["ready", "error"] {
    let context = install_spring_building_asset_lru_fixture(oldest_state)
    let touched_falls_back = !golden_draw_spring_civic_building_asset(
      context, "keep-alive.png", 0.0, 0.0, 1.0, 1.0, 1.0, false,
    )
    let replacement_falls_back = !golden_draw_spring_civic_building_asset(
      context, "replacement.png", 0.0, 0.0, 1.0, 1.0, 1.0, false,
    )
    let evicted = spring_building_asset_lru_fixture_evicted()
    golden_release_spring_civic_building_assets()
    assert_true(touched_falls_back)
    assert_true(replacement_falls_back)
    assert_true(evicted)
  }
}

///|
extern "js" fn install_all_loading_spring_building_asset_cache_fixture() -> @dom.CanvasRenderingContext2D =
  #| () => {
  #|   const records = [];
  #|   for (let index = 0; index < 48; index += 1) {
  #|     const image = {
  #|       onload: () => {},
  #|       onerror: () => {},
  #|       removeAttribute() {},
  #|     };
  #|     records.push([
  #|       `loading-${index}.png`,
  #|       { image, state: "loading", lastUsed: index },
  #|     ]);
  #|   }
  #|   globalThis.__moontownSpringCivicBuildingAssets = new Map(records);
  #|   globalThis.__moontownSpringCivicBuildingAssetClock = 48;
  #|   delete globalThis.__moontownSpringCivicBuildingAssetFrame;
  #|   delete globalThis.__moontownSpringCivicBuildingAssetRepaint;
  #|   const hadImage = Object.prototype.hasOwnProperty.call(globalThis, "Image");
  #|   const previousImage = globalThis.Image;
  #|   let constructed = 0;
  #|   globalThis.Image = function SpringAssetOverflowProbe() {
  #|     constructed += 1;
  #|   };
  #|   globalThis.__moontownSpringAssetAllLoadingFixture = {
  #|     constructed: () => constructed,
  #|     hadImage,
  #|     previousImage,
  #|   };
  #|   return {};
  #| }

///|
extern "js" fn all_loading_spring_building_asset_cache_fixture_unchanged() -> Bool =
  #| () => {
  #|   const fixture = globalThis.__moontownSpringAssetAllLoadingFixture;
  #|   const cache = globalThis.__moontownSpringCivicBuildingAssets;
  #|   const unchanged = cache?.size === 48 &&
  #|     !cache.has("replacement.png") &&
  #|     fixture?.constructed() === 0 &&
  #|     globalThis.__moontownSpringCivicBuildingAssetClock === 49;
  #|   if (fixture?.hadImage) globalThis.Image = fixture.previousImage;
  #|   else delete globalThis.Image;
  #|   delete globalThis.__moontownSpringAssetAllLoadingFixture;
  #|   return Boolean(unchanged);
  #| }

///|
test "spring building image cache refuses a forty-ninth all-loading path" {
  let context = install_all_loading_spring_building_asset_cache_fixture()
  let refused = !golden_draw_spring_civic_building_asset(
    context, "replacement.png", 0.0, 0.0, 1.0, 1.0, 1.0, false,
  )
  let unchanged = all_loading_spring_building_asset_cache_fixture_unchanged()
  golden_release_spring_civic_building_assets()
  assert_true(refused)
  assert_true(unchanged)
}

///|
extern "js" fn install_protected_spring_building_asset_cache_fixture() -> @dom.CanvasRenderingContext2D =
  #| () => {
  #|   const records = [];
  #|   let draws = 0;
  #|   for (let index = 0; index < 48; index += 1) {
  #|     const image = {
  #|       naturalWidth: 64,
  #|       naturalHeight: 64,
  #|       onload: null,
  #|       onerror: null,
  #|       removeAttribute() {},
  #|     };
  #|     records.push([
  #|       `protected-${index}.png`,
  #|       {
  #|         image,
  #|         state: index % 2 === 0 ? "ready" : "error",
  #|         lastUsed: index,
  #|         frameId: 0,
  #|       },
  #|     ]);
  #|   }
  #|   globalThis.__moontownSpringCivicBuildingAssets = new Map(records);
  #|   globalThis.__moontownSpringCivicBuildingAssetClock = 48;
  #|   delete globalThis.__moontownSpringCivicBuildingAssetFrame;
  #|   delete globalThis.__moontownSpringCivicBuildingAssetRepaint;
  #|   const hadImage = Object.prototype.hasOwnProperty.call(globalThis, "Image");
  #|   const previousImage = globalThis.Image;
  #|   let constructed = 0;
  #|   globalThis.Image = function SpringAssetProtectedProbe() {
  #|     constructed += 1;
  #|   };
  #|   globalThis.__moontownSpringAssetProtectedFixture = {
  #|     constructed: () => constructed,
  #|     draws: () => draws,
  #|     hadImage,
  #|     previousImage,
  #|   };
  #|   return {
  #|     save() {},
  #|     restore() {},
  #|     drawImage() { draws += 1; },
  #|   };
  #| }

///|
extern "js" fn protected_spring_building_asset_cache_fixture_unchanged() -> Bool =
  #| () => {
  #|   const fixture = globalThis.__moontownSpringAssetProtectedFixture;
  #|   const cache = globalThis.__moontownSpringCivicBuildingAssets;
  #|   const frame = globalThis.__moontownSpringCivicBuildingAssetFrame;
  #|   const unchanged = cache?.size === 48 &&
  #|     !cache.has("replacement.png") &&
  #|     fixture?.constructed() === 0 &&
  #|     fixture?.draws() === 24 &&
  #|     globalThis.__moontownSpringCivicBuildingAssetClock === 97 &&
  #|     frame?.active === false &&
  #|     Number.isSafeInteger(frame?.id) &&
  #|     frame.id > 0 &&
  #|     [...cache.values()].every(record => record.frameId === frame.id);
  #|   if (fixture?.hadImage) globalThis.Image = fixture.previousImage;
  #|   else delete globalThis.Image;
  #|   delete globalThis.__moontownSpringAssetProtectedFixture;
  #|   return Boolean(unchanged);
  #| }

///|
test "spring building image cache refuses a forty-ninth frame-protected path" {
  let context = install_protected_spring_building_asset_cache_fixture()
  golden_begin_spring_civic_building_asset_frame()
  let mut ready_draws = 0
  for index in 0..<48 {
    if golden_draw_spring_civic_building_asset(
        context,
        "protected-\{index}.png",
        0.0,
        0.0,
        1.0,
        1.0,
        1.0,
        false,
      ) {
      ready_draws += 1
    }
  }
  let refused = !golden_draw_spring_civic_building_asset(
    context, "replacement.png", 0.0, 0.0, 1.0, 1.0, 1.0, false,
  )
  golden_end_spring_civic_building_asset_frame()
  let unchanged = protected_spring_building_asset_cache_fixture_unchanged()
  golden_release_spring_civic_building_assets()
  assert_eq(ready_draws, 24)
  assert_true(refused)
  assert_true(unchanged)
}

///|
fn scan_spring_building_asset_world_fixture(
  context : @dom.CanvasRenderingContext2D,
  pan : Int,
) -> (Int, Int) {
  let styles = ["lowrise", "row", "block", "tower", "courtyard", "campus"]
  let mut admitted = 0
  let mut drawn = 0
  golden_begin_spring_civic_building_asset_frame()
  for index in 0..<60 {
    let sx = if index >= pan && index < pan + 48 { 100.0 } else { -500.0 }
    if golden_spring_building_asset_visible(sx, 100.0, 2.0, 2.0, 0.5, 800, 600) {
      admitted += 1
      let style = styles[index / 10]
      let asset_path = golden_spring_ambient_asset_path_for_variant(
        style,
        index % 10,
      ).unwrap()
      if golden_draw_spring_civic_building_asset(
          context, asset_path, sx, 100.0, 2.0, 2.0, 0.5, false,
        ) {
        drawn += 1
      }
    }
  }
  golden_end_spring_civic_building_asset_frame()
  (admitted, drawn)
}

///|
extern "js" fn install_spring_asset_world_scan_fixture() -> @dom.CanvasRenderingContext2D =
  #| () => {
  #|   const hadImage = Object.prototype.hasOwnProperty.call(globalThis, "Image");
  #|   const previousImage = globalThis.Image;
  #|   const hadRaf = Object.prototype.hasOwnProperty.call(
  #|     globalThis,
  #|     "requestAnimationFrame",
  #|   );
  #|   const previousRaf = globalThis.requestAnimationFrame;
  #|   const hadCancel = Object.prototype.hasOwnProperty.call(
  #|     globalThis,
  #|     "cancelAnimationFrame",
  #|   );
  #|   const previousCancel = globalThis.cancelAnimationFrame;
  #|   const hadRender = Object.prototype.hasOwnProperty.call(
  #|     globalThis,
  #|     "__moontownGoldenValleyRender",
  #|   );
  #|   const previousRender = globalThis.__moontownGoldenValleyRender;
  #|   const fixture = {
  #|     images: [],
  #|     rafs: new Map(),
  #|     nextRaf: 1,
  #|     constructed: 0,
  #|     draws: 0,
  #|     renderCalls: 0,
  #|     canceled: 0,
  #|     hadImage,
  #|     previousImage,
  #|     hadRaf,
  #|     previousRaf,
  #|     hadCancel,
  #|     previousCancel,
  #|     hadRender,
  #|     previousRender,
  #|   };
  #|   globalThis.__moontownSpringAssetWorldScanFixture = fixture;
  #|   globalThis.Image = function SpringAssetWorldScanImage() {
  #|     fixture.constructed += 1;
  #|     fixture.images.push(this);
  #|     this.naturalWidth = 64;
  #|     this.naturalHeight = 64;
  #|     this.complete = true;
  #|     this.removed = false;
  #|     this.removeAttribute = function(name) {
  #|       if (name === "src") this.removed = true;
  #|     };
  #|   };
  #|   globalThis.requestAnimationFrame = callback => {
  #|     const id = fixture.nextRaf++;
  #|     fixture.rafs.set(id, callback);
  #|     return id;
  #|   };
  #|   globalThis.cancelAnimationFrame = id => {
  #|     fixture.canceled += 1;
  #|     fixture.rafs.delete(id);
  #|   };
  #|   delete globalThis.__moontownSpringCivicBuildingAssets;
  #|   delete globalThis.__moontownSpringCivicBuildingAssetClock;
  #|   delete globalThis.__moontownSpringCivicBuildingAssetFrame;
  #|   delete globalThis.__moontownSpringCivicBuildingAssetRepaint;
  #|   return {
  #|     save() {},
  #|     restore() {},
  #|     drawImage() { fixture.draws += 1; },
  #|   };
  #| }

///|
extern "js" fn install_spring_asset_world_scan_render(
  callback : () -> Unit,
) -> Unit =
  #| callback => {
  #|   const fixture = globalThis.__moontownSpringAssetWorldScanFixture;
  #|   globalThis.__moontownGoldenValleyRender = () => {
  #|     fixture.renderCalls += 1;
  #|     callback();
  #|   };
  #| }

///|
extern "js" fn complete_spring_asset_world_scan_images() -> Unit =
  #| () => {
  #|   const fixture = globalThis.__moontownSpringAssetWorldScanFixture;
  #|   for (const [index, image] of fixture.images.slice().entries()) {
  #|     if (index === 0) image.onerror?.();
  #|     else image.onload?.();
  #|   }
  #| }

///|
extern "js" fn spring_asset_world_scan_batch_coalesced() -> Bool =
  #| () => {
  #|   const fixture = globalThis.__moontownSpringAssetWorldScanFixture;
  #|   const cache = globalThis.__moontownSpringCivicBuildingAssets;
  #|   return Boolean(
  #|     fixture?.constructed === 48 &&
  #|     fixture?.draws === 0 &&
  #|     fixture?.renderCalls === 0 &&
  #|     fixture?.rafs.size === 1 &&
  #|     cache?.size === 48 &&
  #|     [...cache.values()].filter(record => record.state === "ready").length === 47 &&
  #|     [...cache.values()].filter(record => record.state === "error").length === 1
  #|   );
  #| }

///|
extern "js" fn flush_spring_asset_world_scan_repaint() -> Unit =
  #| () => {
  #|   const fixture = globalThis.__moontownSpringAssetWorldScanFixture;
  #|   const next = fixture.rafs.entries().next().value;
  #|   if (!next) return;
  #|   fixture.rafs.delete(next[0]);
  #|   next[1](16);
  #| }

///|
extern "js" fn spring_asset_world_scan_settled() -> Bool =
  #| () => {
  #|   const fixture = globalThis.__moontownSpringAssetWorldScanFixture;
  #|   const cache = globalThis.__moontownSpringCivicBuildingAssets;
  #|   return Boolean(
  #|     fixture?.constructed === 48 &&
  #|     fixture?.draws === 47 &&
  #|     fixture?.renderCalls === 1 &&
  #|     fixture?.rafs.size === 0 &&
  #|     cache?.size === 48 &&
  #|     [...cache.values()].filter(record => record.state === "ready").length === 47 &&
  #|     [...cache.values()].filter(record => record.state === "error").length === 1
  #|   );
  #| }

///|
extern "js" fn spring_asset_world_scan_panned() -> Bool =
  #| () => {
  #|   const fixture = globalThis.__moontownSpringAssetWorldScanFixture;
  #|   const cache = globalThis.__moontownSpringCivicBuildingAssets;
  #|   let protectedVisibleRemain = true;
  #|   for (let index = 1; index < 48; index += 1) {
  #|     const style = [
  #|       "lowrise", "row", "block", "tower", "courtyard", "campus",
  #|     ][Math.floor(index / 10)];
  #|     const path =
  #|       `/tilemap/buildings/moontown-spring-ambient-v1/${style}-${index % 10}.webp`;
  #|     if (!cache?.has(path)) protectedVisibleRemain = false;
  #|   }
  #|   return Boolean(
  #|     fixture?.constructed === 49 &&
  #|     fixture?.draws === 94 &&
  #|     cache?.size === 48 &&
  #|     !cache.has(
  #|       "/tilemap/buildings/moontown-spring-ambient-v1/lowrise-0.webp",
  #|     ) &&
  #|     cache.has(
  #|       "/tilemap/buildings/moontown-spring-ambient-v1/courtyard-8.webp",
  #|     ) &&
  #|     protectedVisibleRemain
  #|   );
  #| }

///|
extern "js" fn complete_latest_spring_asset_world_scan_image() -> Unit =
  #| () => {
  #|   const fixture = globalThis.__moontownSpringAssetWorldScanFixture;
  #|   const latest = fixture?.images[fixture.images.length - 1];
  #|   latest?.onload?.();
  #| }

///|
extern "js" fn spring_asset_world_scan_repaint_pending() -> Bool =
  #| () => {
  #|   const fixture = globalThis.__moontownSpringAssetWorldScanFixture;
  #|   const repaint = globalThis.__moontownSpringCivicBuildingAssetRepaint;
  #|   return Boolean(
  #|     fixture?.rafs.size === 1 && repaint?.pending && repaint?.raf
  #|   );
  #| }

///|
extern "js" fn spring_asset_world_scan_repaint_absorbed() -> Bool =
  #| () => {
  #|   const fixture = globalThis.__moontownSpringAssetWorldScanFixture;
  #|   const repaint = globalThis.__moontownSpringCivicBuildingAssetRepaint;
  #|   return Boolean(
  #|     fixture?.rafs.size === 0 &&
  #|     fixture?.canceled === 1 &&
  #|     fixture?.renderCalls === 1 &&
  #|     repaint?.pending === false &&
  #|     repaint?.raf === 0
  #|   );
  #| }

///|
extern "js" fn cleanup_spring_asset_world_scan_fixture() -> Bool =
  #| () => {
  #|   const fixture = globalThis.__moontownSpringAssetWorldScanFixture;
  #|   const released = !globalThis.__moontownSpringCivicBuildingAssets &&
  #|     !globalThis.__moontownSpringCivicBuildingAssetClock &&
  #|     !globalThis.__moontownSpringCivicBuildingAssetFrame &&
  #|     !globalThis.__moontownSpringCivicBuildingAssetRepaint;
  #|   if (fixture?.hadImage) globalThis.Image = fixture.previousImage;
  #|   else delete globalThis.Image;
  #|   if (fixture?.hadRaf) {
  #|     globalThis.requestAnimationFrame = fixture.previousRaf;
  #|   } else delete globalThis.requestAnimationFrame;
  #|   if (fixture?.hadCancel) {
  #|     globalThis.cancelAnimationFrame = fixture.previousCancel;
  #|   } else delete globalThis.cancelAnimationFrame;
  #|   if (fixture?.hadRender) {
  #|     globalThis.__moontownGoldenValleyRender = fixture.previousRender;
  #|   } else delete globalThis.__moontownGoldenValleyRender;
  #|   delete globalThis.__moontownSpringAssetWorldScanFixture;
  #|   return Boolean(released);
  #| }

///|
test "spring asset cache settles a viewport-limited world beyond capacity" {
  let context = install_spring_asset_world_scan_fixture()
  let first_frame = scan_spring_building_asset_world_fixture(context, 0)
  install_spring_asset_world_scan_render(() => {
    let _ = scan_spring_building_asset_world_fixture(context, 0)
  })
  complete_spring_asset_world_scan_images()
  let coalesced = spring_asset_world_scan_batch_coalesced()
  flush_spring_asset_world_scan_repaint()
  let settled = spring_asset_world_scan_settled()
  let panned_frame = scan_spring_building_asset_world_fixture(context, 1)
  let panned = spring_asset_world_scan_panned()
  complete_latest_spring_asset_world_scan_image()
  let repaint_pending = spring_asset_world_scan_repaint_pending()
  golden_begin_spring_civic_building_asset_frame()
  golden_end_spring_civic_building_asset_frame()
  let repaint_absorbed = spring_asset_world_scan_repaint_absorbed()
  golden_release_spring_civic_building_assets()
  let released = cleanup_spring_asset_world_scan_fixture()
  assert_eq(first_frame, (48, 0))
  assert_true(coalesced)
  assert_true(settled)
  assert_eq(panned_frame, (48, 47))
  assert_true(panned)
  assert_true(repaint_pending)
  assert_true(repaint_absorbed)
  assert_true(released)
}
