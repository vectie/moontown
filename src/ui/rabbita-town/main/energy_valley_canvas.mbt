///|
priv struct GoldenValleyCanvasAgent {
  x : Double
  y : Double
  sprite_path : String
  facing_left : Bool
  bob : Double
  work_color : String
  activity_glyph : String
  activity_label : String
  preview : Bool
  selected : Bool
}

///|
/// Renderer-only state paired with one immutable semantic snapshot. No world
/// generation, persistence ledger, or application Model crosses the Canvas
/// boundary.
priv struct TownCanvasViewState {
  tick : Int
  weather : EnergyWeather
  hour : Double
  metro_visible : Bool
  selected_place_id : @energy_valley_contract.StableId?
  selected_actor_id : @energy_valley_contract.StableId?
  runtime_agent_interaction_enabled : Bool
  follow_enabled : Bool
  player_idle_position : (Double, Double)?
  player_motion : PlayerMotion?
}

///|
extern "js" fn schedule_golden_valley_canvas(callback : () -> Unit) -> Unit =
  #| (callback) => globalThis.requestAnimationFrame(() => callback())

///|
extern "js" fn install_golden_valley_canvas_input(
  render_callback : () -> Unit,
) -> Unit =
  #| (renderCallback) => {
  #|   globalThis.__moontownGoldenValleyRender = renderCallback;
  #|   const canvas = globalThis.document?.getElementById("energy-valley-canvas");
  #|   if (!canvas || canvas.dataset.goldenInput === "1") return;
  #|   canvas.dataset.goldenInput = "1";
  #|   globalThis.__moontownGoldenValleyCamera ||= { x: 1792, y: 3200, z: 0.1 };
  #|   const camera = globalThis.__moontownGoldenValleyCamera;
  #|   let cameraDragging = false;
  #|   let painting = false;
  #|   let moved = false;
  #|   let lastX = 0;
  #|   let lastY = 0;
  #|   const inspectSelected = () =>
  #|     Boolean(globalThis.document?.querySelector(
  #|       'button[aria-label^="视察"][aria-pressed="true"]',
  #|     ));
  #|   const paintSelected = () =>
  #|     Boolean(globalThis.document?.querySelector(
  #|       'button[aria-label^="铺路"][aria-pressed="true"],' +
  #|       'button[aria-label^="造林"][aria-pressed="true"]',
  #|     ));
  #|   const rememberAction = event => {
  #|     const rect = canvas.getBoundingClientRect();
  #|     const x = Math.floor(event.clientX - rect.left);
  #|     const y = Math.floor(event.clientY - rect.top);
  #|     globalThis.__moontownGoldenValleyActionX = x;
  #|     globalThis.__moontownGoldenValleyActionY = y;
  #|   };
  #|   canvas.addEventListener("pointerdown", event => {
  #|     if (event.button === 0) rememberAction(event);
  #|     if (event.button === 1 || event.button === 2 ||
  #|         (event.button === 0 && inspectSelected())) {
  #|       cameraDragging = true;
  #|       moved = false;
  #|       lastX = event.clientX;
  #|       lastY = event.clientY;
  #|       canvas.setPointerCapture?.(event.pointerId);
  #|     } else if (event.button === 0) {
  #|       painting = paintSelected();
  #|       if (painting) canvas.setPointerCapture?.(event.pointerId);
  #|     }
  #|   });
  #|   canvas.addEventListener("pointermove", event => {
  #|     if (cameraDragging) {
  #|       if (Math.abs(event.clientX - lastX) > 2 ||
  #|           Math.abs(event.clientY - lastY) > 2) moved = true;
  #|       camera.x -= (event.clientX - lastX) / camera.z;
  #|       camera.y -= (event.clientY - lastY) / camera.z;
  #|       lastX = event.clientX;
  #|       lastY = event.clientY;
  #|       globalThis.__moontownGoldenValleyRender?.();
  #|     } else if (painting) {
  #|       rememberAction(event);
  #|       canvas.dispatchEvent(new MouseEvent("click", {
  #|         bubbles: true,
  #|         button: 0,
  #|         clientX: event.clientX,
  #|         clientY: event.clientY,
  #|       }));
  #|     }
  #|   });
  #|   const stop = event => {
  #|     cameraDragging = false;
  #|     painting = false;
  #|     canvas.releasePointerCapture?.(event.pointerId);
  #|   };
  #|   canvas.addEventListener("pointerup", event => {
  #|     stop(event);
  #|   });
  #|   canvas.addEventListener("pointercancel", stop);
  #|   canvas.addEventListener("click", event => {
  #|     if (moved) event.stopImmediatePropagation();
  #|     moved = false;
  #|   }, true);
  #|   canvas.addEventListener("contextmenu", event => event.preventDefault());
  #|   canvas.addEventListener("wheel", event => {
  #|     event.preventDefault();
  #|     const rect = canvas.getBoundingClientRect();
  #|     const mx = event.clientX - rect.left - rect.width / 2;
  #|     const my = event.clientY - rect.top - rect.height / 2;
  #|     const previous = camera.z;
  #|     camera.z = Math.min(1.8, Math.max(0.07, previous * (
  #|       event.deltaY < 0 ? 1.12 : 0.89
  #|     )));
  #|     camera.x += mx / previous - mx / camera.z;
  #|     camera.y += my / previous - my / camera.z;
  #|     globalThis.__moontownGoldenValleyRender?.();
  #|   }, { passive: false });
  #|   if (!globalThis.__moontownGoldenValleyKeys) {
  #|     globalThis.__moontownGoldenValleyKeys = true;
  #|     globalThis.addEventListener("keydown", event => {
  #|       const modal = globalThis.document?.querySelector(
  #|         '[role="dialog"][aria-modal="true"],[role="alertdialog"][aria-modal="true"]',
  #|       );
  #|       if (event.key === "Tab" && modal) {
  #|         const focusable = [...modal.querySelectorAll(
  #|           'button:not([disabled]),a[href],input:not([disabled]),textarea:not([disabled]),select:not([disabled]),[tabindex]:not([tabindex="-1"])',
  #|         )].filter(element => !element.hidden &&
  #|           element.getAttribute("aria-hidden") !== "true");
  #|         if (focusable.length > 0) {
  #|           const first = focusable[0];
  #|           const last = focusable[focusable.length - 1];
  #|           const active = globalThis.document?.activeElement;
  #|           if (!modal.contains(active)) {
  #|             event.preventDefault();
  #|             (event.shiftKey ? last : first).focus();
  #|           } else if (event.shiftKey && active === first) {
  #|             event.preventDefault();
  #|             last.focus();
  #|           } else if (!event.shiftKey && active === last) {
  #|             event.preventDefault();
  #|             first.focus();
  #|           }
  #|         }
  #|         return;
  #|       }
  #|       // A modal owns the keyboard while it is open. Tab stays inside the
  #|       // dialog above and Escape may close it below; every other town-wide
  #|       // shortcut (tools 1–8, Space, and future map keys) is suspended.
  #|       if (modal && event.key !== "Escape") return;
  #|       if (event.key === "Escape") {
  #|         const restoreLabel = globalThis.document?.querySelector(
  #|           "#town-chronicle-panel",
  #|         ) ? "小镇今日" : globalThis.document?.querySelector(
  #|           "#resident-explorer-panel,#resident-profile-panel",
  #|         ) ? "居民名册" : null;
  #|         globalThis.document?.querySelector(
  #|           'button[aria-label^="视察"]',
  #|         )?.click();
  #|         for (const label of [
  #|           "关闭指南",
  #|           "关闭能源谷运行看板",
  #|           "关闭建筑详情",
  #|           "关闭真实工作请求",
  #|           "关闭居民列表",
  #|           "关闭居民资料",
  #|           "关闭小镇今日",
  #|         ]) {
  #|           globalThis.document?.querySelector(
  #|             `button[aria-label="${label}"]`,
  #|           )?.click();
  #|         }
  #|         if (restoreLabel) globalThis.requestAnimationFrame(() => {
  #|           globalThis.document?.querySelector(
  #|             `button[aria-label="${restoreLabel}"]`,
  #|           )?.focus();
  #|         });
  #|         return;
  #|       }
  #|       const target = event.target;
  #|       if (target?.matches?.("input, textarea, select") ||
  #|           target?.isContentEditable) return;
  #|       if (event.key >= "1" && event.key <= "8") {
  #|         globalThis.document?.querySelector(
  #|           `button[aria-label$="快捷键 ${event.key}"]`,
  #|         )?.click();
  #|       } else if (event.key === " ") {
  #|         event.preventDefault();
  #|         globalThis.document?.querySelector(
  #|           'button[aria-label="暂停模拟"],button[aria-label="继续模拟"]',
  #|         )?.click();
  #|       }
  #|     });
  #|   }
  #|   if (!globalThis.__moontownGoldenValleyAnimation) {
  #|     globalThis.__moontownGoldenValleyAnimation = true;
  #|     const motion = globalThis.matchMedia?.(
  #|       "(prefers-reduced-motion: reduce)",
  #|     );
  #|     let lastPaint = 0;
  #|     const frame = timestamp => {
  #|       // The map remains interactive under reduced motion, but continuous
  #|       // canvas animation is suppressed. Normal motion is capped at 30fps.
  #|       if (!motion?.matches && !globalThis.document?.hidden &&
  #|           timestamp - lastPaint >= 33) {
  #|         lastPaint = timestamp;
  #|         globalThis.__moontownGoldenValleyRender?.();
  #|       }
  #|       globalThis.requestAnimationFrame(frame);
  #|     };
  #|     motion?.addEventListener?.("change", () => {
  #|       globalThis.__moontownGoldenValleyRender?.();
  #|     });
  #|     globalThis.requestAnimationFrame(frame);
  #|   }
  #| }

///|
extern "js" fn golden_valley_action_x() -> Int =
  #| () => globalThis.__moontownGoldenValleyActionX ?? 0

///|
extern "js" fn golden_valley_action_y() -> Int =
  #| () => globalThis.__moontownGoldenValleyActionY ?? 0

///|
extern "js" fn golden_valley_camera_x() -> Double =
  #| () => globalThis.__moontownGoldenValleyCamera?.x ?? 1792

///|
extern "js" fn golden_valley_camera_y() -> Double =
  #| () => globalThis.__moontownGoldenValleyCamera?.y ?? 3200

///|
extern "js" fn golden_valley_camera_zoom() -> Double =
  #| () => globalThis.__moontownGoldenValleyCamera?.z ?? 0.1

///|
extern "js" fn golden_focus_building_camera(
  world_x : Double,
  world_y : Double,
) -> Unit =
  #| (worldX, worldY) => {
  #|   globalThis.__moontownGoldenValleyCamera ||= { x: 1792, y: 3200, z: 0.1 };
  #|   const camera = globalThis.__moontownGoldenValleyCamera;
  #|   camera.x = (worldX - worldY) * 32;
  #|   camera.y = (worldX + worldY) * 16;
  #|   if (camera.z < 0.55) camera.z = 0.55;
  #|   globalThis.__moontownGoldenValleyRender?.();
  #| }

///|
extern "js" fn prepare_golden_valley_canvas(id : String) -> Unit =
  #| (id) => {
  #|   const canvas = globalThis.document?.getElementById(id);
  #|   if (!canvas) return;
  #|   const width = canvas.clientWidth || globalThis.innerWidth || 1280;
  #|   const height = canvas.clientHeight || globalThis.innerHeight || 720;
  #|   const dpr = Math.min(2, globalThis.devicePixelRatio || 1);
  #|   if (canvas.width !== Math.round(width * dpr) ||
  #|       canvas.height !== Math.round(height * dpr)) {
  #|     canvas.width = Math.round(width * dpr);
  #|     canvas.height = Math.round(height * dpr);
  #|   }
  #|   const context = canvas.getContext("2d");
  #|   context?.setTransform(dpr, 0, 0, dpr, 0, 0);
  #| }

///|
extern "js" fn golden_valley_canvas_width(id : String) -> Int =
  #| (id) => globalThis.document?.getElementById(id)?.clientWidth || 1280

///|
extern "js" fn golden_valley_canvas_height(id : String) -> Int =
  #| (id) => globalThis.document?.getElementById(id)?.clientHeight || 720

///|
extern "js" fn golden_ctx_fill_style(
  context : @dom.CanvasRenderingContext2D,
  value : String,
) -> Unit =
  #| (context, value) => { context.fillStyle = value }

///|
extern "js" fn golden_ctx_stroke_style(
  context : @dom.CanvasRenderingContext2D,
  value : String,
) -> Unit =
  #| (context, value) => { context.strokeStyle = value }

///|
extern "js" fn golden_ctx_line_width(
  context : @dom.CanvasRenderingContext2D,
  value : Double,
) -> Unit =
  #| (context, value) => { context.lineWidth = value }

///|
extern "js" fn golden_ctx_global_alpha(
  context : @dom.CanvasRenderingContext2D,
  value : Double,
) -> Unit =
  #| (context, value) => { context.globalAlpha = value }

///|
extern "js" fn golden_ctx_font(
  context : @dom.CanvasRenderingContext2D,
  value : String,
) -> Unit =
  #| (context, value) => { context.font = value }

///|
extern "js" fn golden_ctx_text_align(
  context : @dom.CanvasRenderingContext2D,
  value : String,
) -> Unit =
  #| (context, value) => { context.textAlign = value }

///|
extern "js" fn golden_ctx_text_baseline(
  context : @dom.CanvasRenderingContext2D,
  value : String,
) -> Unit =
  #| (context, value) => { context.textBaseline = value }

///|
extern "js" fn golden_ctx_measure_text(
  context : @dom.CanvasRenderingContext2D,
  value : String,
) -> Double =
  #| (context, value) => context.measureText(value).width

///|
extern "js" fn golden_draw_water_detail(
  context : @dom.CanvasRenderingContext2D,
  sx : Double,
  sy : Double,
  zoom : Double,
  phase : Double,
  time : Double,
) -> Unit =
  #| (context, sx, sy, zoom, phase, time) => {
  #|   const gradient = context.createLinearGradient(
  #|     sx, sy - 16 * zoom, sx, sy + 16 * zoom,
  #|   );
  #|   gradient.addColorStop(0, "#2e7f9e");
  #|   gradient.addColorStop(1, "#1f5f7e");
  #|   context.fillStyle = gradient;
  #|   context.fill();
  #|   context.save();
  #|   context.clip();
  #|   for (let index = 0; index < 2; index += 1) {
  #|     const progress = (
  #|       time * 0.35 + phase * 0.13 + index * 0.5
  #|     ) % 1;
  #|     const offset = (progress - 0.5) * 64 * zoom;
  #|     context.strokeStyle = `rgba(180,230,245,${0.35 - index * 0.12})`;
  #|     context.lineWidth = 2 * zoom;
  #|     context.beginPath();
  #|     context.moveTo(
  #|       sx - 32 * zoom * 0.6 + offset * 0.3,
  #|       sy + offset * 0.55,
  #|     );
  #|     context.quadraticCurveTo(
  #|       sx + Math.sin(time * 2 + phase) * 4 * zoom,
  #|       sy + offset * 0.55 + 3 * zoom,
  #|       sx + 32 * zoom * 0.6 + offset * 0.3,
  #|       sy + offset * 0.55,
  #|     );
  #|     context.stroke();
  #|   }
  #|   const sparkle = (Math.sin(time * 3 + phase * 5) + 1) / 2;
  #|   context.fillStyle = `rgba(255,255,255,${0.12 + sparkle * 0.25})`;
  #|   context.beginPath();
  #|   context.ellipse(
  #|     sx + Math.sin(phase * 9) * 10 * zoom,
  #|     sy + Math.cos(phase * 7) * 5 * zoom,
  #|     2.2 * zoom, 1.1 * zoom, 0, 0, Math.PI * 2,
  #|   );
  #|   context.fill();
  #|   context.restore();
  #| }

///|
extern "js" fn golden_draw_road_detail(
  context : @dom.CanvasRenderingContext2D,
  sx : Double,
  sy : Double,
  zoom : Double,
  mask : Int,
  major : Bool,
) -> Unit =
  #| (context, sx, sy, zoom, mask, major) => {
  #|   const north = [sx + 16 * zoom, sy - 8 * zoom];
  #|   const east = [sx + 16 * zoom, sy + 8 * zoom];
  #|   const south = [sx - 16 * zoom, sy + 8 * zoom];
  #|   const west = [sx - 16 * zoom, sy - 8 * zoom];
  #|   const northFar = [sx + 32 * zoom, sy - 16 * zoom];
  #|   const eastFar = [sx + 32 * zoom, sy + 16 * zoom];
  #|   const southFar = [sx - 32 * zoom, sy + 16 * zoom];
  #|   const westFar = [sx - 32 * zoom, sy - 16 * zoom];
  #|   const connections = [
  #|     [1, north, northFar],
  #|     [2, east, eastFar],
  #|     [4, south, southFar],
  #|     [8, west, westFar],
  #|   ];
  #|   const active = connections.filter(([bit]) => mask & bit);
  #|   const traceRoad = () => {
  #|     context.beginPath();
  #|     if (active.length === 2) {
  #|       const turning = mask !== 5 && mask !== 10;
  #|       const from = active[0][turning ? 2 : 1];
  #|       const to = active[1][turning ? 2 : 1];
  #|       context.moveTo(from[0], from[1]);
  #|       context.quadraticCurveTo(sx, sy, to[0], to[1]);
  #|       return;
  #|     }
  #|     for (const [, point] of active) {
  #|       context.moveTo(sx, sy);
  #|       context.lineTo(point[0], point[1]);
  #|     }
  #|   };
  #|   context.save();
  #|   context.lineCap = "round";
  #|   context.lineJoin = "round";
  #|   // Arterials retain a wider pale kerb and stronger asphalt body while
  #|   // local streets recede. The hierarchy survives the whole-map zoom.
  #|   context.strokeStyle = major
  #|     ? "rgba(238,230,207,0.82)"
  #|     : "rgba(224,220,207,0.48)";
  #|   context.lineWidth = Math.max(
  #|     major ? 5.1 : 3.0,
  #|     (major ? 24 : 13) * zoom,
  #|   );
  #|   context.setLineDash([]);
  #|   traceRoad();
  #|   context.stroke();
  #|   context.strokeStyle = major ? "#363d45" : "#525960";
  #|   context.lineWidth = Math.max(
  #|     major ? 3.9 : 2.25,
  #|     (major ? 18 : 9.5) * zoom,
  #|   );
  #|   traceRoad();
  #|   context.stroke();
  #|   context.strokeStyle = major ? "#f4cf54" : "rgba(248,250,252,0.82)";
  #|   context.lineWidth = Math.max(0.72, (major ? 1.55 : 1.05) * zoom);
  #|   context.setLineDash(zoom >= 0.45 ? [
  #|     Math.max(2.5, 5 * zoom),
  #|     Math.max(2, 4 * zoom),
  #|   ] : []);
  #|   traceRoad();
  #|   context.stroke();
  #|   context.restore();
  #| }

///|
extern "js" fn golden_draw_bridge_detail(
  context : @dom.CanvasRenderingContext2D,
  sx : Double,
  sy : Double,
  zoom : Double,
) -> Unit =
  #| (context, sx, sy, zoom) => {
  #|   context.save();
  #|   context.beginPath();
  #|   context.moveTo(sx, sy - 3 * zoom - 16 * zoom * 0.86);
  #|   context.lineTo(sx + 32 * zoom * 0.86, sy - 3 * zoom);
  #|   context.lineTo(sx, sy - 3 * zoom + 16 * zoom * 0.86);
  #|   context.lineTo(sx - 32 * zoom * 0.86, sy - 3 * zoom);
  #|   context.closePath();
  #|   const gradient = context.createLinearGradient(
  #|     sx, sy - 16 * zoom, sx, sy + 16 * zoom,
  #|   );
  #|   gradient.addColorStop(0, "#b08954");
  #|   gradient.addColorStop(1, "#8a6a40");
  #|   context.fillStyle = gradient;
  #|   context.fill();
  #|   context.strokeStyle = "rgba(60,40,20,0.5)";
  #|   context.lineWidth = 1;
  #|   context.stroke();
  #|   context.strokeStyle = "rgba(60,40,20,0.35)";
  #|   for (let index = -1; index <= 1; index += 1) {
  #|     context.beginPath();
  #|     context.moveTo(
  #|       sx - 32 * zoom * 0.7, sy - 3 * zoom + index * 5 * zoom,
  #|     );
  #|     context.lineTo(
  #|       sx + 32 * zoom * 0.7, sy - 3 * zoom + index * 5 * zoom,
  #|     );
  #|     context.stroke();
  #|   }
  #|   context.strokeStyle = "#5e4630";
  #|   context.lineWidth = 2 * zoom;
  #|   context.beginPath();
  #|   context.moveTo(sx - 32 * zoom * 0.8, sy - 9.72 * zoom);
  #|   context.lineTo(sx + 32 * zoom * 0.8, sy - 9.72 * zoom);
  #|   context.moveTo(sx - 32 * zoom * 0.8, sy + 3.72 * zoom);
  #|   context.lineTo(sx + 32 * zoom * 0.8, sy + 3.72 * zoom);
  #|   context.stroke();
  #|   context.restore();
  #| }

///|
extern "js" fn golden_draw_ground_detail(
  context : @dom.CanvasRenderingContext2D,
  terrain : String,
  sx : Double,
  sy : Double,
  zoom : Double,
  variation : Double,
  phase : Int,
  civic_urban : Bool,
) -> Unit =
  #| (context, terrain, sx, sy, zoom, variation, phase, civicUrban) => {
  #|   const shade = (hex, factor) => {
  #|     const n = Number.parseInt(hex.slice(1), 16);
  #|     const r = Math.min(255, Math.round(((n >> 16) & 255) * factor));
  #|     const g = Math.min(255, Math.round(((n >> 8) & 255) * factor));
  #|     const b = Math.min(255, Math.round((n & 255) * factor));
  #|     return `rgb(${r},${g},${b})`;
  #|   };
  #|   const diamond = () => {
  #|     context.beginPath();
  #|     context.moveTo(sx, sy - 16 * zoom);
  #|     context.lineTo(sx + 32 * zoom, sy);
  #|     context.lineTo(sx, sy + 16 * zoom);
  #|     context.lineTo(sx - 32 * zoom, sy);
  #|     context.closePath();
  #|   };
  #|   if (terrain === "grass") {
  #|     // Two-tone diagonal gradient: light from the upper-left so the lawn
  #|     // reads as softly lit ground instead of a flat green carpet.
  #|     const grassBase = shade("#5da25f", 1 + variation * 0.09);
  #|     const gradient = context.createLinearGradient(
  #|       sx, sy - 16 * zoom,
  #|       sx, sy + 16 * zoom,
  #|     );
  #|     gradient.addColorStop(0, shade("#6db36b", 1 + variation * 0.1));
  #|     gradient.addColorStop(0.55, grassBase);
  #|     gradient.addColorStop(1, shade("#4f8f52", 1 + variation * 0.08));
  #|     context.fillStyle = gradient;
  #|     context.fill();
  #|     return;
  #|   }
  #|   if (terrain === "meadow") {
  #|     context.fillStyle = shade("#78b85c", 0.96 + variation * 0.12);
  #|     context.fill();
  #|     context.fillStyle = variation > 0.55
  #|       ? "rgba(255,220,105,0.52)"
  #|       : "rgba(255,164,190,0.48)";
  #|     for (let index = 0; index < 2; index += 1) {
  #|       const px = sx + (
  #|         (variation * 19 + index * 13) % (32 * zoom * 0.8)
  #|       ) - 32 * zoom * 0.4;
  #|       const py = sy + (
  #|         (variation * 31 + index * 9) % (16 * zoom * 0.9)
  #|       ) - 16 * zoom * 0.45;
  #|       context.beginPath();
  #|       context.arc(px, py, Math.max(0.8, 1.2 * zoom), 0, Math.PI * 2);
  #|       context.fill();
  #|     }
  #|     return;
  #|   }
  #|   if (terrain === "field") {
  #|     context.fillStyle = shade("#a8bd48", 0.92 + variation * 0.12);
  #|     context.fill();
  #|     context.save();
  #|     diamond();
  #|     context.clip();
  #|     context.strokeStyle = phase % 2 === 0
  #|       ? "rgba(236,219,91,0.45)"
  #|       : "rgba(100,128,42,0.38)";
  #|     context.lineWidth = Math.max(1, 1.4 * zoom);
  #|     for (let row = -2; row <= 2; row += 1) {
  #|       context.beginPath();
  #|       context.moveTo(sx - 32 * zoom, sy + row * 5 * zoom);
  #|       context.lineTo(sx + 32 * zoom, sy + row * 5 * zoom);
  #|       context.stroke();
  #|     }
  #|     context.restore();
  #|     return;
  #|   }
  #|   if (terrain === "wetland") {
  #|     context.fillStyle = shade("#70a957", 0.9 + variation * 0.12);
  #|     context.fill();
  #|     context.save();
  #|     diamond();
  #|     context.clip();
  #|     context.fillStyle = "rgba(37,126,133,0.36)";
  #|     context.beginPath();
  #|     context.ellipse(
  #|       sx + (variation - 0.5) * 16 * zoom,
  #|       sy + (variation - 0.5) * 5 * zoom,
  #|       12 * zoom, 3.2 * zoom, 0, 0, Math.PI * 2,
  #|     );
  #|     context.fill();
  #|     context.strokeStyle = "rgba(48,94,44,0.5)";
  #|     context.lineWidth = Math.max(1, zoom);
  #|     for (let reed = -1; reed <= 1; reed += 1) {
  #|       const rx = sx + (reed * 8 + variation * 4) * zoom;
  #|       context.beginPath();
  #|       context.moveTo(rx, sy + 4 * zoom);
  #|       context.lineTo(rx + 1.5 * zoom, sy - 3 * zoom);
  #|       context.stroke();
  #|     }
  #|     context.restore();
  #|     return;
  #|   }
  #|   if (terrain === "forest") {
  #|     context.fillStyle = shade("#3f7f48", 0.98 + variation * 0.08);
  #|     context.fill();
  #|     return;
  #|   }
  #|   if (terrain === "urban") {
  #|     context.fillStyle = civicUrban ? "#aeb6ad" : "#a9b19f";
  #|     context.fill();
  #|     context.strokeStyle = "rgba(255,255,255,0.12)";
  #|     context.lineWidth = 1;
  #|     context.stroke();
  #|     return;
  #|   }
  #|   if (terrain === "plaza") {
  #|     context.fillStyle = "#c9c2b2";
  #|     context.fill();
  #|     context.strokeStyle = "rgba(0,0,0,0.08)";
  #|     context.lineWidth = 1;
  #|     context.stroke();
  #|     if (zoom >= 0.2) {
  #|       // Fine paving joins adjacent campus tiles without replacing their
  #|       // authored footprint. It appears only at neighborhood zoom.
  #|       context.save();
  #|       diamond();
  #|       context.clip();
  #|       context.strokeStyle = "rgba(255,250,235,0.22)";
  #|       context.lineWidth = Math.max(0.6, zoom);
  #|       for (let offset = -24; offset <= 24; offset += 8) {
  #|         context.beginPath();
  #|         context.moveTo(sx - 34 * zoom, sy + offset * zoom);
  #|         context.lineTo(sx + 34 * zoom, sy + offset * zoom);
  #|         context.stroke();
  #|       }
  #|       context.restore();
  #|     }
  #|   }
  #| }

///|
extern "js" fn golden_draw_background(
  context : @dom.CanvasRenderingContext2D,
  width : Int,
  height : Int,
  hour : Double,
) -> Unit =
  #| (context, width, height, hour) => {
  #|   const progress = (hour - 6) / 13;
  #|   const daylight = progress <= 0 || progress >= 1
  #|     ? 0
  #|     : Math.sin(progress * Math.PI);
  #|   const gradient = context.createLinearGradient(0, 0, 0, height);
  #|   if (daylight > 0.5) {
  #|     // Warmer midday palette: friendlier "town" feel vs the old cold
  #|     // control-room blue, while keeping the day/dusk/night cycle legible.
  #|     gradient.addColorStop(0, "#a9d3ec");
  #|     gradient.addColorStop(1, "#e9e3c4");
  #|   } else if (daylight > 0.15) {
  #|     gradient.addColorStop(0, "#8d97c5");
  #|     gradient.addColorStop(1, "#d9bd9a");
  #|   } else {
  #|     gradient.addColorStop(0, "#0b1026");
  #|     gradient.addColorStop(1, "#182238");
  #|   }
  #|   context.fillStyle = gradient;
  #|   context.fillRect(0, 0, width, height);
  #| }

///|
extern "js" fn golden_draw_day_night(
  context : @dom.CanvasRenderingContext2D,
  width : Int,
  height : Int,
  hour : Double,
) -> Unit =
  #| (context, width, height, hour) => {
  #|   const progress = (hour - 6) / 13;
  #|   const daylight = progress <= 0 || progress >= 1
  #|     ? 0
  #|     : Math.sin(progress * Math.PI);
  #|   if (daylight > 0 && daylight < 0.45) {
  #|     context.fillStyle = `rgba(255,140,60,${0.14 * (
  #|       1 - daylight / 0.45
  #|     )})`;
  #|     context.fillRect(0, 0, width, height);
  #|   }
  #|   if (daylight < 0.5) {
  #|     context.fillStyle = `rgba(8,14,40,${0.42 * (
  #|       1 - daylight / 0.5
  #|     )})`;
  #|     context.fillRect(0, 0, width, height);
  #|   }
  #|   const radius = Math.min(width, height) * 0.42;
  #|   const edge = Math.max(width, height) * 0.75;
  #|   const vignette = context.createRadialGradient(
  #|     width / 2, height / 2, radius,
  #|     width / 2, height / 2, edge,
  #|   );
  #|   vignette.addColorStop(0, "rgba(0,0,0,0)");
  #|   vignette.addColorStop(1, "rgba(0,0,0,0.28)");
  #|   context.fillStyle = vignette;
  #|   context.fillRect(0, 0, width, height);
  #| }

///|
extern "js" fn golden_draw_iso_windows(
  context : @dom.CanvasRenderingContext2D,
  sx : Double,
  sy : Double,
  width : Double,
  depth : Double,
  height : Double,
  zoom : Double,
  columns : Int,
  rows : Int,
  lit_fraction : Double,
) -> Unit =
  #| (
  #|   context, sx, sy, width, depth, height, zoom,
  #|   columns, rows, litFraction,
  #| ) => {
  #|   const scaledHeight = height * zoom / 0.95;
  #|   const halfWidth = 16 * zoom;
  #|   const halfHeight = 8 * zoom;
  #|   const topY = sy - scaledHeight;
  #|   const eastTop = {
  #|     x: sx + (width + depth) * halfWidth,
  #|     y: topY + (width - depth) * halfHeight,
  #|   };
  #|   const southTop = {
  #|     x: sx + (width - depth) * halfWidth,
  #|     y: topY + (width + depth) * halfHeight,
  #|   };
  #|   const westTop = {
  #|     x: sx - (width + depth) * halfWidth,
  #|     y: topY + (depth - width) * halfHeight,
  #|   };
  #|   const east = { x: eastTop.x, y: eastTop.y + scaledHeight };
  #|   const south = { x: southTop.x, y: southTop.y + scaledHeight };
  #|   const west = { x: westTop.x, y: westTop.y + scaledHeight };
  #|   const lerp = (a, b, value) => ({
  #|     x: a.x + (b.x - a.x) * value,
  #|     y: a.y + (b.y - a.y) * value,
  #|   });
  #|   const hash = value => {
  #|     let result = 2166136261;
  #|     for (let index = 0; index < value.length; index += 1) {
  #|       result ^= value.charCodeAt(index);
  #|       result = Math.imul(result, 16777619);
  #|     }
  #|     return (result >>> 0) / 4294967296;
  #|   };
  #|   const drawFace = (topLeft, topRight, bottomRight, bottomLeft, salt) => {
  #|     for (let row = 0; row < rows; row += 1) {
  #|       for (let column = 0; column < columns; column += 1) {
  #|         const f0 = column / columns + 0.12 / columns;
  #|         const f1 = (column + 0.62) / columns;
  #|         const g0 = row / rows + 0.18 / rows;
  #|         const g1 = (row + 0.62) / rows;
  #|         const at = (f, g) => lerp(
  #|           lerp(topLeft, topRight, f),
  #|           lerp(bottomLeft, bottomRight, f),
  #|           g,
  #|         );
  #|         const points = [
  #|           at(f0, g0), at(f1, g0), at(f1, g1), at(f0, g1),
  #|         ];
  #|         const value = hash(`${salt}-${row}-${column}`);
  #|         const lit = value < litFraction;
  #|         // Day-time windows read as recessed glass: a darker pane with a
  #|         // brighter sky reflection band so the grid is clearly visible.
  #|         context.fillStyle = lit
  #|           ? value < litFraction * 0.48
  #|             ? "rgba(255,218,132,0.98)"
  #|             : value < litFraction * 0.82
  #|               ? "rgba(255,186,91,0.96)"
  #|               : "rgba(255,231,178,0.94)"
  #|           : value > 0.8
  #|             ? "rgba(20,32,48,0.72)"
  #|             : "rgba(74,108,138,0.62)";
  #|         context.beginPath();
  #|         context.moveTo(points[0].x, points[0].y);
  #|         for (let index = 1; index < points.length; index += 1) {
  #|           context.lineTo(points[index].x, points[index].y);
  #|         }
  #|         context.closePath();
  #|         context.fill();
  #|         if (!lit) {
  #|           // Glass reflection: a bright sliver along the top edge.
  #|           context.fillStyle = "rgba(210,230,245,0.5)";
  #|           context.beginPath();
  #|           context.moveTo(points[0].x, points[0].y);
  #|           context.lineTo(points[1].x, points[1].y);
  #|           context.lineTo(
  #|             points[1].x + (points[2].x - points[1].x) * 0.3,
  #|             points[1].y + (points[2].y - points[1].y) * 0.3,
  #|           );
  #|           context.lineTo(
  #|             points[0].x + (points[3].x - points[0].x) * 0.3,
  #|             points[0].y + (points[3].y - points[0].y) * 0.3,
  #|           );
  #|           context.closePath();
  #|           context.fill();
  #|         }
  #|       }
  #|     }
  #|   };
  #|   drawFace(westTop, southTop, south, west, 1);
  #|   drawFace(eastTop, southTop, south, east, 7);
  #| }

///|
extern "js" fn golden_math_sin(value : Double) -> Double =
  #| (value) => Math.sin(value)

///|
extern "js" fn golden_animation_seconds() -> Double =
  #| () => globalThis.matchMedia?.("(prefers-reduced-motion: reduce)")?.matches
  #|   ? 0
  #|   : globalThis.performance.now() / 1000

///|
extern "js" fn golden_prefers_reduced_motion() -> Bool =
  #| () => Boolean(
  #|   globalThis.matchMedia?.("(prefers-reduced-motion: reduce)")?.matches,
  #| )

///|
extern "js" fn golden_draw_reference_building_shadow(
  context : @dom.CanvasRenderingContext2D,
  sx : Double,
  sy : Double,
  width : Double,
  depth : Double,
  zoom : Double,
) -> Unit =
  #| (context, sx, sy, width, depth, zoom) => {
  #|   // Soft directional cast: light comes from the upper-left, so the shadow
  #|   // falls toward the lower-right. A tight contact shadow anchors the base
  #|   // and a blurred offset shadow gives it a soft, grounded look.
  #|   const rx = width * 32 * zoom * 0.82;
  #|   const ry = depth * 16 * zoom * 0.82;
  #|   context.save();
  #|   // Directional soft shadow, offset away from the light.
  #|   context.fillStyle = "rgba(0,0,0,0.18)";
  #|   context.filter = `blur(${Math.max(2, 6 * zoom)}px)`;
  #|   context.beginPath();
  #|   context.ellipse(
  #|     sx + 12 * zoom, sy + 9 * zoom,
  #|     rx, ry,
  #|     0, 0, Math.PI * 2,
  #|   );
  #|   context.fill();
  #|   context.restore();
  #|   // Tight contact shadow right under the footprint.
  #|   context.fillStyle = "rgba(0,0,0,0.24)";
  #|   context.beginPath();
  #|   context.ellipse(
  #|     sx + 3 * zoom, sy + 2 * zoom,
  #|     rx * 0.92, ry * 0.92,
  #|     0, 0, Math.PI * 2,
  #|   );
  #|   context.fill();
  #| }

///|
extern "js" fn golden_draw_reference_building_details(
  context : @dom.CanvasRenderingContext2D,
  style : String,
  world_x : Double,
  world_y : Double,
  width : Double,
  depth : Double,
  height : Double,
  viewport_width : Int,
  viewport_height : Int,
  time : Double,
  selected : Bool,
) -> Unit =
  #| (context, style, tx, ty, width, depth, height0, vw, vh, time, selected) => {
  #|   const camera = globalThis.__moontownGoldenValleyCamera ??
  #|     { x: -64, y: 832, z: 0.95 };
  #|   const z = camera.z;
  #|   const height = height0 * z / 0.95;
  #|   const toScreen = (x, y) => ({
  #|     x: ((x - y) * 32 - camera.x) * z + vw / 2,
  #|     y: ((x + y) * 16 - camera.y) * z + vh / 2,
  #|   });
  #|   const lerp = (a, b, f) => ({
  #|     x: a.x + (b.x - a.x) * f,
  #|     y: a.y + (b.y - a.y) * f,
  #|   });
  #|   const top = (x, y, w, d, h) => {
  #|     const lift = h * z / 0.95;
  #|     const up = point => ({ x: point.x, y: point.y - lift });
  #|     const N = up(toScreen(x, y));
  #|     const E = up(toScreen(x + w, y));
  #|     const S = up(toScreen(x + w, y + d));
  #|     const W = up(toScreen(x, y + d));
  #|     return {
  #|       N, E, S, W,
  #|       center: {
  #|         x: (N.x + E.x + S.x + W.x) / 4,
  #|         y: (N.y + E.y + S.y + W.y) / 4,
  #|       },
  #|     };
  #|   };
  #|   const polygon = (points, fill) => {
  #|     context.fillStyle = fill;
  #|     context.beginPath();
  #|     context.moveTo(points[0].x, points[0].y);
  #|     for (let i = 1; i < points.length; i += 1) {
  #|       context.lineTo(points[i].x, points[i].y);
  #|     }
  #|     context.closePath();
  #|     context.fill();
  #|   };
  #|   const flag = (x, y, color) => {
  #|     context.strokeStyle = "#e8e8e8";
  #|     context.lineWidth = 1.5 * z;
  #|     context.beginPath();
  #|     context.moveTo(x, y);
  #|     context.lineTo(x, y - 14 * z);
  #|     context.stroke();
  #|     const wave = Math.sin(time * 5) * 2 * z;
  #|     polygon([
  #|       { x, y: y - 14 * z },
  #|       { x: x + 10 * z, y: y - 12 * z + wave },
  #|       { x, y: y - 8 * z },
  #|     ], color);
  #|   };
  #|   const center = toScreen(tx + width / 2, ty + depth / 2);
  #|   if (style === "market") {
  #|     const colors = ["#d4553a", "#e8a83a", "#3a8ad4", "#50b06a"];
  #|     let index = 0;
  #|     for (let column = 0; column < 2; column += 1) {
  #|       for (let row = 0; row < 2; row += 1) {
  #|         const stallWidth = width / 2 - 0.15;
  #|         const stallDepth = depth / 2 - 0.15;
  #|         const roof = top(
  #|           tx + column * width / 2 + 0.08,
  #|           ty + row * depth / 2 + 0.08,
  #|           stallWidth, stallDepth, 6.65,
  #|         );
  #|         context.globalAlpha = 0.85;
  #|         polygon([roof.N, roof.E, roof.S, roof.W], colors[index]);
  #|         context.globalAlpha = 1;
  #|         const start = lerp(roof.N, roof.W, 0.5);
  #|         const end = lerp(roof.E, roof.S, 0.5);
  #|         context.strokeStyle = "rgba(255,255,255,0.5)";
  #|         context.lineWidth = 1.5 * z;
  #|         context.beginPath();
  #|         context.moveTo(start.x, start.y);
  #|         context.lineTo(end.x, end.y);
  #|         context.stroke();
  #|         index += 1;
  #|       }
  #|     }
  #|   }
  #|   if (style === "hall") {
  #|     const roof = top(tx, ty, width, depth, height0);
  #|     const peak = {
  #|       x: roof.center.x,
  #|       y: roof.center.y - 10 * z,
  #|     };
  #|     polygon([roof.W, roof.S, peak], "#8a4f3a");
  #|     context.strokeStyle = "rgba(250,246,235,0.9)";
  #|     context.lineWidth = 2.2 * z;
  #|     for (let i = 1; i <= 3; i += 1) {
  #|       const base = lerp(roof.W, roof.S, i / 4);
  #|       context.beginPath();
  #|       context.moveTo(base.x, base.y);
  #|       context.lineTo(base.x, base.y + 8 * z);
  #|       context.stroke();
  #|     }
  #|     flag(peak.x, peak.y, "#d4553a");
  #|   } else if (style === "home" || style === "custom-home") {
  #|     const first = top(tx, ty, width / 2, depth, height0 * 0.85);
  #|     const second = top(
  #|       tx + width / 2, ty + 0.3, width / 2, depth - 0.3, height0,
  #|     );
  #|     for (const roof of [first, second]) {
  #|       polygon([roof.N, roof.W, {
  #|         x: roof.S.x, y: roof.S.y - 6 * z,
  #|       }], "#7a5240");
  #|       polygon([roof.N, roof.E, {
  #|         x: roof.S.x, y: roof.S.y - 6 * z,
  #|       }], "#8a6248");
  #|     }
  #|   } else if (style === "garden") {
  #|     const domeHeight = 20 * z;
  #|     const gradient = context.createLinearGradient(
  #|       center.x, center.y - domeHeight, center.x, center.y,
  #|     );
  #|     gradient.addColorStop(0, "rgba(210,240,250,0.85)");
  #|     gradient.addColorStop(1, "rgba(150,200,220,0.45)");
  #|     context.fillStyle = gradient;
  #|     context.beginPath();
  #|     context.ellipse(
  #|       center.x, center.y - 5 * z, 16 * z, domeHeight * 0.8,
  #|       0, Math.PI, 0,
  #|     );
  #|     context.fill();
  #|     context.strokeStyle = "rgba(255,255,255,0.6)";
  #|     context.lineWidth = z;
  #|     for (let i = -2; i <= 2; i += 1) {
  #|       context.beginPath();
  #|       context.ellipse(
  #|         center.x + i * 6 * z, center.y - 5 * z,
  #|         3 * z, domeHeight * 0.75, 0, Math.PI, 0,
  #|       );
  #|       context.stroke();
  #|     }
  #|   } else if (style === "plaza") {
  #|     context.strokeStyle = "rgba(250,246,235,0.95)";
  #|     context.lineWidth = 2 * z;
  #|     const corners = [
  #|       toScreen(tx + 0.3, ty + 0.3),
  #|       toScreen(tx + width - 0.3, ty + 0.3),
  #|       toScreen(tx + width - 0.3, ty + depth - 0.3),
  #|       toScreen(tx + 0.3, ty + depth - 0.3),
  #|     ];
  #|     for (const point of corners) {
  #|       context.beginPath();
  #|       context.moveTo(point.x, point.y - 4 * z);
  #|       context.lineTo(point.x, point.y - 14 * z);
  #|       context.stroke();
  #|     }
  #|     const fx = center.x;
  #|     const fy = center.y - 4 * z;
  #|     context.fillStyle = "#b8b0a0";
  #|     context.beginPath();
  #|     context.ellipse(fx, fy, 11 * z, 5.5 * z, 0, 0, Math.PI * 2);
  #|     context.fill();
  #|     context.fillStyle = "#3f8ab8";
  #|     context.beginPath();
  #|     context.ellipse(fx, fy - z, 8.5 * z, 4 * z, 0, 0, Math.PI * 2);
  #|     context.fill();
  #|     const jet = 6 * z + Math.sin(time * 3) * 2 * z;
  #|     context.strokeStyle = "rgba(200,235,250,0.9)";
  #|     context.lineWidth = 1.6 * z;
  #|     for (let i = -1; i <= 1; i += 1) {
  #|       context.beginPath();
  #|       context.moveTo(fx + i * 2.5 * z, fy - z);
  #|       context.quadraticCurveTo(
  #|         fx + i * 5 * z, fy - jet - 3 * z,
  #|         fx + i * 6.5 * z, fy - z,
  #|       );
  #|       context.stroke();
  #|     }
  #|     flag(center.x, center.y - 14 * z, "#3a8ad4");
  #|   } else if (style === "radar") {
  #|     const roof = top(tx, ty, width, depth, height0 * 0.6);
  #|     context.strokeStyle = "#cfd8e0";
  #|     context.lineWidth = 2 * z;
  #|     context.beginPath();
  #|     context.moveTo(roof.center.x, roof.center.y);
  #|     context.lineTo(roof.center.x, roof.center.y - 22 * z);
  #|     context.stroke();
  #|     const angle = time * 1.4;
  #|     context.strokeStyle = "#5ec8e8";
  #|     context.lineWidth = 3 * z;
  #|     context.beginPath();
  #|     context.moveTo(
  #|       roof.center.x - Math.cos(angle) * 12 * z,
  #|       roof.center.y - 22 * z - Math.sin(angle) * 4 * z,
  #|     );
  #|     context.lineTo(
  #|       roof.center.x + Math.cos(angle) * 12 * z,
  #|       roof.center.y - 22 * z + Math.sin(angle) * 4 * z,
  #|     );
  #|     context.stroke();
  #|     const wave = (time * 0.7 + 0.37) % 1;
  #|     context.strokeStyle = `rgba(94,200,232,${0.5 * (1 - wave)})`;
  #|     context.lineWidth = 1.5 * z;
  #|     context.beginPath();
  #|     context.ellipse(
  #|       roof.center.x, roof.center.y - 22 * z,
  #|       (10 + wave * 22) * z, (10 + wave * 22) * 0.35 * z,
  #|       0, 0, Math.PI * 2,
  #|     );
  #|     context.stroke();
  #|   } else if (style === "tower" || style === "custom-tower") {
  #|     const roof = top(
  #|       tx + 0.3, ty, width - 0.3, 0.6, height0 + 7.6,
  #|     );
  #|     context.fillStyle = "rgba(255,255,255,0.12)";
  #|     polygon([roof.N, roof.E, roof.S, roof.W], context.fillStyle);
  #|     context.strokeStyle = "#dfe8f0";
  #|     context.lineWidth = 1.6 * z;
  #|     context.beginPath();
  #|     context.moveTo(roof.center.x, roof.center.y);
  #|     context.lineTo(roof.center.x, roof.center.y - 12 * z);
  #|     context.stroke();
  #|     const blink = (Math.sin(time * 2.5 + 3.7) + 1) / 2;
  #|     context.fillStyle = `rgba(255,80,80,${0.4 + blink * 0.6})`;
  #|     context.beginPath();
  #|     context.arc(
  #|       roof.center.x, roof.center.y - 12 * z, 2 * z,
  #|       0, Math.PI * 2,
  #|     );
  #|     context.fill();
  #|   }
  #|   if (selected) {
  #|     const pulse = (Math.sin(time * 4) + 1) / 2;
  #|     const N = toScreen(tx, ty);
  #|     const E = toScreen(tx + width, ty);
  #|     const S = toScreen(tx + width, ty + depth);
  #|     const W = toScreen(tx, ty + depth);
  #|     context.strokeStyle = `rgba(255,210,90,${0.6 + pulse * 0.4})`;
  #|     context.lineWidth = 2.5 * z;
  #|     context.beginPath();
  #|     context.moveTo(N.x, N.y);
  #|     context.lineTo(E.x, E.y);
  #|     context.lineTo(S.x, S.y);
  #|     context.lineTo(W.x, W.y);
  #|     context.closePath();
  #|     context.stroke();
  #|     const gradient = context.createLinearGradient(
  #|       center.x, center.y - 90 * z, center.x, center.y,
  #|     );
  #|     gradient.addColorStop(0, "rgba(255,210,90,0)");
  #|     gradient.addColorStop(1, `rgba(255,210,90,${0.25 + pulse * 0.2})`);
  #|     context.fillStyle = gradient;
  #|     context.fillRect(
  #|       center.x - 14 * z, center.y - 90 * z, 28 * z, 90 * z,
  #|     );
  #|   }
  #| }

///|
extern "js" fn golden_reference_hash(value : String) -> Double =
  #| (value) => {
  #|   let hash = 2166136261;
  #|   for (let index = 0; index < value.length; index += 1) {
  #|     hash ^= value.charCodeAt(index);
  #|     hash = Math.imul(hash, 16777619);
  #|   }
  #|   return (hash >>> 0) / 4294967296;
  #| }

///|
extern "js" fn golden_draw_reference_tree(
  context : @dom.CanvasRenderingContext2D,
  sx : Double,
  sy : Double,
  zoom : Double,
  seed : Double,
  time : Double,
) -> Unit =
  #| (context, sx, sy, zoom, seed, time) => {
  #|   const shade = (hex, factor) => {
  #|     const n = Number.parseInt(hex.slice(1), 16);
  #|     const r = Math.min(255, Math.max(0, ((n >> 16) & 255) * factor));
  #|     const g = Math.min(255, Math.max(0, ((n >> 8) & 255) * factor));
  #|     const b = Math.min(255, Math.max(0, (n & 255) * factor));
  #|     return `rgb(${r | 0},${g | 0},${b | 0})`;
  #|   };
  #|   const sway = Math.sin(time * 1.2 + seed * 20) * 1.5 * zoom;
  #|   const height = (14 + seed * 10) * zoom;
  #|   context.fillStyle = "rgba(0,0,0,0.18)";
  #|   context.beginPath();
  #|   context.ellipse(
  #|     sx + 3 * zoom, sy + zoom, 8 * zoom, 3.5 * zoom,
  #|     0, 0, Math.PI * 2,
  #|   );
  #|   context.fill();
  #|   context.strokeStyle = "#6b4a2e";
  #|   context.lineWidth = 2.4 * zoom;
  #|   context.beginPath();
  #|   context.moveTo(sx, sy);
  #|   context.lineTo(sx + sway * 0.3, sy - height * 0.45);
  #|   context.stroke();
  #|   context.fillStyle = shade("#3e7d46", 0.9 + seed * 0.25);
  #|   context.beginPath();
  #|   context.ellipse(
  #|     sx + sway * 0.5, sy - height * 0.62,
  #|     9 * zoom, 6.5 * zoom, 0, 0, Math.PI * 2,
  #|   );
  #|   context.fill();
  #|   context.fillStyle = shade("#4d9a52", 0.9 + seed * 0.25);
  #|   context.beginPath();
  #|   context.ellipse(
  #|     sx + sway * 0.8 - 2 * zoom, sy - height * 0.85,
  #|     6.5 * zoom, 5 * zoom, 0, 0, Math.PI * 2,
  #|   );
  #|   context.fill();
  #| }

///|
fn golden_valley_agent_sprite_path(role : String, index : Int) -> String {
  match role.to_lower() {
    "mayor" => "/tilemap/actors/mayor_walk_strip.png"
    "keeper" => "/tilemap/actors/keeper_walk_strip.png"
    "worker" => "/tilemap/actors/worker_walk_strip.png"
    "researcher" => "/tilemap/actors/researcher_walk_strip.png"
    _ => "/tilemap/actors/roster/resident_\{index.abs() % 64}_walk_strip.png"
  }
}

///|
extern "js" fn golden_draw_sprite_agent(
  context : @dom.CanvasRenderingContext2D,
  sx : Double,
  sy : Double,
  zoom : Double,
  sprite_path : String,
  facing_left : Bool,
  bob : Double,
  work_color : String,
  activity_glyph : String,
  activity_label : String,
  preview : Bool,
  selected : Bool,
) -> Unit =
  #| (
  #|   context, sx, sy, zoom, spritePath, facingLeft, bob, workColor,
  #|   activityGlyph, activityLabel, preview, selected,
  #| ) => {
  #|   globalThis.__moontownGoldenAgentSprites ||= new Map();
  #|   const cache = globalThis.__moontownGoldenAgentSprites;
  #|   let sprite = cache.get(spritePath);
  #|   if (!sprite) {
  #|     const image = new Image();
  #|     sprite = { image, ready: false, failed: false };
  #|     cache.set(spritePath, sprite);
  #|     image.decoding = "async";
  #|     image.onload = () => {
  #|       sprite.ready = true;
  #|       globalThis.__moontownGoldenValleyRender?.();
  #|     };
  #|     image.onerror = () => {
  #|       sprite.failed = true;
  #|     };
  #|     image.src = spritePath;
  #|   }
  #|   const height = Math.min(82, Math.max(20, 64 * zoom));
  #|   const shadowWidth = height * 0.27;
  #|   context.save();
  #|   context.fillStyle = "rgba(15,23,42,0.24)";
  #|   context.beginPath();
  #|   context.ellipse(
  #|     sx, sy + Math.max(1, zoom * 2),
  #|     shadowWidth, Math.max(2, height * 0.08),
  #|     0, 0, Math.PI * 2,
  #|   );
  #|   context.fill();
  #|   if (selected) {
  #|     context.fillStyle = "rgba(251,191,36,0.14)";
  #|     context.strokeStyle = "rgba(253,230,138,0.96)";
  #|     context.lineWidth = Math.max(2, zoom * 2.2);
  #|     context.beginPath();
  #|     context.ellipse(
  #|       sx, sy + Math.max(1, zoom * 2),
  #|       Math.max(18, height * 0.38), Math.max(7, height * 0.13),
  #|       0, 0, Math.PI * 2,
  #|     );
  #|     context.fill();
  #|     context.stroke();
  #|   }
  #|   // PREVIEW is a shape as well as a color. Keep this dashed diamond
  #|   // visible at whole-map zoom, while the activity bubble below remains a
  #|   // progressive-detail affordance for closer zoom levels.
  #|   if (preview) {
  #|     const markerRadius = Math.max(7, height * 0.22);
  #|     const markerY = sy - height - Math.max(4, height * 0.08);
  #|     context.strokeStyle = "rgba(221,214,254,0.96)";
  #|     context.lineWidth = Math.max(1.25, zoom * 1.35);
  #|     context.setLineDash([3, 2]);
  #|     context.beginPath();
  #|     context.moveTo(sx, markerY - markerRadius);
  #|     context.lineTo(sx + markerRadius, markerY);
  #|     context.lineTo(sx, markerY + markerRadius);
  #|     context.lineTo(sx - markerRadius, markerY);
  #|     context.closePath();
  #|     context.stroke();
  #|     context.setLineDash([]);
  #|   }
  #|   if (activityGlyph && zoom >= 0.38) {
  #|     const text = zoom >= 0.9 && activityLabel
  #|       ? activityLabel
  #|       : activityGlyph;
  #|     const fontSize = zoom >= 0.9 ? 10 : 12;
  #|     context.font =
  #|       "700 " + fontSize +
  #|       "px \"PingFang SC\", \"Microsoft YaHei\", sans-serif";
  #|     context.textAlign = "center";
  #|     context.textBaseline = "middle";
  #|     const width = Math.max(
  #|       18,
  #|       Math.min(92, context.measureText(text).width + 12),
  #|     );
  #|     const bubbleY = sy - height - Math.max(9, zoom * 12);
  #|     context.fillStyle = preview
  #|       ? "rgba(30,41,59,0.88)"
  #|       : "rgba(2,6,23,0.92)";
  #|     context.strokeStyle = workColor || (
  #|       preview ? "rgba(196,181,253,0.9)" : "rgba(125,211,252,0.9)"
  #|     );
  #|     context.lineWidth = Math.max(1, zoom);
  #|     context.setLineDash(preview ? [3, 2] : []);
  #|     context.beginPath();
  #|     context.roundRect(
  #|       sx - width / 2, bubbleY - 9, width, 18, 8,
  #|     );
  #|     context.fill();
  #|     context.stroke();
  #|     context.setLineDash([]);
  #|     context.fillStyle = preview ? "#ddd6fe" : "#e0f2fe";
  #|     context.fillText(text, sx, bubbleY + 0.5);
  #|   }
  #|   if (sprite.ready && sprite.image.naturalWidth > 0) {
  #|     const image = sprite.image;
  #|     const frameCount = 4;
  #|     const frameWidth = image.naturalWidth / frameCount;
  #|     const frame = ((Math.floor(bob * 0.72) % frameCount) + frameCount) %
  #|       frameCount;
  #|     const width = height * frameWidth / image.naturalHeight;
  #|     const bobY = Math.abs(Math.sin(bob * 0.5)) * Math.max(0.5, zoom);
  #|     context.translate(sx, sy - bobY);
  #|     if (facingLeft) context.scale(-1, 1);
  #|     context.imageSmoothingEnabled = false;
  #|     context.drawImage(
  #|       image,
  #|       frame * frameWidth, 0, frameWidth, image.naturalHeight,
  #|       -width / 2, -height, width, height,
  #|     );
  #|     if (workColor) {
  #|       context.fillStyle = workColor;
  #|       context.beginPath();
  #|       context.arc(width * 0.42, -height * 0.9, Math.max(2, height * 0.08),
  #|         0, Math.PI * 2);
  #|       context.fill();
  #|       context.strokeStyle = "rgba(2,6,23,0.82)";
  #|       context.lineWidth = Math.max(1, zoom * 1.4);
  #|       context.stroke();
  #|     }
  #|   }
  #|   context.restore();
  #| }

///|
fn golden_screen_x(
  world_x : Double,
  world_y : Double,
  viewport_width : Int,
) -> Double {
  ((world_x - world_y) * 32.0 - golden_valley_camera_x()) *
  golden_valley_camera_zoom() +
  viewport_width.to_double() / 2.0
}

///|
fn golden_screen_y(
  world_x : Double,
  world_y : Double,
  viewport_height : Int,
) -> Double {
  ((world_x + world_y) * 16.0 - golden_valley_camera_y()) *
  golden_valley_camera_zoom() +
  viewport_height.to_double() / 2.0
}

///|
fn golden_diamond(
  context : @dom.CanvasRenderingContext2D,
  x : Double,
  y : Double,
) -> Unit {
  let half_width = 32.0 * golden_valley_camera_zoom()
  let half_height = 16.0 * golden_valley_camera_zoom()
  context.begin_path()
  context.move_to(x, y - half_height)
  context.line_to(x + half_width, y)
  context.line_to(x, y + half_height)
  context.line_to(x - half_width, y)
  context.close_path()
}

///|
fn golden_draw_tile(
  context : @dom.CanvasRenderingContext2D,
  snapshot : @energy_valley_contract.TownSnapshot,
  roads : Map[String, TownCanvasRoadCell],
  x : Int,
  y : Int,
  viewport_width : Int,
  viewport_height : Int,
) -> Unit {
  let sx = golden_screen_x(
    x.to_double() + 0.5,
    y.to_double() + 0.5,
    viewport_width,
  )
  let sy = golden_screen_y(
    x.to_double() + 0.5,
    y.to_double() + 0.5,
    viewport_height,
  )
  if sx < -80.0 ||
    sx > viewport_width.to_double() + 80.0 ||
    sy < -80.0 ||
    sy > viewport_height.to_double() + 80.0 {
    return
  }
  let road = roads.get(town_canvas_road_key(x, y))
  let terrain = town_snapshot_canvas_terrain(snapshot, road, x, y)
  let variation = town_snapshot_canvas_variation(snapshot, x, y)
  golden_diamond(context, sx, sy)
  if terrain == "water" || terrain == "bridge" {
    golden_draw_water_detail(
      context,
      sx,
      sy,
      golden_valley_camera_zoom(),
      x.to_double() * 0.31 + y.to_double() * 0.57,
      golden_animation_seconds(),
    )
  } else if terrain == "road" {
    golden_draw_ground_detail(
      context,
      "urban",
      sx,
      sy,
      golden_valley_camera_zoom(),
      variation,
      x + y,
      false,
    )
  } else {
    golden_draw_ground_detail(
      context,
      terrain,
      sx,
      sy,
      golden_valley_camera_zoom(),
      variation,
      x + y,
      false,
    )
  }
  if terrain == "bridge" {
    golden_draw_bridge_detail(context, sx, sy, golden_valley_camera_zoom())
  }
}

///|
fn golden_draw_road_overlay_tile(
  context : @dom.CanvasRenderingContext2D,
  road : TownCanvasRoadCell?,
  x : Int,
  y : Int,
  viewport_width : Int,
  viewport_height : Int,
) -> Unit {
  let semantic_road = match road {
    Some(value) if !value.bridge => value
    _ => return
  }
  let sx = golden_screen_x(
    x.to_double() + 0.5,
    y.to_double() + 0.5,
    viewport_width,
  )
  let sy = golden_screen_y(
    x.to_double() + 0.5,
    y.to_double() + 0.5,
    viewport_height,
  )
  if sx < -120.0 ||
    sx > viewport_width.to_double() + 120.0 ||
    sy < -120.0 ||
    sy > viewport_height.to_double() + 120.0 {
    return
  }
  golden_draw_road_detail(
    context,
    sx,
    sy,
    golden_valley_camera_zoom(),
    semantic_road.mask,
    semantic_road.road_class is @energy_valley_contract.Arterial,
  )
}

///|
extern "js" fn golden_draw_iso_box(
  context : @dom.CanvasRenderingContext2D,
  sx : Double,
  sy : Double,
  width : Double,
  depth : Double,
  height : Double,
  roof : String,
  left : String,
  right : String,
) -> Unit =
  #| (context, sx, sy, width, depth, height, roof, left, right) => {
  #|   const camera = globalThis.__moontownGoldenValleyCamera || { z: 0.1 };
  #|   const zoom = camera.z;
  #|   const scaledHeight = height * zoom / 0.95;
  #|   const halfWidth = 16 * zoom;
  #|   const halfHeight = 8 * zoom;
  #|   const topY = sy - scaledHeight;
  #|   const north = [
  #|     sx + (depth - width) * halfWidth,
  #|     topY - (width + depth) * halfHeight,
  #|   ];
  #|   const east = [
  #|     sx + (width + depth) * halfWidth,
  #|     topY + (width - depth) * halfHeight,
  #|   ];
  #|   const south = [
  #|     sx + (width - depth) * halfWidth,
  #|     topY + (width + depth) * halfHeight,
  #|   ];
  #|   const west = [
  #|     sx - (width + depth) * halfWidth,
  #|     topY + (depth - width) * halfHeight,
  #|   ];
  #|   const parse = hex => {
  #|     const value = hex.replace("#", "");
  #|     const full = value.length === 3
  #|       ? value.split("").map(ch => ch + ch).join("")
  #|       : value;
  #|     return [
  #|       parseInt(full.slice(0, 2), 16),
  #|       parseInt(full.slice(2, 4), 16),
  #|       parseInt(full.slice(4, 6), 16),
  #|     ];
  #|   };
  #|   const clamp = value => Math.max(0, Math.min(255, Math.round(value)));
  #|   const shade = (hex, amount) => {
  #|     const [r, g, b] = parse(hex);
  #|     const lift = amount >= 0
  #|       ? channel => channel + (255 - channel) * amount
  #|       : channel => channel * (1 + amount);
  #|     return `rgb(${clamp(lift(r))},${clamp(lift(g))},${clamp(lift(b))})`;
  #|   };
  #|   const fillPoly = points => {
  #|     context.beginPath();
  #|     context.moveTo(points[0][0], points[0][1]);
  #|     for (let index = 1; index < points.length; index += 1) {
  #|       context.lineTo(points[index][0], points[index][1]);
  #|     }
  #|     context.closePath();
  #|   };
  #|   // Left face: vertical gradient, lighter near the roof, darker at base.
  #|   const leftTop = topY + Math.min(west[1], south[1]) + halfHeight * 0.4;
  #|   const leftGradient = context.createLinearGradient(
  #|     0, leftTop, 0, leftTop + scaledHeight,
  #|   );
  #|   leftGradient.addColorStop(0, shade(left, 0.10));
  #|   leftGradient.addColorStop(1, shade(left, -0.22));
  #|   fillPoly([
  #|     west,
  #|     south,
  #|     [south[0], south[1] + scaledHeight],
  #|     [west[0], west[1] + scaledHeight],
  #|   ]);
  #|   context.fillStyle = leftGradient;
  #|   context.fill();
  #|   // Right face: vertical gradient, slightly darker overall than the left.
  #|   const rightTop = topY + Math.min(south[1], east[1]) + halfHeight * 0.4;
  #|   const rightGradient = context.createLinearGradient(
  #|     0, rightTop, 0, rightTop + scaledHeight,
  #|   );
  #|   rightGradient.addColorStop(0, shade(right, 0.04));
  #|   rightGradient.addColorStop(1, shade(right, -0.26));
  #|   fillPoly([
  #|     south,
  #|     east,
  #|     [east[0], east[1] + scaledHeight],
  #|     [south[0], south[1] + scaledHeight],
  #|   ]);
  #|   context.fillStyle = rightGradient;
  #|   context.fill();
  #|   // Roof: soft diagonal sheen from the sun-facing corner.
  #|   const roofGradient = context.createLinearGradient(
  #|     north[0], north[1], south[0], south[1],
  #|   );
  #|   roofGradient.addColorStop(0, shade(roof, 0.18));
  #|   roofGradient.addColorStop(0.5, roof);
  #|   roofGradient.addColorStop(1, shade(roof, -0.10));
  #|   fillPoly([north, east, south, west]);
  #|   context.fillStyle = roofGradient;
  #|   context.fill();
  #|   // Roof rim highlight + outer edge definition so the box reads crisply.
  #|   context.lineJoin = "round";
  #|   context.lineWidth = Math.max(1, zoom * 1.1);
  #|   context.strokeStyle = shade(roof, -0.28);
  #|   fillPoly([north, east, south, west]);
  #|   context.stroke();
  #|   // Bright top edges (north-west / north-east) catch the light.
  #|   context.beginPath();
  #|   context.moveTo(west[0], west[1]);
  #|   context.lineTo(north[0], north[1]);
  #|   context.lineTo(east[0], east[1]);
  #|   context.strokeStyle = shade(roof, 0.32);
  #|   context.lineWidth = Math.max(1, zoom * 1.2);
  #|   context.stroke();
  #| }

///|
fn golden_building_colors(style : String) -> (String, String, String) {
  match style {
    "tower" => ("#bcd8e8", "#6f9cbd", "#54799a")
    "custom-tower" => ("#d8c8e8", "#9a7fbd", "#7a619a")
    "lab" => ("#d5e8dd", "#8fb8a0", "#729a84")
    "custom-lab" => ("#e8ddd0", "#b8a08f", "#9a8472")
    "garden" => ("#69b56a", "#4d8a52", "#3f7345")
    "home" => ("#f0d8c8", "#c89880", "#a87a64")
    "custom-home" => ("#e0e8f0", "#98a8b8", "#7c8c9c")
    "radar" => ("#d0d8e0", "#98a4b0", "#7e8a96")
    "market" => ("#e8a83a", "#b98242", "#966735")
    "plaza" => ("#ddd6c4", "#b5ad99", "#98917d")
    _ => ("#e8e0cf", "#b8ad97", "#9a9080")
  }
}

///|
fn town_snapshot_place_work_status(
  snapshot : @energy_valley_contract.TownSnapshot,
  place_id : @energy_valley_contract.StableId,
) -> String {
  let mut rank = 0
  let mut status = ""
  for presence in snapshot.presences_at(place_id) {
    match snapshot.find_actor_profile(presence.actor_id) {
      Some(profile) if profile.source_kind
        is @energy_valley_contract.RuntimeEvidence => {
        let (candidate_rank, candidate_status) = match profile.state {
          @energy_valley_contract.ActorStateFailed => (7, "failed")
          @energy_valley_contract.ActorStateBlocked => (6, "blocked")
          @energy_valley_contract.ActorStateWaitingReview =>
            (5, "waiting_review")
          @energy_valley_contract.ActorStateActive => (4, "running")
          @energy_valley_contract.ActorStateAssigned => (3, "assigned")
          @energy_valley_contract.ActorStateCompleted => (2, "completed")
          @energy_valley_contract.ActorStateIdle => (1, "idle")
        }
        if candidate_rank > rank {
          rank = candidate_rank
          status = candidate_status
        }
      }
      _ => ()
    }
  }
  status
}

///|
fn golden_draw_building(
  context : @dom.CanvasRenderingContext2D,
  building : TownCanvasBuilding,
  selected : Bool,
  work_status : String,
  viewport_width : Int,
  viewport_height : Int,
  hour : Double,
) -> Unit {
  let center_x = building.x.to_double() + building.width.to_double() / 2.0
  let center_y = building.y.to_double() + building.depth.to_double() / 2.0
  let sx = golden_screen_x(center_x, center_y, viewport_width)
  let sy = golden_screen_y(center_x, center_y, viewport_height)
  let height = building.floors.to_double() * 24.7
  let (roof, left, right) = golden_building_colors(building.style)
  golden_draw_reference_building_shadow(
    context,
    sx,
    sy,
    building.width.to_double(),
    building.depth.to_double(),
    golden_valley_camera_zoom(),
  )
  if building.style == "market" {
    for column in 0..<2 {
      for row in 0..<2 {
        let stall_x = building.x.to_double() +
          column.to_double() * building.width.to_double() / 2.0 +
          0.08
        let stall_y = building.y.to_double() +
          row.to_double() * building.depth.to_double() / 2.0 +
          0.08
        let stall_width = building.width.to_double() / 2.0 - 0.15
        let stall_depth = building.depth.to_double() / 2.0 - 0.15
        let stall_center_x = stall_x + stall_width / 2.0
        let stall_center_y = stall_y + stall_depth / 2.0
        golden_draw_iso_box(
          context,
          golden_screen_x(stall_center_x, stall_center_y, viewport_width),
          golden_screen_y(stall_center_x, stall_center_y, viewport_height),
          stall_width,
          stall_depth,
          6.65,
          "#f0ead8",
          "#c8bfa8",
          "#aaa28c",
        )
      }
    }
  } else if building.style == "home" || building.style == "custom-home" {
    let half_width = building.width.to_double() / 2.0
    let first_center_x = building.x.to_double() + half_width / 2.0
    let first_center_y = building.y.to_double() +
      building.depth.to_double() / 2.0
    golden_draw_iso_box(
      context,
      golden_screen_x(first_center_x, first_center_y, viewport_width),
      golden_screen_y(first_center_x, first_center_y, viewport_height),
      half_width,
      building.depth.to_double(),
      height * 0.85,
      roof,
      left,
      right,
    )
    let second_depth = building.depth.to_double() - 0.3
    let second_center_x = building.x.to_double() + half_width + half_width / 2.0
    let second_center_y = building.y.to_double() + 0.3 + second_depth / 2.0
    golden_draw_iso_box(
      context,
      golden_screen_x(second_center_x, second_center_y, viewport_width),
      golden_screen_y(second_center_x, second_center_y, viewport_height),
      half_width,
      second_depth,
      height,
      if building.style == "custom-home" {
        roof
      } else {
        "#e8e0d0"
      },
      if building.style == "custom-home" {
        left
      } else {
        "#b0a894"
      },
      if building.style == "custom-home" {
        right
      } else {
        "#948c78"
      },
    )
  } else if building.style == "tower" || building.style == "custom-tower" {
    let rear_depth = building.depth.to_double() - 0.6
    let rear_center_x = building.x.to_double() +
      building.width.to_double() / 2.0
    let rear_center_y = building.y.to_double() + 0.6 + rear_depth / 2.0
    golden_draw_iso_box(
      context,
      golden_screen_x(rear_center_x, rear_center_y, viewport_width),
      golden_screen_y(rear_center_x, rear_center_y, viewport_height),
      building.width.to_double(),
      rear_depth,
      height,
      roof,
      left,
      right,
    )
    let front_width = building.width.to_double() - 0.3
    let front_center_x = building.x.to_double() + 0.3 + front_width / 2.0
    let front_center_y = building.y.to_double() + 0.3
    golden_draw_iso_box(
      context,
      golden_screen_x(front_center_x, front_center_y, viewport_width),
      golden_screen_y(front_center_x, front_center_y, viewport_height),
      front_width,
      0.6,
      height + 7.6,
      roof,
      left,
      right,
    )
  } else {
    let body_height = if building.style == "garden" {
      4.75
    } else if building.style == "plaza" {
      3.8
    } else if building.style == "radar" {
      height * 0.6
    } else {
      height
    }
    golden_draw_iso_box(
      context,
      sx,
      sy,
      building.width.to_double(),
      building.depth.to_double(),
      body_height,
      roof,
      left,
      right,
    )
  }
  if building.style != "garden" &&
    building.style != "plaza" &&
    building.style != "market" {
    let columns = if building.width * 2 < 2 { 2 } else { building.width * 2 }
    let lit_fraction = if hour < 6.0 || hour >= 19.0 { 0.62 } else { 0.0 }
    golden_draw_iso_windows(
      context,
      sx,
      sy,
      building.width.to_double(),
      building.depth.to_double(),
      if building.style == "radar" {
        height * 0.6
      } else {
        height
      },
      golden_valley_camera_zoom(),
      columns,
      building.floors,
      lit_fraction,
    )
  }
  if building.style == "lab" || building.style == "custom-lab" {
    let first_center_x = building.x.to_double() + 0.6
    let first_center_y = building.y.to_double() + 0.6
    golden_draw_iso_box(
      context,
      golden_screen_x(first_center_x, first_center_y, viewport_width),
      golden_screen_y(first_center_x, first_center_y, viewport_height),
      0.6,
      0.6,
      height + 4.75,
      "#aabbcc",
      "#888899",
      "#777788",
    )
    let second_center_x = building.x.to_double() +
      building.width.to_double() -
      0.65
    let second_center_y = building.y.to_double() + 0.65
    golden_draw_iso_box(
      context,
      golden_screen_x(second_center_x, second_center_y, viewport_width),
      golden_screen_y(second_center_x, second_center_y, viewport_height),
      0.5,
      0.5,
      height + 3.325,
      "#bbbbaa",
      "#999988",
      "#887777",
    )
  }
  golden_draw_reference_building_details(
    context,
    building.style,
    building.x.to_double(),
    building.y.to_double(),
    building.width.to_double(),
    building.depth.to_double(),
    height,
    viewport_width,
    viewport_height,
    golden_animation_seconds(),
    selected,
  )
  if building.style == "garden" {
    let tree_x = building.x.to_double() + 0.5
    let tree_y = building.y.to_double() + building.depth.to_double() - 0.5
    golden_draw_reference_tree(
      context,
      golden_screen_x(tree_x, tree_y, viewport_width),
      golden_screen_y(tree_x, tree_y, viewport_height),
      golden_valley_camera_zoom() * 0.8,
      golden_reference_hash("civic-ai-garden-\{building.x}-\{building.y}"),
      golden_animation_seconds(),
    )
  }
  let zoom = golden_valley_camera_zoom()
  let label_x = if building.style == "tower" || building.style == "custom-tower" {
    let front_width = building.width.to_double() - 0.3
    golden_screen_x(
      building.x.to_double() + 0.3 + front_width / 2.0,
      building.y.to_double() + 0.3,
      viewport_width,
    )
  } else if building.style == "home" || building.style == "custom-home" {
    let half_width = building.width.to_double() / 2.0
    let second_depth = building.depth.to_double() - 0.3
    golden_screen_x(
      building.x.to_double() + half_width + half_width / 2.0,
      building.y.to_double() + 0.3 + second_depth / 2.0,
      viewport_width,
    )
  } else {
    sx
  }
  let top_center_y = if building.style == "garden" {
    sy - 18.0 * zoom
  } else if building.style == "plaza" {
    sy - 14.0 * zoom
  } else if building.style == "market" {
    sy
  } else if building.style == "radar" {
    sy - height * 0.6 * zoom / 0.95
  } else if building.style == "tower" || building.style == "custom-tower" {
    sy - (height + 7.6) * zoom / 0.95
  } else {
    sy - height * zoom / 0.95
  }
  let font_size = if 11.0 * zoom < 10.0 { 10.0 } else { 11.0 * zoom }
  golden_ctx_font(
    context,
    "\{font_size}px \"PingFang SC\", \"Microsoft YaHei\", sans-serif",
  )
  golden_ctx_text_align(context, "center")
  golden_ctx_text_baseline(context, "middle")
  let label_y = top_center_y - 14.0 * zoom
  if zoom > 0.75 {
    let label_width = golden_ctx_measure_text(context, building.name)
    golden_ctx_fill_style(context, "rgba(12,20,36,.72)")
    context.begin_path()
    context.round_rect(
      label_x - label_width / 2.0 - 6.0,
      label_y - 9.0,
      label_width + 12.0,
      16.0,
      8.0,
    )
    context.fill()
    golden_ctx_fill_style(context, "#ffe9b8")
    context.fill_text(building.name, label_x, label_y)
  }
  if !work_status.is_empty() {
    let color = golden_valley_work_status_color(work_status)
    let pulse = (golden_math_sin(golden_animation_seconds() * 4.5) + 1.0) / 2.0
    let beacon_y = top_center_y - 25.0 * zoom
    golden_ctx_fill_style(context, color)
    context.begin_path()
    context.arc(label_x, beacon_y, 3.2 * zoom, 0.0, 6.29)
    context.fill()
    if work_status == "running" ||
      work_status == "waiting_review" ||
      work_status == "blocked" {
      golden_ctx_stroke_style(context, color)
      golden_ctx_global_alpha(context, 0.25 + pulse * 0.4)
      golden_ctx_line_width(context, 1.3 * zoom)
      context.begin_path()
      context.arc(label_x, beacon_y, (6.0 + pulse * 5.0) * zoom, 0.0, 6.29)
      context.stroke()
      golden_ctx_global_alpha(context, 1.0)
    }
  }
}

///|
fn golden_draw_agents_at_depth(
  context : @dom.CanvasRenderingContext2D,
  agents : Array[GoldenValleyCanvasAgent],
  depth : Int,
  viewport_width : Int,
  viewport_height : Int,
) -> Unit {
  for agent in agents {
    if (agent.x + agent.y + 0.45).floor().to_int() != depth {
      continue
    }
    let sx = golden_screen_x(agent.x, agent.y, viewport_width)
    let sy = golden_screen_y(agent.x, agent.y, viewport_height)
    if sx < -30.0 ||
      sx > viewport_width.to_double() + 30.0 ||
      sy < -30.0 ||
      sy > viewport_height.to_double() + 30.0 {
      continue
    }
    golden_draw_sprite_agent(
      context,
      sx,
      sy,
      if golden_valley_camera_zoom() < 0.32 {
        0.32
      } else {
        golden_valley_camera_zoom()
      },
      agent.sprite_path,
      agent.facing_left,
      agent.bob,
      agent.work_color,
      agent.activity_glyph,
      agent.activity_label,
      agent.preview,
      agent.selected,
    )
  }
}

///|
fn golden_draw_weather(
  context : @dom.CanvasRenderingContext2D,
  weather : EnergyWeather,
  tick : Int,
  viewport_width : Int,
  viewport_height : Int,
) -> Unit {
  match weather {
    Sunny => ()
    Cloudy => {
      golden_ctx_fill_style(context, "rgba(91,107,125,.13)")
      context.fill_rect(
        0.0,
        0.0,
        viewport_width.to_double(),
        viewport_height.to_double(),
      )
    }
    Rain => {
      golden_ctx_stroke_style(context, "rgba(166,211,235,.42)")
      golden_ctx_line_width(context, 1.0)
      for index in 0..<130 {
        let x = energy_valley_variation(
          active_energy_valley_seed(),
          index,
          tick,
          281,
          viewport_width,
        )
        let y = energy_valley_variation(
          active_energy_valley_seed(),
          index,
          tick,
          283,
          viewport_height,
        )
        context.begin_path()
        context.move_to(x.to_double(), y.to_double())
        context.line_to(x.to_double() - 4.0, y.to_double() + 11.0)
        context.stroke()
      }
    }
    Snow => {
      golden_ctx_fill_style(context, "rgba(240,248,255,.66)")
      for index in 0..<95 {
        let x = energy_valley_variation(
          active_energy_valley_seed(),
          index,
          tick / 2,
          293,
          viewport_width,
        )
        let y = energy_valley_variation(
          active_energy_valley_seed(),
          index,
          tick,
          307,
          viewport_height,
        )
        let size = 0.8 +
          energy_valley_variation(
            active_energy_valley_seed(),
            index,
            1,
            311,
            18,
          ).to_double() /
          10.0
        context.begin_path()
        context.arc(x.to_double(), y.to_double(), size, 0.0, 6.29)
        context.fill()
      }
    }
  }
}

///|
fn town_canvas_follow_position(view : TownCanvasViewState) -> (Double, Double)? {
  if !view.follow_enabled {
    return None
  }
  match view.player_motion {
    Some(motion) => {
      let elapsed = golden_animation_seconds() - motion.started_seconds
      if elapsed < 0.0 {
        return Some((motion.from_x, motion.from_y))
      }
      let walked = elapsed * player_walk_speed
      let total = player_path_length(motion.path)
      if walked >= total {
        Some(player_point_along(motion.path, total))
      } else {
        Some(player_point_along(motion.path, walked))
      }
    }
    None => view.player_idle_position
  }
}

///|
fn draw_golden_valley_canvas(
  snapshot : @energy_valley_contract.TownSnapshot,
  view : TownCanvasViewState,
) -> Unit {
  let canvas_id = "energy-valley-canvas"
  match town_canvas_follow_position(view) {
    Some((x, y)) => golden_follow_camera(x, y)
    None => ()
  }
  prepare_golden_valley_canvas(canvas_id)
  let width = golden_valley_canvas_width(canvas_id)
  let height = golden_valley_canvas_height(canvas_id)
  match @canvas.get_context2d(canvas_id) {
    None => ()
    Some(context) => {
      context.clear_rect(0.0, 0.0, width.to_double(), height.to_double())
      let hour = view.hour
      golden_draw_background(context, width, height, hour)
      // Every spatial fact below is projected from the immutable snapshot
      // prepared by page orchestration. Canvas never runs world compilation.
      let ecosystem_town_snapshot = snapshot
      let canvas_roads = town_snapshot_canvas_roads(ecosystem_town_snapshot)
      let canvas_road_lookup = town_snapshot_canvas_road_lookup(canvas_roads)
      let canvas_cols = town_snapshot_canvas_cols(ecosystem_town_snapshot)
      let canvas_rows = town_snapshot_canvas_rows(ecosystem_town_snapshot)
      let canvas_installations = town_snapshot_installations_by_depth(
        ecosystem_town_snapshot,
      )
      for y in 0..<canvas_rows {
        for x in 0..<canvas_cols {
          golden_draw_tile(
            context, ecosystem_town_snapshot, canvas_road_lookup, x, y, width, height,
          )
        }
      }
      for y in 0..<canvas_rows {
        for x in 0..<canvas_cols {
          golden_draw_road_overlay_tile(
            context,
            canvas_road_lookup.get(town_canvas_road_key(x, y)),
            x,
            y,
            width,
            height,
          )
        }
      }
      golden_draw_town_snapshot_metro_underlay(
        context,
        ecosystem_town_snapshot,
        view.metro_visible,
        width,
        height,
      )
      // Runtime and public-life overlays consume the same semantic frame.
      golden_draw_ecosystem_pedestrian_spurs(
        context, ecosystem_town_snapshot, width, height,
      )
      let canvas_buildings = town_snapshot_canvas_buildings(
        ecosystem_town_snapshot,
      )
      golden_draw_selected_town_snapshot_relations(
        context,
        ecosystem_town_snapshot,
        view.selected_place_id,
        width,
        height,
      )
      golden_draw_active_ecosystem_exchanges(
        context, ecosystem_town_snapshot, width, height,
      )
      let agents = town_snapshot_canvas_agents(
        ecosystem_town_snapshot,
        golden_animation_seconds(),
        golden_prefers_reduced_motion(),
        view.selected_actor_id,
      )
      for depth in 0..<(canvas_cols + canvas_rows) {
        match canvas_installations.get(depth) {
          Some(installations) =>
            golden_draw_town_snapshot_installations(
              context, installations, width, height, hour,
            )
          None => ()
        }
        golden_draw_agents_at_depth(context, agents, depth, width, height)
        for semantic_building in canvas_buildings {
          if semantic_building.x + semantic_building.y + semantic_building.depth ==
            depth {
            let selected = view.selected_place_id ==
              Some(semantic_building.place_id)
            golden_draw_building(
              context,
              semantic_building,
              selected,
              town_snapshot_place_work_status(
                ecosystem_town_snapshot,
                semantic_building.place_id,
              ),
              width,
              height,
              hour,
            )
            golden_draw_ecosystem_place_layer(
              context, ecosystem_town_snapshot, semantic_building, selected, width,
              height,
            )
          }
        }
      }
      golden_draw_town_snapshot_metro_landmarks(
        context,
        ecosystem_town_snapshot,
        view.metro_visible,
        width,
        height,
      )
      golden_draw_weather(context, view.weather, view.tick, width, height)
      golden_draw_day_night(context, width, height, hour)
      golden_ctx_global_alpha(context, 1.0)
      // Publish pointer truth only after this exact semantic frame completed a
      // real draw. A queued-but-not-painted Model must never replace the frame
      // that remains visible to the user.
      golden_valley_accept_canvas_frame_with_runtime_eligibility(
        snapshot,
        view.runtime_agent_interaction_enabled,
      )
    }
  }
}

///|
fn render_golden_valley_canvas(
  dispatch : Dispatch[Msg],
  snapshot : @energy_valley_contract.TownSnapshot,
  view : TownCanvasViewState,
) -> @rabbita.Html {
  schedule_golden_valley_canvas(() => draw_golden_valley_canvas(snapshot, view))
  schedule_golden_valley_canvas(() => {
    install_golden_valley_canvas_input(() => {
      draw_golden_valley_canvas(snapshot, view)
    })
    install_player_walk_keys()
  })
  canvas(
    id="energy-valley-canvas",
    class="absolute inset-0 h-full w-full cursor-grab active:cursor-grabbing",
    attrs=@html.Attrs::build()
      .aria_label("能源谷可交互等距地图")
      .on_click(_ => {
        dispatch(
          EnergyCanvasClick(golden_valley_action_x(), golden_valley_action_y()),
        )
      }),
    no_children(),
  )
}
