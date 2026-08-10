///|
/// Optional authored skins for the sixteen canonical civic modules. These paths
/// never replace semantic geometry: the live TownCanvasBuilding remains the
/// sole source of placement, depth, selection, and hit authority.
fn golden_spring_civic_building_asset_path(module_key : String?) -> String? {
  match module_key {
    Some(raw_key) =>
      match normalize_module_binding_key(raw_key) {
        "resident-twins" =>
          Some("/tilemap/buildings/moontown-spring-civic-v1/resident-twins.png")
        "contest-express" =>
          Some(
            "/tilemap/buildings/moontown-spring-civic-v1/contest-express.png",
          )
        "research-ai-agents" =>
          Some(
            "/tilemap/buildings/moontown-spring-civic-v1/research-ai-agents.png",
          )
        "social-square" =>
          Some("/tilemap/buildings/moontown-spring-civic-v1/social-square.png")
        "ai-garden" =>
          Some("/tilemap/buildings/moontown-spring-civic-v1/ai-garden.png")
        "physical-bridge" =>
          Some(
            "/tilemap/buildings/moontown-spring-civic-v1/physical-bridge.png",
          )
        "town-shell" =>
          Some("/tilemap/buildings/moontown-spring-civic-v1/town-shell.png")
        "policy-hall" =>
          Some("/tilemap/buildings/moontown-spring-civic-v1/policy-hall.png")
        "vitality-tower" | "vitality-dashboard" =>
          Some("/tilemap/buildings/moontown-spring-civic-v1/vitality-tower.png")
        "story-radar" | "broadcast-tower" =>
          Some("/tilemap/buildings/moontown-spring-civic-v1/story-radar.png")
        "talent-avenue" =>
          Some("/tilemap/buildings/moontown-spring-civic-v1/talent-avenue.png")
        "valley-market" =>
          Some("/tilemap/buildings/moontown-spring-civic-v1/valley-market.png")
        "research-embodied-robotics" =>
          Some(
            "/tilemap/buildings/moontown-spring-civic-v1/research-embodied-robotics.png",
          )
        "research-opc" =>
          Some("/tilemap/buildings/moontown-spring-civic-v1/research-opc.png")
        "research-llm-training" =>
          Some(
            "/tilemap/buildings/moontown-spring-civic-v1/research-llm-training.png",
          )
        "research-ai-hardware" =>
          Some(
            "/tilemap/buildings/moontown-spring-civic-v1/research-ai-hardware.png",
          )
        _ => None
      }
    None => None
  }
}

///|
/// Both normalized spring packs use y=0.80 as their semantic ground anchor.
/// Their widest verified opaque silhouettes occupy at most 0.84 of the square,
/// so the complete visible building—not only its narrower semantic base—fits
/// the projected footprint diamond. This prevents adjacent legal lots from
/// visually merging while preserving their world geometry and depth order.
fn golden_spring_building_sprite_size(
  width : Double,
  depth : Double,
  zoom : Double,
) -> Double {
  (width + depth) * 32.0 * zoom / 0.84
}

///|
fn golden_spring_civic_building_top_y(
  ground_y : Double,
  width : Double,
  depth : Double,
  zoom : Double,
) -> Double {
  ground_y - golden_spring_building_sprite_size(width, depth, zoom) * 0.8
}

///|
/// Conservatively admit an authored square cutout only when its projected
/// bounds can affect this viewport. Runtime skins are normalized to a square,
/// anchored at (0.50, 0.80), and sized from the same verified 0.84 opaque-span
/// contract used by the draw path. A fixed overscan prevents edge popping
/// without admitting the whole offscreen world into the decoded-image cache.
fn golden_spring_building_asset_visible(
  sx : Double,
  sy : Double,
  width : Double,
  depth : Double,
  zoom : Double,
  viewport_width : Int,
  viewport_height : Int,
) -> Bool {
  if width <= 0.0 ||
    depth <= 0.0 ||
    zoom <= 0.0 ||
    viewport_width <= 0 ||
    viewport_height <= 0 {
    return false
  }
  let sprite_size = golden_spring_building_sprite_size(width, depth, zoom)
  let overscan = 32.0
  let left = sx - sprite_size * 0.5 - overscan
  let right = sx + sprite_size * 0.5 + overscan
  let top = sy - sprite_size * 0.8 - overscan
  let bottom = sy + sprite_size * 0.2 + overscan
  right >= 0.0 &&
  left <= viewport_width.to_double() &&
  bottom >= 0.0 &&
  top <= viewport_height.to_double()
}

///|
/// Begin one synchronous Canvas paint. Records touched during this frame are
/// protected from LRU eviction until the matching end call. A normal animation
/// paint also absorbs any pending asset-ready repaint batch.
extern "js" fn golden_begin_spring_civic_building_asset_frame() -> Unit =
  #| () => {
  #|   let frame = globalThis.__moontownSpringCivicBuildingAssetFrame;
  #|   if (!frame) {
  #|     frame = { id: 0, active: false };
  #|     globalThis.__moontownSpringCivicBuildingAssetFrame = frame;
  #|   }
  #|   frame.id = Number.isSafeInteger(frame.id) &&
  #|     frame.id >= 0 &&
  #|     frame.id < Number.MAX_SAFE_INTEGER
  #|     ? frame.id + 1
  #|     : 1;
  #|   frame.active = true;
  #|   const repaint = globalThis.__moontownSpringCivicBuildingAssetRepaint;
  #|   if (repaint?.pending) {
  #|     if (repaint.raf) {
  #|       try { globalThis.cancelAnimationFrame?.(repaint.raf); } catch (_) {}
  #|     }
  #|     repaint.pending = false;
  #|     repaint.raf = 0;
  #|   }
  #| }

///|
extern "js" fn golden_end_spring_civic_building_asset_frame() -> Unit =
  #| () => {
  #|   const frame = globalThis.__moontownSpringCivicBuildingAssetFrame;
  #|   if (frame) frame.active = false;
  #| }

///|
/// Paint one ready modular cutout at its real projected footprint. Assets use
/// the pack contract's normalized ground-center anchor (0.50, 0.80) and a
/// canonical 0.84-wide visible-silhouette envelope. Returning false asks the caller to
/// render its complete procedural fallback for this frame.
extern "js" fn golden_draw_spring_civic_building_asset(
  context : @dom.CanvasRenderingContext2D,
  asset_path : String,
  sx : Double,
  sy : Double,
  width : Double,
  depth : Double,
  zoom : Double,
  selected : Bool,
) -> Bool =
  #| (context, assetPath, sx, sy, width, depth, zoom, selected) => {
  #|   if (typeof globalThis.Image !== "function") return false;
  #|   let cache = globalThis.__moontownSpringCivicBuildingAssets;
  #|   if (!cache) {
  #|     cache = new Map();
  #|     globalThis.__moontownSpringCivicBuildingAssets = cache;
  #|   }
  #|   let clock = globalThis.__moontownSpringCivicBuildingAssetClock;
  #|   if (!Number.isSafeInteger(clock) || clock < 0) clock = 0;
  #|   clock += 1;
  #|   globalThis.__moontownSpringCivicBuildingAssetClock = clock;
  #|   const frame = globalThis.__moontownSpringCivicBuildingAssetFrame;
  #|   const activeFrameId = frame?.active && Number.isSafeInteger(frame.id)
  #|     ? frame.id
  #|     : 0;
  #|   let record = cache.get(assetPath);
  #|   if (record) {
  #|     record.lastUsed = clock;
  #|     if (activeFrameId > 0) record.frameId = activeFrameId;
  #|   }
  #|   if (!record) {
  #|     // Ninety-six allowlisted paths exist, but decoded images are bounded
  #|     // to forty-eight. Never evict an in-flight request: its callbacks own
  #|     // the transition out of loading and remain safe until release.
  #|     while (cache.size >= 48) {
  #|       let oldestPath = null;
  #|       let oldestRecord = null;
  #|       let oldestLastUsed = Infinity;
  #|       for (const [cachedPath, candidate] of cache) {
  #|         if (candidate?.state === "loading" ||
  #|             (activeFrameId > 0 && candidate?.frameId === activeFrameId)) {
  #|           continue;
  #|         }
  #|         const lastUsed = Number.isFinite(candidate?.lastUsed)
  #|           ? candidate.lastUsed
  #|           : -Infinity;
  #|         if (oldestPath === null || lastUsed < oldestLastUsed) {
  #|           oldestPath = cachedPath;
  #|           oldestRecord = candidate;
  #|           oldestLastUsed = lastUsed;
  #|         }
  #|       }
  #|       // When every retained record is loading or protected by this paint,
  #|       // refuse allocation and let the procedural renderer own this frame.
  #|       if (oldestPath === null) return false;
  #|       const oldestImage = oldestRecord?.image;
  #|       if (oldestImage) {
  #|         oldestImage.onload = null;
  #|         oldestImage.onerror = null;
  #|         if (oldestRecord.state === "loading") {
  #|           try { oldestImage.removeAttribute?.("src"); } catch (_) {}
  #|         }
  #|       }
  #|       if (oldestRecord) oldestRecord.image = null;
  #|       cache.delete(oldestPath);
  #|     }
  #|     const image = new globalThis.Image();
  #|     record = {
  #|       image,
  #|       state: "loading",
  #|       lastUsed: clock,
  #|       frameId: activeFrameId,
  #|     };
  #|     cache.set(assetPath, record);
  #|     const scheduleRepaint = () => {
  #|       let repaint = globalThis.__moontownSpringCivicBuildingAssetRepaint;
  #|       if (!repaint) {
  #|         repaint = { pending: false, raf: 0 };
  #|         globalThis.__moontownSpringCivicBuildingAssetRepaint = repaint;
  #|       }
  #|       if (repaint.pending) return;
  #|       repaint.pending = true;
  #|       const run = () => {
  #|         if (globalThis.__moontownSpringCivicBuildingAssetRepaint !== repaint ||
  #|             !repaint.pending) return;
  #|         repaint.pending = false;
  #|         repaint.raf = 0;
  #|         globalThis.__moontownGoldenValleyRender?.();
  #|       };
  #|       if (typeof globalThis.requestAnimationFrame === "function") {
  #|         repaint.raf = globalThis.requestAnimationFrame(run);
  #|       } else if (typeof globalThis.queueMicrotask === "function") {
  #|         globalThis.queueMicrotask(run);
  #|       } else {
  #|         repaint.pending = false;
  #|         repaint.raf = 0;
  #|       }
  #|     };
  #|     image.decoding = "async";
  #|     image.onload = () => {
  #|       if (globalThis.__moontownSpringCivicBuildingAssets !== cache ||
  #|           cache.get(assetPath) !== record) return;
  #|       image.onload = null;
  #|       image.onerror = null;
  #|       record.state = image.naturalWidth > 0 && image.naturalHeight > 0
  #|         ? "ready"
  #|         : "error";
  #|       scheduleRepaint();
  #|     };
  #|     image.onerror = () => {
  #|       if (globalThis.__moontownSpringCivicBuildingAssets !== cache ||
  #|           cache.get(assetPath) !== record) return;
  #|       image.onload = null;
  #|       image.onerror = null;
  #|       record.state = "error";
  #|       scheduleRepaint();
  #|     };
  #|     image.src = assetPath;
  #|     return false;
  #|   }
  #|   const image = record.image;
  #|   if (record.state !== "ready" || !image?.naturalWidth ||
  #|       !image?.naturalHeight) return false;
  #|   // The live footprint sets scale; sprite pixels never set world size.
  #|   const projectedFootprintWidth = (width + depth) * 32 * zoom;
  #|   const scale = projectedFootprintWidth / (image.naturalWidth * 0.84);
  #|   const drawWidth = image.naturalWidth * scale;
  #|   const drawHeight = image.naturalHeight * scale;
  #|   const drawX = sx - drawWidth * 0.5;
  #|   const drawY = sy - drawHeight * 0.8;
  #|   try {
  #|     context.save();
  #|     context.imageSmoothingEnabled = true;
  #|     context.imageSmoothingQuality = "high";
  #|     context.drawImage(image, drawX, drawY, drawWidth, drawHeight);
  #|     context.restore();
  #|   } catch (_) {
  #|     record.state = "error";
  #|     try { context.restore(); } catch (_) {}
  #|     return false;
  #|   }
  #|   if (selected) {
  #|     const halfWidth = 16 * zoom;
  #|     const halfHeight = 8 * zoom;
  #|     const footprint = [
  #|       [sx + (depth - width) * halfWidth,
  #|        sy - (width + depth) * halfHeight],
  #|       [sx + (width + depth) * halfWidth,
  #|        sy + (width - depth) * halfHeight],
  #|       [sx + (width - depth) * halfWidth,
  #|        sy + (width + depth) * halfHeight],
  #|       [sx - (width + depth) * halfWidth,
  #|        sy + (depth - width) * halfHeight],
  #|     ];
  #|     context.save();
  #|     context.strokeStyle = "rgba(32,169,208,0.96)";
  #|     context.lineWidth = Math.max(1.5, 2.4 * zoom);
  #|     context.lineJoin = "round";
  #|     context.shadowColor = "rgba(32,169,208,0.34)";
  #|     context.shadowBlur = Math.max(2, 5 * zoom);
  #|     context.beginPath();
  #|     context.moveTo(footprint[0][0], footprint[0][1]);
  #|     for (let index = 1; index < footprint.length; index += 1) {
  #|       context.lineTo(footprint[index][0], footprint[index][1]);
  #|     }
  #|     context.closePath();
  #|     context.stroke();
  #|     context.restore();
  #|   }
  #|   return true;
  #| }

///|
/// Drop every image callback and cache reference when the Canvas owner stops.
/// The shared cache retains at most forty-eight of the sixteen landmark plus
/// eighty ambient paths while mounted; dynamic world content cannot grow the
/// decoded image set without bound.
extern "js" fn golden_release_spring_civic_building_assets() -> Unit =
  #| () => {
  #|   const repaint = globalThis.__moontownSpringCivicBuildingAssetRepaint;
  #|   if (repaint?.raf) {
  #|     try { globalThis.cancelAnimationFrame?.(repaint.raf); } catch (_) {}
  #|   }
  #|   const cache = globalThis.__moontownSpringCivicBuildingAssets;
  #|   if (cache) {
  #|     for (const record of cache.values()) {
  #|       const image = record?.image;
  #|       if (!image) continue;
  #|       image.onload = null;
  #|       image.onerror = null;
  #|       if (record.state === "loading") {
  #|         try { image.removeAttribute?.("src"); } catch (_) {}
  #|       }
  #|       record.image = null;
  #|     }
  #|     cache.clear();
  #|     if (globalThis.__moontownSpringCivicBuildingAssets === cache) {
  #|       delete globalThis.__moontownSpringCivicBuildingAssets;
  #|     }
  #|   }
  #|   delete globalThis.__moontownSpringCivicBuildingAssetClock;
  #|   delete globalThis.__moontownSpringCivicBuildingAssetFrame;
  #|   delete globalThis.__moontownSpringCivicBuildingAssetRepaint;
  #| }

///|
priv struct GoldenStatusPinCandidate {
  index : Int
  status : String
  tie_break : String
}

///|
/// Deterministically cap persistent building status pins at three. Runtime
/// severity wins; authored civic-role order (encoded by the caller) then gives
/// equal-severity candidates a stable tie break.
fn golden_status_pin_indices(
  statuses : ArrayView[String],
  tie_breaks : ArrayView[String],
) -> Array[Int] {
  let candidates : Array[GoldenStatusPinCandidate] = []
  for index, status in statuses {
    if !status.is_empty() {
      let tie_break = if index < tie_breaks.length() {
        tie_breaks[index]
      } else {
        "z:\{index}"
      }
      candidates.push({ index, status, tie_break })
    }
  }
  candidates.sort_by((left, right) => {
    let left_urgency = ecosystem_runtime_status_urgency(left.status)
    let right_urgency = ecosystem_runtime_status_urgency(right.status)
    if left_urgency != right_urgency {
      right_urgency - left_urgency
    } else {
      let by_tie_break = left.tie_break.compare(right.tie_break)
      if by_tie_break != 0 {
        by_tie_break
      } else {
        left.index.compare(right.index)
      }
    }
  })
  let shown = if candidates.length() < 3 { candidates.length() } else { 3 }
  let result : Array[Int] = []
  for index in 0..<shown {
    result.push(candidates[index].index)
  }
  result
}

///|
fn golden_status_pin_tie_break(
  module_key : String?,
  place_id : @energy_valley_contract.StableId,
) -> String {
  let role_rank = match module_key {
    Some(raw_key) =>
      match normalize_module_binding_key(raw_key) {
        "resident-twins" => "0"
        "contest-express" => "1"
        "research-ai-agents" => "2"
        "social-square" => "3"
        "ai-garden" => "4"
        "physical-bridge" => "5"
        "town-shell" => "6"
        _ => "7"
      }
    None => "7"
  }
  "\{role_rank}:\{place_id.to_string()}"
}
