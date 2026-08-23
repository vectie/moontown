///|
/// One lifecycle for the indoor and underground world canvases. Each canvas
/// keeps its own latest MoonBit closure and repaints only after data, assets,
/// or its measured size changes.
extern "js" fn schedule_spatial_world_canvas(
  canvas_id : String,
  callback : () -> Unit,
) -> Unit =
  #| (canvasId, callback) => {
  #|   if (typeof globalThis.requestAnimationFrame !== "function") return;
  #|   const scenes = globalThis.__moontownSpatialWorldScenes ||= new Map();
  #|   let scene = scenes.get(canvasId);
  #|   if (!scene) {
  #|     scene = { raf: 0, pending: null, render: null, observer: null };
  #|     scenes.set(canvasId, scene);
  #|   }
  #|   scene.pending = callback;
  #|   scene.render = callback;
  #|   if (!scene.raf) {
  #|     scene.raf = globalThis.requestAnimationFrame(() => {
  #|       scene.raf = 0;
  #|       const paint = scene.pending;
  #|       scene.pending = null;
  #|       if (typeof paint === "function") paint();
  #|       const canvas = globalThis.document?.getElementById(canvasId);
  #|       if (canvas && !scene.observer && typeof ResizeObserver === "function") {
  #|         scene.observer = new ResizeObserver(() => {
  #|           if (scene.raf) return;
  #|           scene.raf = globalThis.requestAnimationFrame(() => {
  #|             scene.raf = 0;
  #|             scene.render?.();
  #|           });
  #|         });
  #|         scene.observer.observe(canvas);
  #|       }
  #|     });
  #|   }
  #| }

///|
extern "js" fn spatial_world_canvas_draw_plate(
  context : @dom.CanvasRenderingContext2D,
  canvas_id : String,
  asset_path : String,
  width : Int,
  height : Int,
  fallback_color : String,
) -> Bool =
  #| (context, canvasId, assetPath, width, height, fallbackColor) => {
  #|   context.fillStyle = fallbackColor;
  #|   context.fillRect(0, 0, width, height);
  #|   const cache = globalThis.__moontownSpatialWorldPlates ||= new Map();
  #|   let record = cache.get(assetPath);
  #|   if (!record) {
  #|     const image = new Image();
  #|     record = { image, ready: false, failed: false };
  #|     cache.set(assetPath, record);
  #|     image.decoding = "async";
  #|     image.onload = () => {
  #|       record.ready = true;
  #|       globalThis.__moontownSpatialWorldScenes?.get(canvasId)?.render?.();
  #|     };
  #|     image.onerror = () => { record.failed = true; };
  #|     image.src = assetPath;
  #|   }
  #|   if (!record.ready || !record.image.naturalWidth) return false;
  #|   context.imageSmoothingEnabled = true;
  #|   context.drawImage(record.image, 0, 0, width, height);
  #|   return true;
  #| }

///|
/// Draw one cell from an authored transparent prop atlas. The atlas supplies
/// finish and material detail; MoonBit still decides which semantic entity
/// exists, which cell represents it, and where that entity belongs.
extern "js" fn spatial_world_canvas_draw_atlas_prop(
  context : @dom.CanvasRenderingContext2D,
  canvas_id : String,
  asset_path : String,
  columns : Int,
  rows : Int,
  asset_index : Int,
  x : Double,
  y : Double,
  scale : Double,
  target_size : Double,
  baseline_ratio : Double,
  selected : Bool,
  state : String,
) -> Bool =
  #| (context, canvasId, assetPath, columns, rows, assetIndex, x, y, scale, targetSize, baselineRatio, selected, state) => {
  #|   const cache = globalThis.__moontownSpatialWorldAtlases ||= new Map();
  #|   let record = cache.get(assetPath);
  #|   if (!record) {
  #|     const image = new Image();
  #|     record = { image, ready: false, failed: false };
  #|     cache.set(assetPath, record);
  #|     image.decoding = "async";
  #|     image.onload = () => {
  #|       record.ready = true;
  #|       globalThis.__moontownSpatialWorldScenes?.get(canvasId)?.render?.();
  #|     };
  #|     image.onerror = () => { record.failed = true; };
  #|     image.src = assetPath;
  #|   }
  #|   if (!record.ready || !record.image.naturalWidth) return false;
  #|   const safeColumns = Math.max(1, columns);
  #|   const safeRows = Math.max(1, rows);
  #|   const cellWidth = record.image.naturalWidth / safeColumns;
  #|   const cellHeight = record.image.naturalHeight / safeRows;
  #|   const safeIndex = Math.max(0, Math.min(assetIndex, safeColumns * safeRows - 1));
  #|   const column = safeIndex % safeColumns;
  #|   const row = Math.floor(safeIndex / safeColumns);
  #|   const size = targetSize * Math.max(.48, scale);
  #|   const drawHeight = size;
  #|   const drawWidth = size * cellWidth / cellHeight;
  #|   const baseline = Math.max(.5, Math.min(.98, baselineRatio));
  #|   const normalized = String(state).toLowerCase();
  #|   const tone = /offline|unavailable|unreachable|unhealthy|retired/.test(normalized) ? "#b85f58"
  #|     : /not-observed|not-configured|vacant/.test(normalized) ? "#b8895b"
  #|     : /ready|active|observed|reachable|occupied/.test(normalized) ? "#6fa653" : "";
  #|   context.save();
  #|   if (selected) {
  #|     context.strokeStyle = "#f2d88a";
  #|     context.lineWidth = 3 * Math.max(.48, scale);
  #|     context.beginPath();
  #|     context.ellipse(x, y + drawHeight * .015, drawWidth * .31, drawHeight * .095, 0, 0, Math.PI * 2);
  #|     context.stroke();
  #|   }
  #|   context.imageSmoothingEnabled = true;
  #|   context.drawImage(
  #|     record.image,
  #|     column * cellWidth,
  #|     row * cellHeight,
  #|     cellWidth,
  #|     cellHeight,
  #|     x - drawWidth / 2,
  #|     y - drawHeight * baseline,
  #|     drawWidth,
  #|     drawHeight,
  #|   );
  #|   if (tone) {
  #|     context.fillStyle = tone;
  #|     context.strokeStyle = "#fff8df";
  #|     context.lineWidth = 1.5 * Math.max(.48, scale);
  #|     context.beginPath();
  #|     context.arc(x + drawWidth * .27, y - drawHeight * .54, drawHeight * .026, 0, Math.PI * 2);
  #|     context.fill();
  #|     context.stroke();
  #|   }
  #|   context.restore();
  #|   return true;
  #| }

///|
extern "js" fn spatial_world_canvas_draw_connection(
  context : @dom.CanvasRenderingContext2D,
  from_x : Double,
  from_y : Double,
  to_x : Double,
  to_y : Double,
  color : String,
) -> Unit =
  #| (context, fromX, fromY, toX, toY, color) => {
  #|   context.save();
  #|   context.strokeStyle = color;
  #|   context.lineWidth = 2;
  #|   context.setLineDash([7, 6]);
  #|   context.beginPath();
  #|   context.moveTo(fromX, fromY);
  #|   const midY = fromY + (toY - fromY) * 0.55;
  #|   context.bezierCurveTo(fromX, midY, toX, midY, toX, toY);
  #|   context.stroke();
  #|   context.setLineDash([]);
  #|   context.restore();
  #| }

///|
/// Authored Canvas furniture built from the same matte roof/left/right face
/// grammar as the outdoor isometric buildings. No semantic label is painted
/// into the world; the parallel DOM hotspot owns accessible identity.
extern "js" fn spatial_world_canvas_draw_indoor_prop(
  context : @dom.CanvasRenderingContext2D,
  kind : String,
  x : Double,
  y : Double,
  scale : Double,
  accent : String,
  occupied : Bool,
) -> Unit =
  #| (context, kind, x, y, scale, accent, occupied) => {
  #|   const s = Math.max(.48, scale);
  #|   const poly = (points, fill, stroke = "#405866", line = 1.25) => {
  #|     context.beginPath();
  #|     context.moveTo(points[0][0], points[0][1]);
  #|     for (let i = 1; i < points.length; i += 1) context.lineTo(points[i][0], points[i][1]);
  #|     context.closePath();
  #|     context.fillStyle = fill;
  #|     context.fill();
  #|     context.strokeStyle = stroke;
  #|     context.lineWidth = line * s;
  #|     context.stroke();
  #|   };
  #|   const prism = (cx, cy, w, d, h, roof, left, right) => {
  #|     w *= s; d *= s; h *= s;
  #|     const n = [cx, cy - d / 2 - h];
  #|     const e = [cx + w / 2, cy - h];
  #|     const south = [cx, cy + d / 2 - h];
  #|     const west = [cx - w / 2, cy - h];
  #|     poly([west, south, [south[0], south[1] + h], [west[0], west[1] + h]], left);
  #|     poly([south, e, [e[0], e[1] + h], [south[0], south[1] + h]], right);
  #|     poly([n, e, south, west], roof);
  #|   };
  #|   const chair = (cx, cy, tone = "#83bed0") => {
  #|     prism(cx, cy, 19, 12, 8, tone, "#668f9b", "#5f98ad");
  #|     prism(cx, cy - 5 * s, 18, 6, 20, "#a9d0d8", "#668f9b", "#5f98ad");
  #|   };
  #|   context.save();
  #|   context.fillStyle = "rgba(45,70,78,.18)";
  #|   context.beginPath();
  #|   context.ellipse(x + 7*s, y + 8*s, 53*s, 17*s, 0, 0, Math.PI*2);
  #|   context.fill();
  #|   if (occupied) {
  #|     context.strokeStyle = "rgba(229,184,64,.9)";
  #|     context.lineWidth = 2*s;
  #|     context.beginPath();
  #|     context.ellipse(x, y + 5*s, 57*s, 20*s, 0, 0, Math.PI*2);
  #|     context.stroke();
  #|   }
  #|   if (kind === "meeting") {
  #|     context.fillStyle = "#ede5d4";
  #|     context.strokeStyle = "#405866";
  #|     context.lineWidth = 1.5*s;
  #|     context.beginPath();
  #|     context.ellipse(x, y - 10*s, 42*s, 20*s, 0, 0, Math.PI*2);
  #|     context.fill(); context.stroke();
  #|     context.fillStyle = "#b8895b";
  #|     context.fillRect(x-4*s, y-8*s, 8*s, 25*s);
  #|     chair(x-55*s, y+4*s); chair(x+55*s, y+4*s);
  #|     chair(x, y-38*s, "#f2d88a"); chair(x, y+25*s, "#f2d88a");
  #|   } else if (kind === "exhibit") {
  #|     prism(x, y, 48, 28, 44, "#f5f2e9", "#d7c9b4", "#b8895b");
  #|     prism(x, y-46*s, 42, 9, 42, "#d9eef0", "#83bed0", "#5f98ad");
  #|     context.fillStyle = accent;
  #|     context.fillRect(x-12*s, y-76*s, 24*s, 16*s);
  #|   } else if (kind === "bench") {
  #|     prism(x, y, 86, 22, 13, "#d7c9b4", "#b8895b", "#956a47");
  #|     prism(x, y-19*s, 82, 8, 25, "#ede5d4", "#b8895b", "#956a47");
  #|   } else if (kind === "stage") {
  #|     prism(x, y+6*s, 100, 50, 10, "#efb6bf", "#b8898f", "#a76f78");
  #|     prism(x, y-35*s, 62, 11, 50, "#f5f2e9", "#d7c9b4", "#b8895b");
  #|   } else if (kind === "gate") {
  #|     prism(x, y, 38, 28, 12, "#d9eef0", "#83bed0", "#5f98ad");
  #|     prism(x-22*s, y-34*s, 12, 14, 62, "#f5f2e9", "#83bed0", "#5f98ad");
  #|     prism(x+22*s, y-34*s, 12, 14, 62, "#f5f2e9", "#83bed0", "#5f98ad");
  #|     context.strokeStyle = accent;
  #|     context.lineWidth = 4*s;
  #|     context.beginPath(); context.moveTo(x-16*s,y-68*s); context.lineTo(x+16*s,y-68*s); context.stroke();
  #|   } else {
  #|     const service = kind === "service" || kind === "exchange";
  #|     prism(x, y, service ? 90 : 76, service ? 34 : 40, 18,
  #|       service ? "#83bed0" : "#d7c9b4",
  #|       service ? "#668f9b" : "#b8895b",
  #|       service ? "#5f98ad" : "#956a47");
  #|     prism(x, y-30*s, 30, 9, 34, "#d9eef0", "#405866", "#334b57");
  #|     context.fillStyle = "#35a8ce";
  #|     context.fillRect(x-10*s, y-55*s, 20*s, 13*s);
  #|     chair(x-34*s, y+26*s); chair(x+34*s, y+26*s);
  #|   }
  #|   context.fillStyle = accent;
  #|   context.beginPath(); context.arc(x+44*s, y-34*s, 4.5*s, 0, Math.PI*2); context.fill();
  #|   context.strokeStyle = "#fff8df"; context.lineWidth = 1.5*s; context.stroke();
  #|   context.restore();
  #| }

///|
extern "js" fn spatial_world_canvas_draw_agent(
  context : @dom.CanvasRenderingContext2D,
  canvas_id : String,
  sprite_path : String,
  x : Double,
  y : Double,
  scale : Double,
  live : Bool,
) -> Unit =
  #| (context, canvasId, spritePath, x, y, scale, live) => {
  #|   const cache = globalThis.__moontownSpatialWorldActors ||= new Map();
  #|   let record = cache.get(spritePath);
  #|   if (!record) {
  #|     const image = new Image();
  #|     record = { image, ready: false, failed: false };
  #|     cache.set(spritePath, record);
  #|     image.decoding = "async";
  #|     image.onload = () => {
  #|       record.ready = true;
  #|       globalThis.__moontownSpatialWorldScenes?.get(canvasId)?.render?.();
  #|     };
  #|     image.onerror = () => { record.failed = true; };
  #|     image.src = spritePath;
  #|   }
  #|   const s = Math.max(.48, scale);
  #|   const h = 68*s;
  #|   context.save();
  #|   context.fillStyle = "rgba(45,70,78,.25)";
  #|   context.beginPath(); context.ellipse(x, y+2*s, 16*s, 5*s, 0, 0, Math.PI*2); context.fill();
  #|   if (live) {
  #|     context.strokeStyle = "rgba(229,184,64,.95)";
  #|     context.lineWidth = 2*s;
  #|     context.beginPath(); context.ellipse(x, y+1*s, 22*s, 8*s, 0, 0, Math.PI*2); context.stroke();
  #|   }
  #|   if (record.ready && record.image.naturalWidth) {
  #|     const w = h * record.image.naturalWidth / record.image.naturalHeight;
  #|     context.imageSmoothingEnabled = true;
  #|     context.drawImage(record.image, x-w/2, y-h, w, h);
  #|   }
  #|   context.restore();
  #| }

///|
extern "js" fn spatial_world_canvas_draw_compute_entity(
  context : @dom.CanvasRenderingContext2D,
  kind : String,
  x : Double,
  y : Double,
  scale : Double,
  state : String,
  selected : Bool,
) -> Unit =
  #| (context, kind, x, y, scale, state, selected) => {
  #|   const s = Math.max(.48, scale);
  #|   const normalized = String(state).toLowerCase();
  #|   const tone = /offline|unavailable|unreachable|unhealthy|retired/.test(normalized) ? "#b85f58"
  #|     : /not-observed|not-configured/.test(normalized) ? "#b8895b"
  #|     : /ready|active|observed|reachable/.test(normalized) ? "#6fa653" : "#b8895b";
  #|   const poly = (points, fill, stroke = "#334b57", line = 1.25) => {
  #|     context.beginPath(); context.moveTo(points[0][0],points[0][1]);
  #|     for (let i=1;i<points.length;i+=1) context.lineTo(points[i][0],points[i][1]);
  #|     context.closePath(); context.fillStyle=fill; context.fill();
  #|     context.strokeStyle=stroke; context.lineWidth=line*s; context.stroke();
  #|   };
  #|   const prism = (cx,cy,w,d,h,roof,left,right) => {
  #|     w*=s;d*=s;h*=s;
  #|     const n=[cx,cy-d/2-h],e=[cx+w/2,cy-h],so=[cx,cy+d/2-h],we=[cx-w/2,cy-h];
  #|     poly([we,so,[so[0],so[1]+h],[we[0],we[1]+h]],left);
  #|     poly([so,e,[e[0],e[1]+h],[so[0],so[1]+h]],right);
  #|     poly([n,e,so,we],roof);
  #|   };
  #|   context.save();
  #|   context.fillStyle="rgba(18,31,38,.32)"; context.beginPath();
  #|   context.ellipse(x+7*s,y+7*s,(kind==="rack"?38:48)*s,13*s,0,0,Math.PI*2); context.fill();
  #|   if (selected) {
  #|     context.strokeStyle="#f2d88a"; context.lineWidth=3*s; context.beginPath();
  #|     context.ellipse(x,y+4*s,(kind==="rack"?43:55)*s,17*s,0,0,Math.PI*2); context.stroke();
  #|   }
  #|   if (kind === "rack") {
  #|     prism(x,y,66,34,108,"#668f9b","#405866","#334b57");
  #|     context.fillStyle="#243b47"; context.strokeStyle="#83bed0"; context.lineWidth=1*s;
  #|     for (let i=0;i<5;i+=1) {
  #|       const by=y-94*s+i*17*s; context.fillRect(x-26*s,by,45*s,10*s); context.strokeRect(x-26*s,by,45*s,10*s);
  #|       context.fillStyle=i===0?tone:"#62717d"; context.beginPath(); context.arc(x-20*s,by+5*s,2.2*s,0,Math.PI*2); context.fill(); context.fillStyle="#243b47";
  #|     }
  #|   } else if (kind === "terminal") {
  #|     prism(x,y,58,24,48,"#d4d3cc","#405866","#334b57");
  #|     context.fillStyle="#d9eef0"; context.strokeStyle="#83bed0"; context.lineWidth=2*s;
  #|     context.fillRect(x-21*s,y-40*s,34*s,22*s); context.strokeRect(x-21*s,y-40*s,34*s,22*s);
  #|     context.fillStyle=tone; context.fillRect(x-16*s,y-33*s,5*s,9*s); context.fillRect(x-8*s,y-29*s,5*s,5*s); context.fillRect(x,y-36*s,5*s,12*s);
  #|   } else if (kind === "gateway") {
  #|     prism(x,y+12*s,92,58,18,"#d4d3cc","#668f9b","#405866");
  #|     context.fillStyle="#f5f2e9"; context.strokeStyle="#83bed0"; context.lineWidth=9*s;
  #|     context.beginPath(); context.arc(x,y-38*s,39*s,0,Math.PI*2); context.fill(); context.stroke();
  #|     context.strokeStyle="#e5b840"; context.lineWidth=3*s; context.beginPath(); context.arc(x,y-38*s,27*s,-.7,2.2); context.stroke();
  #|     context.fillStyle=tone; context.beginPath(); context.arc(x,y-38*s,7*s,0,Math.PI*2); context.fill();
  #|   } else {
  #|     prism(x,y,88,40,17,"#83bed0","#668f9b","#405866");
  #|     prism(x,y-35*s,40,10,38,"#d9eef0","#405866","#334b57");
  #|     context.fillStyle="#203944"; context.fillRect(x-15*s,y-61*s,27*s,17*s);
  #|     context.fillStyle=tone; context.fillRect(x-11*s,y-56*s,4*s,9*s); context.fillRect(x-4*s,y-52*s,4*s,5*s); context.fillRect(x+3*s,y-58*s,4*s,11*s);
  #|   }
  #|   context.restore();
  #| }

///|
fn spatial_scene_scale(width : Int) -> Double {
  (width.to_double() / 1400.0).clamp(min=0.48, max=1.18)
}

///|
fn spatial_scene_anchor(
  width : Int,
  height : Int,
  normalized_x : Double,
  normalized_y : Double,
  underground : Bool,
) -> (Double, Double) {
  let north_x = if underground { 0.47 } else { 0.46 }
  let north_y = if underground { 0.31 } else { 0.29 }
  let east_x = if underground { 0.94 } else { 0.95 }
  let east_y = if underground { 0.60 } else { 0.53 }
  let west_x = if underground { 0.07 } else { 0.05 }
  let west_y = if underground { 0.64 } else { 0.65 }
  (
    (
      north_x +
      normalized_x * (east_x - north_x) +
      normalized_y * (west_x - north_x)
    ) *
    width.to_double(),
    (
      north_y +
      normalized_x * (east_y - north_y) +
      normalized_y * (west_y - north_y)
    ) *
    height.to_double(),
  )
}

///|
fn spatial_scene_hotspot_style(
  normalized_x : Double,
  normalized_y : Double,
  underground : Bool,
  width_percent : Double,
  height_percent : Double,
) -> Array[String] {
  let north_x = if underground { 47.0 } else { 46.0 }
  let north_y = if underground { 31.0 } else { 29.0 }
  let east_x = if underground { 94.0 } else { 95.0 }
  let east_y = if underground { 60.0 } else { 53.0 }
  let west_x = if underground { 7.0 } else { 5.0 }
  let west_y = if underground { 64.0 } else { 65.0 }
  let left = north_x +
    normalized_x * (east_x - north_x) +
    normalized_y * (west_x - north_x)
  let top = north_y +
    normalized_x * (east_y - north_y) +
    normalized_y * (west_y - north_y)
  [
    "left: {left}%", "top: {top}%", "width: {width_percent}%", "height: {height_percent}%",
  ]
}
