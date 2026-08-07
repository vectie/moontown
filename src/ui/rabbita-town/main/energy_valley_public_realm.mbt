///|
/// Deterministic public-realm placement rules. These functions deliberately
/// consume the typed Wenyu terrain/road facts without mutating them: visual
/// detail follows the authored geography instead of inventing a second map.
fn golden_public_realm_is_night(hour : Double) -> Bool {
  hour < 6.5 || hour >= 18.5
}

///|
fn golden_public_realm_streetlight_at(
  seed : Int,
  x : Int,
  y : Int,
  terrain : String,
  road_mask : Int,
  major : Bool,
) -> Bool {
  terrain == "road" &&
  road_mask != 0 &&
  energy_valley_variation(seed, x, y, 701, if major { 7 } else { 11 }) == 0
}

///|
fn golden_public_realm_street_tree_at(
  seed : Int,
  x : Int,
  y : Int,
  terrain : String,
  road_mask : Int,
) -> Bool {
  terrain == "road" &&
  road_mask != 0 &&
  energy_valley_variation(seed, x, y, 709, 17) == 0
}

///|
/// Returns 0 for no plaza furniture, 1 for a bench, and 2 for a planter.
fn golden_public_realm_plaza_feature(
  seed : Int,
  x : Int,
  y : Int,
  terrain : String,
  occupied : Bool,
) -> Int {
  if terrain != "plaza" || occupied {
    return 0
  }
  let roll = energy_valley_variation(seed, x, y, 719, 67)
  if roll == 0 {
    1
  } else if roll == 1 {
    2
  } else {
    0
  }
}

///|
fn golden_public_realm_promenade_district(district : String) -> Bool {
  district == "civic-core" ||
  district == "lake-learning" ||
  district == "lake-exchange" ||
  district == "east-river" ||
  district == "south-showcase"
}

///|
/// The returned mask uses N/E/S/W bits 1/2/4/8 and traces only shore edges
/// that touch authored water. This makes the boardwalk conform to the Wenyu
/// river/lake outline instead of cutting a decorative curve across the map.
fn golden_public_realm_boardwalk_mask(
  terrain : String,
  district : String,
  north : String,
  east : String,
  south : String,
  west : String,
) -> Int {
  if terrain == "water" ||
    terrain == "road" ||
    terrain == "bridge" ||
    terrain == "void" ||
    !golden_public_realm_promenade_district(district) {
    return 0
  }
  let mut mask = 0
  if north == "water" {
    mask = mask | 1
  }
  if east == "water" {
    mask = mask | 2
  }
  if south == "water" {
    mask = mask | 4
  }
  if west == "water" {
    mask = mask | 8
  }
  mask
}

///|
fn golden_public_realm_side(seed : Int, x : Int, y : Int, salt : Int) -> Int {
  if energy_valley_variation(seed, x, y, salt, 2) == 0 {
    -1
  } else {
    1
  }
}

///|
extern "js" fn golden_draw_public_streetlight(
  context : @dom.CanvasRenderingContext2D,
  sx : Double,
  sy : Double,
  zoom : Double,
  road_mask : Int,
  side : Int,
  night : Bool,
) -> Unit =
  #| (context, sx, sy, zoom, mask, side, night) => {
  #|   // Offset the fixture to the road edge. The two straight road masks use
  #|   // opposite isometric normals; junctions use a stable diagonal verge.
  #|   const spacing = Math.max(3, 8 * zoom);
  #|   let ox = spacing * side;
  #|   let oy = spacing * 0.42 * side;
  #|   if (mask === 5) oy = -spacing * 0.42 * side;
  #|   if (mask === 10) oy = spacing * 0.42 * side;
  #|   const x = sx + ox;
  #|   const y = sy + oy;
  #|   const pole = Math.max(4, 14 * zoom);
  #|   context.save();
  #|   context.strokeStyle = "rgba(49,53,57,0.96)";
  #|   context.lineWidth = Math.max(0.8, 1.5 * zoom);
  #|   context.beginPath();
  #|   context.moveTo(x, y);
  #|   context.lineTo(x, y - pole);
  #|   context.lineTo(x + 3 * zoom * side, y - pole);
  #|   context.stroke();
  #|   context.fillStyle = night ? "#ffd47c" : "#e8e2cf";
  #|   context.beginPath();
  #|   context.arc(
  #|     x + 3 * zoom * side, y - pole,
  #|     Math.max(1.1, 2.2 * zoom), 0, Math.PI * 2,
  #|   );
  #|   context.fill();
  #|   if (night) {
  #|     const glow = Math.max(5, 16 * zoom);
  #|     const gx = x + 3 * zoom * side;
  #|     const gy = y - pole;
  #|     const gradient = context.createRadialGradient(gx, gy, 0, gx, gy, glow);
  #|     gradient.addColorStop(0, "rgba(255,211,118,0.72)");
  #|     gradient.addColorStop(1, "rgba(255,211,118,0)");
  #|     context.fillStyle = gradient;
  #|     context.beginPath();
  #|     context.arc(gx, gy, glow, 0, Math.PI * 2);
  #|     context.fill();
  #|   }
  #|   context.restore();
  #| }

///|
extern "js" fn golden_draw_public_street_tree(
  context : @dom.CanvasRenderingContext2D,
  sx : Double,
  sy : Double,
  zoom : Double,
  road_mask : Int,
  side : Int,
) -> Unit =
  #| (context, sx, sy, zoom, mask, side) => {
  #|   const spacing = Math.max(3.5, 10 * zoom);
  #|   let ox = spacing * side;
  #|   let oy = spacing * 0.42 * side;
  #|   if (mask === 5) oy = -spacing * 0.42 * side;
  #|   const x = sx + ox;
  #|   const y = sy + oy;
  #|   const trunk = Math.max(2.8, 8 * zoom);
  #|   const crown = Math.max(1.8, 6.5 * zoom);
  #|   context.save();
  #|   context.fillStyle = "rgba(18,39,24,0.18)";
  #|   context.beginPath();
  #|   context.ellipse(x + 2, y + 1, crown, crown * 0.42, 0, 0, Math.PI * 2);
  #|   context.fill();
  #|   context.strokeStyle = "#6f4a2c";
  #|   context.lineWidth = Math.max(0.8, 1.5 * zoom);
  #|   context.beginPath();
  #|   context.moveTo(x, y);
  #|   context.lineTo(x, y - trunk);
  #|   context.stroke();
  #|   context.fillStyle = "#4e9a57";
  #|   context.beginPath();
  #|   context.arc(x, y - trunk, crown, 0, Math.PI * 2);
  #|   context.fill();
  #|   context.fillStyle = "rgba(130,190,103,0.72)";
  #|   context.beginPath();
  #|   context.arc(
  #|     x - crown * 0.28, y - trunk - crown * 0.3,
  #|     crown * 0.54, 0, Math.PI * 2,
  #|   );
  #|   context.fill();
  #|   context.restore();
  #| }

///|
extern "js" fn golden_draw_public_bench(
  context : @dom.CanvasRenderingContext2D,
  sx : Double,
  sy : Double,
  zoom : Double,
  orientation : Int,
) -> Unit =
  #| (context, sx, sy, zoom, orientation) => {
  #|   const width = Math.max(4.5, 13 * zoom);
  #|   const rise = Math.max(1.4, 4 * zoom);
  #|   const slope = orientation > 0 ? 0.42 : -0.42;
  #|   const ax = sx - width / 2;
  #|   const ay = sy - width * slope / 2;
  #|   const bx = sx + width / 2;
  #|   const by = sy + width * slope / 2;
  #|   context.save();
  #|   context.lineCap = "round";
  #|   context.strokeStyle = "#81532f";
  #|   context.lineWidth = Math.max(1.5, 3.2 * zoom);
  #|   context.beginPath();
  #|   context.moveTo(ax, ay - rise);
  #|   context.lineTo(bx, by - rise);
  #|   context.stroke();
  #|   context.strokeStyle = "#47392e";
  #|   context.lineWidth = Math.max(0.7, 1.2 * zoom);
  #|   for (const t of [0.2, 0.8]) {
  #|     const x = ax + (bx - ax) * t;
  #|     const y = ay + (by - ay) * t;
  #|     context.beginPath();
  #|     context.moveTo(x, y - rise);
  #|     context.lineTo(x, y + rise * 0.75);
  #|     context.stroke();
  #|   }
  #|   context.restore();
  #| }

///|
extern "js" fn golden_draw_public_planter(
  context : @dom.CanvasRenderingContext2D,
  sx : Double,
  sy : Double,
  zoom : Double,
) -> Unit =
  #| (context, sx, sy, zoom) => {
  #|   const radius = Math.max(2, 5.5 * zoom);
  #|   context.save();
  #|   context.fillStyle = "#8e7561";
  #|   context.beginPath();
  #|   context.ellipse(sx, sy, radius, radius * 0.5, 0, 0, Math.PI * 2);
  #|   context.fill();
  #|   context.fillStyle = "#4f8d4d";
  #|   context.beginPath();
  #|   context.arc(sx, sy - radius * 0.65, radius * 0.75, 0, Math.PI * 2);
  #|   context.fill();
  #|   context.fillStyle = "#f4c65e";
  #|   context.beginPath();
  #|   context.arc(
  #|     sx + radius * 0.25, sy - radius * 0.95,
  #|     Math.max(0.7, radius * 0.22), 0, Math.PI * 2,
  #|   );
  #|   context.fill();
  #|   context.restore();
  #| }

///|
fn golden_public_realm_boardwalk_casing_width(zoom : Double) -> Double {
  let scaled = 8.0 * zoom
  if scaled < 0.8 {
    0.8
  } else {
    scaled
  }
}

///|
fn golden_public_realm_boardwalk_deck_width(zoom : Double) -> Double {
  let scaled = 6.0 * zoom
  if scaled < 0.5 {
    0.5
  } else {
    scaled
  }
}

///|
fn golden_public_realm_boardwalk_shadow_offset(zoom : Double) -> Double {
  let scaled = 2.0 * zoom
  if scaled < 0.25 {
    0.25
  } else {
    scaled
  }
}

///|
extern "js" fn golden_draw_public_boardwalk_scaled(
  context : @dom.CanvasRenderingContext2D,
  sx : Double,
  sy : Double,
  zoom : Double,
  edge_mask : Int,
  casing_width : Double,
  deck_width : Double,
  shadow_offset : Double,
) -> Unit =
  #| (context, sx, sy, zoom, mask, casingWidth, deckWidth, shadowOffset) => {
  #|   const top = [sx, sy - 16 * zoom];
  #|   const right = [sx + 32 * zoom, sy];
  #|   const bottom = [sx, sy + 16 * zoom];
  #|   const left = [sx - 32 * zoom, sy];
  #|   const edges = [
  #|     [1, top, right], [2, right, bottom],
  #|     [4, bottom, left], [8, left, top],
  #|   ];
  #|   context.save();
  #|   context.lineCap = "round";
  #|   context.lineJoin = "round";
  #|   for (const [bit, from, to] of edges) {
  #|     if (!(mask & bit)) continue;
  #|     context.strokeStyle = "rgba(67,46,29,0.44)";
  #|     context.lineWidth = casingWidth;
  #|     context.beginPath();
  #|     context.moveTo(from[0], from[1] + shadowOffset);
  #|     context.lineTo(to[0], to[1] + shadowOffset);
  #|     context.stroke();
  #|     context.strokeStyle = "#b9824b";
  #|     context.lineWidth = deckWidth;
  #|     context.beginPath();
  #|     context.moveTo(from[0], from[1]);
  #|     context.lineTo(to[0], to[1]);
  #|     context.stroke();
  #|     if (zoom >= 0.24) {
  #|       context.strokeStyle = "rgba(255,226,175,0.55)";
  #|       context.lineWidth = Math.max(0.7, zoom);
  #|       for (let step = 0.18; step < 0.95; step += 0.2) {
  #|         const x = from[0] + (to[0] - from[0]) * step;
  #|         const y = from[1] + (to[1] - from[1]) * step;
  #|         const nx = -(to[1] - from[1]);
  #|         const ny = to[0] - from[0];
  #|         const length = Math.hypot(nx, ny) || 1;
  #|         const reach = 2.2 * zoom;
  #|         context.beginPath();
  #|         context.moveTo(x - nx / length * reach, y - ny / length * reach);
  #|         context.lineTo(x + nx / length * reach, y + ny / length * reach);
  #|         context.stroke();
  #|       }
  #|     }
  #|   }
  #|   context.restore();
  #| }

///|
fn golden_draw_public_boardwalk(
  context : @dom.CanvasRenderingContext2D,
  sx : Double,
  sy : Double,
  zoom : Double,
  edge_mask : Int,
) -> Unit {
  golden_draw_public_boardwalk_scaled(
    context,
    sx,
    sy,
    zoom,
    edge_mask,
    golden_public_realm_boardwalk_casing_width(zoom),
    golden_public_realm_boardwalk_deck_width(zoom),
    golden_public_realm_boardwalk_shadow_offset(zoom),
  )
}
