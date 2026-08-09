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
  #| callback => {
  #|   if (typeof globalThis.requestAnimationFrame !== "function") return;
  #|   let schedule = globalThis.__moontownGoldenValleyCanvasSchedule;
  #|   if (!schedule) {
  #|     schedule = { raf: 0, pending: null };
  #|     globalThis.__moontownGoldenValleyCanvasSchedule = schedule;
  #|   }
  #|   schedule.pending = callback;
  #|   if (schedule.raf) return;
  #|   schedule.raf = globalThis.requestAnimationFrame(() => {
  #|     if (globalThis.__moontownGoldenValleyCanvasSchedule !== schedule) return;
  #|     schedule.raf = 0;
  #|     const render = schedule.pending;
  #|     schedule.pending = null;
  #|     if (typeof render === "function") render();
  #|   });
  #| }

///|
extern "js" fn browser_stop_golden_valley_canvas() -> Unit =
  #| () => {
  #|   const lifecycle = globalThis.__moontownGoldenValleyCanvasLifecycle;
  #|   if (typeof lifecycle?.stop === "function") {
  #|     lifecycle.stop(true);
  #|     return;
  #|   }
  #|   const schedule = globalThis.__moontownGoldenValleyCanvasSchedule;
  #|   if (schedule?.raf) {
  #|     globalThis.cancelAnimationFrame?.(schedule.raf);
  #|   }
  #|   if (schedule) {
  #|     schedule.raf = 0;
  #|     schedule.pending = null;
  #|   }
  #|   const canvas = globalThis.document?.getElementById(
  #|     "energy-valley-canvas",
  #|   );
  #|   if (canvas) {
  #|     delete canvas.dataset.goldenInput;
  #|     canvas.width = 0;
  #|     canvas.height = 0;
  #|   }
  #|   delete globalThis.__moontownGoldenValleyCanvasSchedule;
  #|   delete globalThis.__moontownGoldenValleyRender;
  #|   delete globalThis.__moontownStopGoldenValleyCanvas;
  #| }

///|
fn stop_golden_valley_canvas() -> Unit {
  browser_stop_golden_valley_canvas()
  golden_valley_clear_canvas_frame()
}

///|
extern "js" fn install_golden_valley_canvas_input(
  render_callback : () -> Unit,
  release_frame_callback : () -> Unit,
) -> Unit =
  #| (renderCallback, releaseFrameCallback) => {
  #|   const canvas = globalThis.document?.getElementById("energy-valley-canvas");
  #|   if (!canvas) {
  #|     const lifecycle = globalThis.__moontownGoldenValleyCanvasLifecycle;
  #|     if (typeof lifecycle?.stop === "function") lifecycle.stop(true);
  #|     else {
  #|       const schedule = globalThis.__moontownGoldenValleyCanvasSchedule;
  #|       if (schedule?.raf) globalThis.cancelAnimationFrame?.(schedule.raf);
  #|       if (schedule) {
  #|         schedule.raf = 0;
  #|         schedule.pending = null;
  #|       }
  #|       delete globalThis.__moontownGoldenValleyCanvasSchedule;
  #|       delete globalThis.__moontownGoldenValleyRender;
  #|       releaseFrameCallback();
  #|     }
  #|     return;
  #|   }
  #|   let lifecycle = globalThis.__moontownGoldenValleyCanvasLifecycle;
  #|   if (lifecycle && (!lifecycle.running || lifecycle.canvas !== canvas)) {
  #|     // Drawing has already accepted the replacement Canvas frame, so stop
  #|     // the detached owner without clearing that newly accepted authority.
  #|     lifecycle.stop(false);
  #|     lifecycle = null;
  #|   }
  #|   if (lifecycle) {
  #|     lifecycle.render = renderCallback;
  #|     lifecycle.releaseFrame = releaseFrameCallback;
  #|     return;
  #|   }
  #|   lifecycle = {
  #|     canvas,
  #|     render: renderCallback,
  #|     releaseFrame: releaseFrameCallback,
  #|     running: true,
  #|     animationRaf: 0,
  #|     transientRafs: new Set(),
  #|     cleanups: [],
  #|     lastPaint: 0,
  #|     stop: null,
  #|     invoke: null,
  #|   };
  #|   globalThis.__moontownGoldenValleyCanvasLifecycle = lifecycle;
  #|   const invoke = () => {
  #|     if (globalThis.__moontownGoldenValleyCanvasLifecycle === lifecycle &&
  #|         lifecycle.running) lifecycle.render?.();
  #|   };
  #|   lifecycle.invoke = invoke;
  #|   globalThis.__moontownGoldenValleyRender = invoke;
  #|   const stopLifecycle = (
  #|     clearAcceptedFrame = true,
  #|     preservePendingPaint = false,
  #|   ) => {
  #|     if (!lifecycle.running) return;
  #|     lifecycle.running = false;
  #|     const schedule = globalThis.__moontownGoldenValleyCanvasSchedule;
  #|     if (!preservePendingPaint) {
  #|       if (schedule?.raf) globalThis.cancelAnimationFrame?.(schedule.raf);
  #|       if (schedule) {
  #|         schedule.raf = 0;
  #|         schedule.pending = null;
  #|       }
  #|     }
  #|     if (lifecycle.animationRaf) {
  #|       globalThis.cancelAnimationFrame?.(lifecycle.animationRaf);
  #|       lifecycle.animationRaf = 0;
  #|     }
  #|     for (const raf of lifecycle.transientRafs) {
  #|       globalThis.cancelAnimationFrame?.(raf);
  #|     }
  #|     lifecycle.transientRafs.clear();
  #|     for (const cleanup of lifecycle.cleanups.splice(0).reverse()) {
  #|       try { cleanup(); } catch (_) {}
  #|     }
  #|     const ownedCanvas = lifecycle.canvas;
  #|     if (ownedCanvas) {
  #|       delete ownedCanvas.dataset.goldenInput;
  #|       ownedCanvas.width = 0;
  #|       ownedCanvas.height = 0;
  #|     }
  #|     const releaseFrame = lifecycle.releaseFrame;
  #|     lifecycle.canvas = null;
  #|     lifecycle.render = null;
  #|     lifecycle.releaseFrame = null;
  #|     lifecycle.invoke = null;
  #|     if (globalThis.__moontownGoldenValleyCanvasLifecycle === lifecycle) {
  #|       delete globalThis.__moontownGoldenValleyCanvasLifecycle;
  #|       if (!preservePendingPaint) {
  #|         delete globalThis.__moontownGoldenValleyCanvasSchedule;
  #|       }
  #|       if (globalThis.__moontownGoldenValleyRender === invoke) {
  #|         delete globalThis.__moontownGoldenValleyRender;
  #|       }
  #|       if (globalThis.__moontownStopGoldenValleyCanvas === stopLifecycle) {
  #|         delete globalThis.__moontownStopGoldenValleyCanvas;
  #|       }
  #|       delete globalThis.__moontownGoldenValleyKeys;
  #|       delete globalThis.__moontownGoldenValleyAnimation;
  #|     }
  #|     if (clearAcceptedFrame) releaseFrame?.();
  #|   };
  #|   lifecycle.stop = stopLifecycle;
  #|   globalThis.__moontownStopGoldenValleyCanvas = stopLifecycle;
  #|   canvas.dataset.goldenInput = "1";
  #|   const viewportWidth = canvas.clientWidth || globalThis.innerWidth || 1280;
  #|   const viewportHeight = canvas.clientHeight || globalThis.innerHeight || 720;
  #|   const civicZoom = viewportWidth < 640
  #|     ? 0.34
  #|     : viewportWidth < 1100 || viewportHeight < 800 ? 0.42 : 0.5;
  #|   globalThis.__moontownGoldenValleyCamera ||= {
  #|     x: 1792, y: 3200, z: civicZoom,
  #|   };
  #|   const camera = globalThis.__moontownGoldenValleyCamera;
  #|   // Migrate only untouched historical overview presets. Deliberate pans
  #|   // and zooms stay intact while new sessions open on seven civic heroes.
  #|   const artVersion = globalThis.__moontownGoldenValleyCameraArtVersion ?? 0;
  #|   const legacyOverview = camera.z <= 0.101 ||
  #|     (artVersion === 2 && Math.abs(camera.z - 0.25) < 0.001);
  #|   if (artVersion < 3 && legacyOverview &&
  #|       Math.abs(camera.x - 1792) < 0.01 &&
  #|       Math.abs(camera.y - 3200) < 0.01) {
  #|     camera.z = civicZoom;
  #|   }
  #|   globalThis.__moontownGoldenValleyCameraArtVersion = 3;
  #|   let cameraDragging = false;
  #|   let painting = false;
  #|   let moved = false;
  #|   let activePointerId = null;
  #|   let lastX = 0;
  #|   let lastY = 0;
  #|   const listen = (target, name, handler, options) => {
  #|     if (typeof target?.addEventListener !== "function") return;
  #|     target.addEventListener(name, handler, options);
  #|     lifecycle.cleanups.push(() => {
  #|       target.removeEventListener?.(name, handler, options);
  #|     });
  #|   };
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
  #|   const onPointerDown = event => {
  #|     if (event.button === 0) rememberAction(event);
  #|     if (event.button === 1 || event.button === 2 ||
  #|         (event.button === 0 && inspectSelected())) {
  #|       cameraDragging = true;
  #|       moved = false;
  #|       lastX = event.clientX;
  #|       lastY = event.clientY;
  #|       activePointerId = event.pointerId;
  #|       canvas.setPointerCapture?.(event.pointerId);
  #|     } else if (event.button === 0) {
  #|       painting = paintSelected();
  #|       if (painting) {
  #|         activePointerId = event.pointerId;
  #|         canvas.setPointerCapture?.(event.pointerId);
  #|       }
  #|     }
  #|   };
  #|   const onPointerMove = event => {
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
  #|   };
  #|   const stopPointer = event => {
  #|     cameraDragging = false;
  #|     painting = false;
  #|     canvas.releasePointerCapture?.(event.pointerId);
  #|     activePointerId = null;
  #|   };
  #|   const onPointerUp = event => stopPointer(event);
  #|   const onClick = event => {
  #|     if (moved) event.stopImmediatePropagation();
  #|     moved = false;
  #|   };
  #|   const onContextMenu = event => event.preventDefault();
  #|   const onWheel = event => {
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
  #|   };
  #|   listen(canvas, "pointerdown", onPointerDown);
  #|   listen(canvas, "pointermove", onPointerMove);
  #|   listen(canvas, "pointerup", onPointerUp);
  #|   listen(canvas, "pointercancel", stopPointer);
  #|   listen(canvas, "click", onClick, true);
  #|   listen(canvas, "contextmenu", onContextMenu);
  #|   listen(canvas, "wheel", onWheel, { passive: false });
  #|   lifecycle.cleanups.push(() => {
  #|     cameraDragging = false;
  #|     painting = false;
  #|     if (activePointerId !== null) {
  #|       canvas.releasePointerCapture?.(activePointerId);
  #|       activePointerId = null;
  #|     }
  #|   });
  #|   globalThis.__moontownGoldenValleyKeys = true;
  #|   const onKeyDown = event => {
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
  #|         if (restoreLabel &&
  #|             typeof globalThis.requestAnimationFrame === "function") {
  #|           let focusRaf = 0;
  #|           focusRaf = globalThis.requestAnimationFrame(() => {
  #|             lifecycle.transientRafs.delete(focusRaf);
  #|             if (!lifecycle.running) return;
  #|             globalThis.document?.querySelector(
  #|               `button[aria-label="${restoreLabel}"]`,
  #|             )?.focus();
  #|           });
  #|           lifecycle.transientRafs.add(focusRaf);
  #|         }
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
  #|   };
  #|   listen(globalThis, "keydown", onKeyDown);
  #|   globalThis.__moontownGoldenValleyAnimation = true;
  #|   const motion = globalThis.matchMedia?.(
  #|     "(prefers-reduced-motion: reduce)",
  #|   );
  #|   const onMotionChange = () => invoke();
  #|   listen(motion, "change", onMotionChange);
  #|   const frame = timestamp => {
  #|     lifecycle.animationRaf = 0;
  #|     if (!lifecycle.running ||
  #|         globalThis.__moontownGoldenValleyCanvasLifecycle !== lifecycle) {
  #|       return;
  #|     }
  #|     const mounted = globalThis.document?.getElementById(
  #|       "energy-valley-canvas",
  #|     );
  #|     if (mounted !== lifecycle.canvas ||
  #|         lifecycle.canvas?.isConnected === false) {
  #|       const replacementMounted = Boolean(
  #|         mounted && mounted !== lifecycle.canvas &&
  #|         mounted.isConnected !== false,
  #|       );
  #|       lifecycle.stop(true, replacementMounted);
  #|       return;
  #|     }
  #|     // The map remains interactive under reduced motion, but continuous
  #|     // canvas animation is suppressed. Normal motion is capped at 30fps.
  #|     if (!motion?.matches && !globalThis.document?.hidden &&
  #|         timestamp - lifecycle.lastPaint >= 33) {
  #|       lifecycle.lastPaint = timestamp;
  #|       invoke();
  #|     }
  #|     if (lifecycle.running) {
  #|       lifecycle.animationRaf = globalThis.requestAnimationFrame(frame);
  #|     }
  #|   };
  #|   lifecycle.animationRaf = globalThis.requestAnimationFrame(frame);
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
  #| () => globalThis.__moontownGoldenValleyCamera?.z ?? (
  #|   globalThis.innerWidth < 640
  #|     ? 0.34
  #|     : globalThis.innerWidth < 1100 || globalThis.innerHeight < 800
  #|       ? 0.42
  #|       : 0.5
  #| )

///|
extern "js" fn golden_focus_building_camera(
  world_x : Double,
  world_y : Double,
) -> Unit =
  #| (worldX, worldY) => {
  #|   const civicZoom = globalThis.innerWidth < 640
  #|     ? 0.34
  #|     : globalThis.innerWidth < 1100 || globalThis.innerHeight < 800
  #|       ? 0.42
  #|       : 0.5;
  #|   globalThis.__moontownGoldenValleyCamera ||= {
  #|     x: 1792, y: 3200, z: civicZoom,
  #|   };
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
  #|   // Clear civic blue: two calm values keep the waterfront legible
  #|   // without turning every water tile into a textured effect.
  #|   gradient.addColorStop(0, "#35a8ce");
  #|   gradient.addColorStop(1, "#238caf");
  #|   context.fillStyle = gradient;
  #|   context.fill();
  #|   if (zoom < 0.24) return;
  #|   context.save();
  #|   context.clip();
  #|   const progress = (time * 0.16 + phase * 0.11) % 1;
  #|   const offset = (progress - 0.5) * 42 * zoom;
  #|   context.strokeStyle = "rgba(226,248,252,0.46)";
  #|   context.lineWidth = Math.max(0.8, 1.25 * zoom);
  #|   context.beginPath();
  #|   context.moveTo(sx - 17 * zoom + offset * 0.2, sy + offset * 0.32);
  #|   context.quadraticCurveTo(
  #|     sx, sy + offset * 0.32 + 1.5 * zoom,
  #|     sx + 17 * zoom + offset * 0.2, sy + offset * 0.32,
  #|   );
  #|   context.stroke();
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
  #|   // Warm-white kerbs and blue-grey asphalt form a quiet hierarchy.
  #|   // Markings appear progressively so the overview remains a composition,
  #|   // not a mesh of tiny lines.
  #|   context.strokeStyle = major ? "#f5f2e9" : "#e7e5dd";
  #|   context.lineWidth = Math.max(
  #|     major ? 4.8 : 2.8,
  #|     (major ? 21 : 11.5) * zoom,
  #|   );
  #|   context.setLineDash([]);
  #|   traceRoad();
  #|   context.stroke();
  #|   context.strokeStyle = major ? "#62717d" : "#7a858d";
  #|   context.lineWidth = Math.max(
  #|     major ? 3.6 : 2.0,
  #|     (major ? 16.5 : 8.2) * zoom,
  #|   );
  #|   traceRoad();
  #|   context.stroke();
  #|   if ((major && zoom >= 0.28) || (!major && zoom >= 0.62)) {
  #|     context.strokeStyle = "rgba(245,242,233,0.9)";
  #|     context.lineWidth = Math.max(0.7, (major ? 1.35 : 0.9) * zoom);
  #|     context.setLineDash([
  #|       Math.max(3, 6 * zoom),
  #|       Math.max(2.5, 5 * zoom),
  #|     ]);
  #|     traceRoad();
  #|     context.stroke();
  #|   }
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
  #|   context.fillStyle = "#d4d3cc";
  #|   context.fill();
  #|   context.strokeStyle = "#405866";
  #|   context.lineWidth = Math.max(0.8, 1.15 * zoom);
  #|   context.stroke();
  #|   if (zoom >= 0.48) {
  #|     context.strokeStyle = "rgba(245,242,233,0.8)";
  #|     context.lineWidth = Math.max(0.7, zoom);
  #|     context.beginPath();
  #|     context.moveTo(sx - 18 * zoom, sy - 3 * zoom);
  #|     context.lineTo(sx + 18 * zoom, sy - 3 * zoom);
  #|     context.stroke();
  #|   }
  #|   context.strokeStyle = "#20a9d0";
  #|   context.lineWidth = Math.max(0.9, 1.65 * zoom);
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
  #|     // Broad matte color fields make the green spine read at a glance.
  #|     context.fillStyle = shade("#91c467", 0.96 + variation * 0.06);
  #|     context.fill();
  #|     return;
  #|   }
  #|   if (terrain === "meadow") {
  #|     context.fillStyle = shade("#9dcc76", 0.96 + variation * 0.05);
  #|     context.fill();
  #|     if (zoom >= 0.55 && phase % 7 === 0) {
  #|       context.fillStyle = variation > 0.55 ? "#e5b840" : "#efb6bf";
  #|       for (let index = 0; index < 3; index += 1) {
  #|         const px = sx + (index - 1) * 3.2 * zoom;
  #|         const py = sy + ((index % 2) * 2 - 1) * 1.5 * zoom;
  #|       context.beginPath();
  #|         context.arc(px, py, Math.max(0.65, 1.0 * zoom), 0, Math.PI * 2);
  #|       context.fill();
  #|       }
  #|     }
  #|     return;
  #|   }
  #|   if (terrain === "field") {
  #|     context.fillStyle = shade("#b5ca68", 0.95 + variation * 0.05);
  #|     context.fill();
  #|     if (zoom >= 0.45) {
  #|       context.save();
  #|       diamond();
  #|       context.clip();
  #|       context.strokeStyle = "rgba(71,118,75,0.34)";
  #|       context.lineWidth = Math.max(0.8, 1.1 * zoom);
  #|       for (let row = -1; row <= 1; row += 1) {
  #|         context.beginPath();
  #|         context.moveTo(sx - 32 * zoom, sy + row * 6 * zoom);
  #|         context.lineTo(sx + 32 * zoom, sy + row * 6 * zoom);
  #|         context.stroke();
  #|       }
  #|       context.restore();
  #|     }
  #|     return;
  #|   }
  #|   if (terrain === "wetland") {
  #|     context.fillStyle = shade("#79b768", 0.95 + variation * 0.05);
  #|     context.fill();
  #|     context.save();
  #|     diamond();
  #|     context.clip();
  #|     context.fillStyle = "rgba(39,152,194,0.48)";
  #|     context.beginPath();
  #|     context.ellipse(
  #|       sx + (variation - 0.5) * 16 * zoom,
  #|       sy + (variation - 0.5) * 5 * zoom,
  #|       12 * zoom, 3.2 * zoom, 0, 0, Math.PI * 2,
  #|     );
  #|     context.fill();
  #|     if (zoom >= 0.55) {
  #|       context.strokeStyle = "rgba(71,118,75,0.72)";
  #|       context.lineWidth = Math.max(0.8, zoom);
  #|       for (let reed = -1; reed <= 1; reed += 1) {
  #|         const rx = sx + (reed * 6 + variation * 3) * zoom;
  #|         context.beginPath();
  #|         context.moveTo(rx, sy + 3 * zoom);
  #|         context.lineTo(rx + 1.2 * zoom, sy - 2.5 * zoom);
  #|         context.stroke();
  #|       }
  #|     }
  #|     context.restore();
  #|     return;
  #|   }
  #|   if (terrain === "forest") {
  #|     context.fillStyle = shade("#47764b", 0.97 + variation * 0.05);
  #|     context.fill();
  #|     return;
  #|   }
  #|   if (terrain === "urban") {
  #|     context.fillStyle = civicUrban ? "#e1ded4" : "#d4d3cc";
  #|     context.fill();
  #|     return;
  #|   }
  #|   if (terrain === "plaza") {
  #|     context.fillStyle = "#ede5d4";
  #|     context.fill();
  #|     if (zoom >= 0.62) {
  #|       // Fine paving joins adjacent campus tiles without replacing their
  #|       // authored footprint. It appears only at neighborhood zoom.
  #|       context.save();
  #|       diamond();
  #|       context.clip();
  #|       context.strokeStyle = "rgba(91,111,120,0.16)";
  #|       context.lineWidth = Math.max(0.6, zoom);
  #|       for (let offset = -16; offset <= 16; offset += 16) {
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
  #|     // Clear late-morning spring light; the map colors carry the scene.
  #|     gradient.addColorStop(0, "#8fd4eb");
  #|     gradient.addColorStop(1, "#d9eef0");
  #|   } else if (daylight > 0.15) {
  #|     gradient.addColorStop(0, "#91b9d2");
  #|     gradient.addColorStop(1, "#d9d9cf");
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
  #|     context.fillStyle = `rgba(229,184,64,${0.08 * (
  #|       1 - daylight / 0.45
  #|     )})`;
  #|     context.fillRect(0, 0, width, height);
  #|   }
  #|   if (daylight < 0.5) {
  #|     context.fillStyle = `rgba(13,31,46,${0.3 * (
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
  #|   vignette.addColorStop(1, "rgba(24,48,59,0.12)");
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
  #|   if (zoom < 0.34) return;
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
  #|         // A small, repeated glass rhythm replaces dense facade grids.
  #|         context.fillStyle = lit
  #|           ? value < litFraction * 0.7
  #|             ? "#e5b840"
  #|             : "#f2d88a"
  #|           : value > 0.84
  #|             ? "#6aa6ba"
  #|             : "#83bed0";
  #|         context.beginPath();
  #|         context.moveTo(points[0].x, points[0].y);
  #|         for (let index = 1; index < points.length; index += 1) {
  #|           context.lineTo(points[index].x, points[index].y);
  #|         }
  #|         context.closePath();
  #|         context.fill();
  #|         context.strokeStyle = "rgba(50,78,91,0.46)";
  #|         context.lineWidth = Math.max(0.55, 0.7 * zoom);
  #|         context.stroke();
  #|         if (!lit) {
  #|           context.strokeStyle = "rgba(230,248,250,0.58)";
  #|           context.lineWidth = Math.max(0.45, 0.55 * zoom);
  #|           context.beginPath();
  #|           context.moveTo(points[0].x, points[0].y);
  #|           context.lineTo(points[1].x, points[1].y);
  #|           context.stroke();
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
  #|   // Late-morning light comes from the upper-left. Keep one restrained
  #|   // directional cast plus a crisp contact shadow.
  #|   const rx = width * 32 * zoom * 0.82;
  #|   const ry = depth * 16 * zoom * 0.82;
  #|   context.save();
  #|   // Directional soft shadow, offset away from the light.
  #|   context.fillStyle = "rgba(45,70,78,0.14)";
  #|   context.filter = `blur(${Math.max(1.5, 3.5 * zoom)}px)`;
  #|   context.beginPath();
  #|   context.ellipse(
  #|     sx + 10 * zoom, sy + 7 * zoom,
  #|     rx, ry,
  #|     0, 0, Math.PI * 2,
  #|   );
  #|   context.fill();
  #|   context.restore();
  #|   // Tight contact shadow right under the footprint.
  #|   context.fillStyle = "rgba(39,61,70,0.18)";
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
  name : String,
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
  #| (
  #|   context, style, name, tx, ty, width, depth, height0,
  #|   vw, vh, time, selected,
  #| ) => {
  #|   const civicZoom = globalThis.innerWidth < 640
  #|     ? 0.34
  #|     : globalThis.innerWidth < 1100 || globalThis.innerHeight < 800
  #|       ? 0.42
  #|       : 0.5;
  #|   const camera = globalThis.__moontownGoldenValleyCamera ??
  #|     { x: 1792, y: 3200, z: civicZoom };
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
  #|   const outline = (points, color = "#405866") => {
  #|     context.strokeStyle = color;
  #|     context.lineWidth = Math.max(0.7, 1.15 * z);
  #|     context.lineJoin = "round";
  #|     context.beginPath();
  #|     context.moveTo(points[0].x, points[0].y);
  #|     for (let i = 1; i < points.length; i += 1) {
  #|       context.lineTo(points[i].x, points[i].y);
  #|     }
  #|     context.closePath();
  #|     context.stroke();
  #|   };
  #|   const center = toScreen(tx + width / 2, ty + depth / 2);
  #|   if (style === "market") {
  #|     const colors = ["#f5f2e9", "#91c467", "#ede5d4", "#b8895b"];
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
  #|         polygon([roof.N, roof.E, roof.S, roof.W], colors[index]);
  #|         outline([roof.N, roof.E, roof.S, roof.W]);
  #|         const start = lerp(roof.N, roof.W, 0.5);
  #|         const end = lerp(roof.E, roof.S, 0.5);
  #|         context.strokeStyle = "rgba(64,88,102,0.46)";
  #|         context.lineWidth = Math.max(0.6, z);
  #|         context.beginPath();
  #|         context.moveTo(start.x, start.y);
  #|         context.lineTo(end.x, end.y);
  #|         context.stroke();
  #|         index += 1;
  #|       }
  #|     }
  #|   }
  #|   if (style === "hall" || style === "custom-hall") {
  #|     const landmark = name.includes("市政") || name.includes("知识") ||
  #|       name.toLowerCase().includes("moonbook");
  #|     const roof = top(tx, ty, width, depth, height0 + (landmark ? 3.2 : 1));
  #|     if (landmark) {
  #|       // Two lifted page planes and one recessed spine make the civic
  #|       // landmark read as an open MoonBook from the isometric camera.
  #|       const spineN = { x: roof.N.x, y: roof.N.y + 2.2 * z };
  #|       const spineS = { x: roof.S.x, y: roof.S.y + 2.2 * z };
  #|       const outerW = { x: roof.W.x, y: roof.W.y - 4.2 * z };
  #|       const outerE = { x: roof.E.x, y: roof.E.y - 4.2 * z };
  #|       const leftPage = [spineN, outerW, spineS];
  #|       const rightPage = [spineN, outerE, spineS];
  #|       polygon(leftPage, "#f5f2e9");
  #|       polygon(rightPage, "#ede5d4");
  #|       outline(leftPage);
  #|       outline(rightPage);
  #|       context.strokeStyle = "#20a9d0";
  #|       context.lineWidth = Math.max(0.8, 1.7 * z);
  #|       context.beginPath();
  #|       context.moveTo(spineN.x, spineN.y);
  #|       context.lineTo(spineS.x, spineS.y);
  #|       context.stroke();
  #|     } else {
  #|       const inset = [roof.N, roof.E, roof.S, roof.W].map(point =>
  #|         lerp(point, roof.center, 0.28));
  #|       const maker = name.includes("众创") || name.includes("工坊") ||
  #|         name.toLowerCase().includes("maker");
  #|       const accent = maker
  #|         ? "#b8895b"
  #|         : name.includes("政策") ? "#b96f52" : "#83bed0";
  #|       polygon(inset, accent);
  #|       outline(inset);
  #|     }
  #|   } else if (style === "home" || style === "custom-home") {
  #|     const first = top(tx, ty, width / 2, depth, height0 * 0.85);
  #|     const second = top(
  #|       tx + width / 2, ty + 0.3, width / 2, depth - 0.3, height0,
  #|     );
  #|     for (const roof of [first, second]) {
  #|       const terrace = [roof.N, roof.E, roof.S, roof.W].map(point =>
  #|         lerp(point, roof.center, 0.3));
  #|       polygon(terrace, "#6fa653");
  #|       outline(terrace, "#47764b");
  #|       context.strokeStyle = "#b8895b";
  #|       context.lineWidth = Math.max(0.8, 1.5 * z);
  #|       context.beginPath();
  #|       context.moveTo(roof.W.x, roof.W.y);
  #|       context.lineTo(roof.S.x, roof.S.y);
  #|       context.stroke();
  #|     }
  #|   } else if (style === "garden") {
  #|     const canopy = top(tx + 0.35, ty + 0.35, width - 0.7, depth - 0.7, 13);
  #|     const canopyPoints = [canopy.N, canopy.E, canopy.S, canopy.W];
  #|     context.globalAlpha = 0.82;
  #|     polygon(canopyPoints, "#b9e2e5");
  #|     context.globalAlpha = 1;
  #|     outline(canopyPoints);
  #|     const planter = canopyPoints.map(point =>
  #|       lerp(point, canopy.center, 0.38));
  #|     polygon(planter, "#6fa653");
  #|     outline(planter, "#47764b");
  #|     if (z >= 0.5) {
  #|       context.strokeStyle = "rgba(64,88,102,0.58)";
  #|       context.lineWidth = Math.max(0.55, 0.8 * z);
  #|       for (const fraction of [0.33, 0.66]) {
  #|         const a = lerp(canopy.N, canopy.W, fraction);
  #|         const b = lerp(canopy.E, canopy.S, fraction);
  #|         context.beginPath();
  #|         context.moveTo(a.x, a.y);
  #|         context.lineTo(b.x, b.y);
  #|         context.stroke();
  #|       }
  #|     }
  #|   } else if (style === "plaza") {
  #|     const fx = center.x;
  #|     const fy = center.y - 4 * z;
  #|     context.fillStyle = "#d4d3cc";
  #|     context.beginPath();
  #|     context.ellipse(fx, fy, 11 * z, 5.5 * z, 0, 0, Math.PI * 2);
  #|     context.fill();
  #|     context.strokeStyle = "#405866";
  #|     context.lineWidth = Math.max(0.7, z);
  #|     context.stroke();
  #|     context.fillStyle = "#2798c2";
  #|     context.beginPath();
  #|     context.ellipse(fx, fy - z, 8.5 * z, 4 * z, 0, 0, Math.PI * 2);
  #|     context.fill();
  #|     if (z >= 0.42) {
  #|       const jet = 5 * z + Math.sin(time * 2) * z;
  #|       context.strokeStyle = "rgba(226,248,252,0.9)";
  #|       context.lineWidth = Math.max(0.7, 1.2 * z);
  #|       context.beginPath();
  #|       context.moveTo(fx, fy - z);
  #|       context.quadraticCurveTo(
  #|         fx + 3 * z, fy - jet,
  #|         fx + 5 * z, fy - z,
  #|       );
  #|       context.stroke();
  #|     }
  #|   } else if (style === "radar") {
  #|     const roof = top(tx, ty, width, depth, height0 * 0.6);
  #|     const canopy = [roof.N, roof.E, roof.S, roof.W].map(point =>
  #|       lerp(point, roof.center, 0.22));
  #|     polygon(canopy, "#83bed0");
  #|     outline(canopy);
  #|     context.fillStyle = "#20a9d0";
  #|     context.beginPath();
  #|     context.arc(roof.center.x, roof.center.y, 4.2 * z, 0, Math.PI * 2);
  #|     context.fill();
  #|     context.strokeStyle = "#f5f2e9";
  #|     context.lineWidth = Math.max(0.7, z);
  #|     context.stroke();
  #|   } else if (style === "tower" || style === "custom-tower") {
  #|     const roof = top(
  #|       tx + 0.3, ty, width - 0.3, 0.6, height0 + 7.6,
  #|     );
  #|     const roofPoints = [roof.N, roof.E, roof.S, roof.W];
  #|     polygon(roofPoints, "#6fa653");
  #|     outline(roofPoints, "#47764b");
  #|     context.strokeStyle = "#20a9d0";
  #|     context.lineWidth = Math.max(0.8, 1.6 * z);
  #|     context.beginPath();
  #|     context.moveTo(roof.W.x, roof.W.y);
  #|     context.lineTo(roof.N.x, roof.N.y);
  #|     context.lineTo(roof.E.x, roof.E.y);
  #|     context.stroke();
  #|   }
  #|   if (selected) {
  #|     const pulse = (Math.sin(time * 4) + 1) / 2;
  #|     const N = toScreen(tx, ty);
  #|     const E = toScreen(tx + width, ty);
  #|     const S = toScreen(tx + width, ty + depth);
  #|     const W = toScreen(tx, ty + depth);
  #|     context.strokeStyle = `rgba(229,184,64,${0.72 + pulse * 0.2})`;
  #|     context.lineWidth = 2.5 * z;
  #|     context.beginPath();
  #|     context.moveTo(N.x, N.y);
  #|     context.lineTo(E.x, E.y);
  #|     context.lineTo(S.x, S.y);
  #|     context.lineTo(W.x, W.y);
  #|     context.closePath();
  #|     context.stroke();
  #|     context.fillStyle = "#20a9d0";
  #|     context.beginPath();
  #|     context.arc(center.x, center.y - 9 * z, 3.2 * z, 0, Math.PI * 2);
  #|     context.fill();
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
  #|   const sway = Math.sin(time * 0.7 + seed * 20) * 0.35 * zoom;
  #|   const height = (14 + seed * 10) * zoom;
  #|   context.fillStyle = "rgba(45,70,78,0.14)";
  #|   context.beginPath();
  #|   context.ellipse(
  #|     sx + 3 * zoom, sy + zoom, 8 * zoom, 3.5 * zoom,
  #|     0, 0, Math.PI * 2,
  #|   );
  #|   context.fill();
  #|   context.strokeStyle = "#8a6848";
  #|   context.lineWidth = Math.max(0.9, 2.2 * zoom);
  #|   context.beginPath();
  #|   context.moveTo(sx, sy);
  #|   context.lineTo(sx + sway * 0.3, sy - height * 0.45);
  #|   context.stroke();
  #|   const lobes = [
  #|     { x: -5.5, y: -0.6, rx: 7.2, ry: 5.8, color: "#47764b" },
  #|     { x: 5.2, y: -1.4, rx: 7.5, ry: 6, color: "#6fa653" },
  #|     { x: 0, y: -6.8, rx: 8.2, ry: 6.4, color: "#91c467" },
  #|   ];
  #|   for (const lobe of lobes) {
  #|     context.fillStyle = shade(lobe.color, 0.96 + seed * 0.07);
  #|     context.beginPath();
  #|     context.ellipse(
  #|       sx + sway + lobe.x * zoom,
  #|       sy - height * 0.58 + lobe.y * zoom,
  #|       lobe.rx * zoom, lobe.ry * zoom, 0, 0, Math.PI * 2,
  #|     );
  #|     context.fill();
  #|     context.strokeStyle = "rgba(47,83,53,0.7)";
  #|     context.lineWidth = Math.max(0.55, 0.8 * zoom);
  #|     context.stroke();
  #|   }
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
  #|   const civicZoom = globalThis.innerWidth < 640
  #|     ? 0.34
  #|     : globalThis.innerWidth < 1100 || globalThis.innerHeight < 800
  #|       ? 0.42
  #|       : 0.5;
  #|   const camera = globalThis.__moontownGoldenValleyCamera || { z: civicZoom };
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
  #|   // Matte two-value faces with one precise outline. Distinct planes,
  #|   // rather than material gradients, carry the 2.5D massing.
  #|   const leftFace = [
  #|     west,
  #|     south,
  #|     [south[0], south[1] + scaledHeight],
  #|     [west[0], west[1] + scaledHeight],
  #|   ];
  #|   fillPoly(leftFace);
  #|   context.fillStyle = left;
  #|   context.fill();
  #|   const rightFace = [
  #|     south,
  #|     east,
  #|     [east[0], east[1] + scaledHeight],
  #|     [south[0], south[1] + scaledHeight],
  #|   ];
  #|   fillPoly(rightFace);
  #|   context.fillStyle = right;
  #|   context.fill();
  #|   const roofFace = [north, east, south, west];
  #|   fillPoly(roofFace);
  #|   context.fillStyle = roof;
  #|   context.fill();
  #|   context.lineJoin = "round";
  #|   context.lineWidth = Math.max(0.75, zoom * 1.25);
  #|   context.strokeStyle = "rgba(53,76,88,0.72)";
  #|   for (const face of [leftFace, rightFace, roofFace]) {
  #|     fillPoly(face);
  #|     context.stroke();
  #|   }
  #|   // A single warm-white sun edge establishes the light direction.
  #|   context.beginPath();
  #|   context.moveTo(west[0], west[1]);
  #|   context.lineTo(north[0], north[1]);
  #|   context.lineTo(east[0], east[1]);
  #|   context.strokeStyle = shade(roof, 0.24);
  #|   context.lineWidth = Math.max(0.65, zoom);
  #|   context.stroke();
  #| }

///|
fn golden_building_colors(style : String) -> (String, String, String) {
  match style {
    "tower" => ("#f5f2e9", "#83bed0", "#5f98ad")
    "custom-tower" => ("#e9f0ef", "#87b5bd", "#668f9b")
    "lab" => ("#f5f2e9", "#d4d3cc", "#83bed0")
    "custom-lab" => ("#ede5d4", "#c7b79f", "#75aabb")
    "hall" | "custom-hall" => ("#f5f2e9", "#d4d3cc", "#b9c7c7")
    "garden" => ("#91c467", "#6fa653", "#47764b")
    "home" => ("#f5f2e9", "#d7c9b4", "#b8895b")
    "custom-home" => ("#f1f0ea", "#bdced0", "#8caab0")
    "radar" => ("#f5f2e9", "#d4d3cc", "#83bed0")
    "market" => ("#ede5d4", "#b8895b", "#956a47")
    "plaza" => ("#f5f2e9", "#d4d3cc", "#b8b9b3")
    _ => ("#f5f2e9", "#d4d3cc", "#b7b8b2")
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
fn golden_civic_hero_label(module_key : String?) -> Bool {
  match module_key {
    Some(value) =>
      match value {
        "town-shell"
        | "contest-express"
        | "resident-twins"
        | "ai-garden"
        | "social-square"
        | "research-ai-agents"
        | "physical-bridge" => true
        other if other.contains("transit") || other.contains("mobility") => true
        _ => false
      }
    None => false
  }
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
        "#f5f2e9"
      },
      if building.style == "custom-home" {
        left
      } else {
        "#d7c9b4"
      },
      if building.style == "custom-home" {
        right
      } else {
        "#b8895b"
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
    let columns = if building.width <= 3 {
      2
    } else if building.width <= 6 {
      3
    } else {
      4
    }
    let rows = if building.floors > 3 { 3 } else { building.floors }
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
      rows,
      lit_fraction,
    )
  }
  if building.style == "lab" || building.style == "custom-lab" {
    let first_center_x = building.x.to_double() +
      building.width.to_double() / 2.0
    let first_center_y = building.y.to_double() + 0.6
    golden_draw_iso_box(
      context,
      golden_screen_x(first_center_x, first_center_y, viewport_width),
      golden_screen_y(first_center_x, first_center_y, viewport_height),
      1.4,
      0.55,
      height + 2.2,
      "#83bed0",
      "#6897a6",
      "#507887",
    )
  }
  golden_draw_reference_building_details(
    context,
    building.style,
    building.name,
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
  let show_label = selected ||
    !work_status.is_empty() ||
    zoom >= 0.72 ||
    (zoom >= 0.42 && golden_civic_hero_label(building.module_key))
  if show_label {
    let label_width = golden_ctx_measure_text(context, building.name)
    golden_ctx_fill_style(context, "rgba(245,242,233,.94)")
    context.begin_path()
    context.round_rect(
      label_x - label_width / 2.0 - 6.0,
      label_y - 9.0,
      label_width + 12.0,
      16.0,
      8.0,
    )
    context.fill()
    golden_ctx_stroke_style(context, "rgba(64,88,102,.42)")
    golden_ctx_line_width(context, 0.8)
    context.stroke()
    golden_ctx_fill_style(context, "#334b57")
    context.fill_text(building.name, label_x, label_y)
  }
  if golden_policy_hall_publication_highlight(building.module_key) {
    golden_draw_policy_hall_publication_highlight(
      context,
      sx,
      sy,
      top_center_y,
      building.width.to_double(),
      building.depth.to_double(),
      zoom,
      golden_policy_hall_publication_badge(),
      selected,
      golden_prefers_reduced_motion(),
      golden_animation_seconds(),
    )
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
      golden_ctx_fill_style(context, "rgba(91,107,125,.08)")
      context.fill_rect(
        0.0,
        0.0,
        viewport_width.to_double(),
        viewport_height.to_double(),
      )
    }
    Rain => {
      golden_ctx_stroke_style(context, "rgba(196,229,240,.38)")
      golden_ctx_line_width(context, 0.9)
      for index in 0..<80 {
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
      golden_ctx_fill_style(context, "rgba(240,248,255,.58)")
      for index in 0..<58 {
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
) -> Bool {
  let canvas_id = "energy-valley-canvas"
  match town_canvas_follow_position(view) {
    Some((x, y)) => golden_follow_camera(x, y)
    None => ()
  }
  prepare_golden_valley_canvas(canvas_id)
  let width = golden_valley_canvas_width(canvas_id)
  let height = golden_valley_canvas_height(canvas_id)
  match @canvas.get_context2d(canvas_id) {
    None => false
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
      true
    }
  }
}

///|
fn render_golden_valley_canvas(
  dispatch : Dispatch[Msg],
  snapshot : @energy_valley_contract.TownSnapshot,
  view : TownCanvasViewState,
) -> @rabbita.Html {
  schedule_golden_valley_canvas(() => {
    // Drawing first preserves the accepted-frame contract: input and the
    // continuous animator only adopt this snapshot after a successful paint.
    if draw_golden_valley_canvas(snapshot, view) {
      install_golden_valley_canvas_input(
        () => {
          if !draw_golden_valley_canvas(snapshot, view) {
            stop_golden_valley_canvas()
          }
        },
        () => golden_valley_clear_canvas_frame(),
      )
      install_player_walk_keys()
    } else {
      stop_golden_valley_canvas()
    }
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
