///|
/// Geographic axes in the SAME registered ground coordinates as the roads.
/// Not a screen rotation. Positive u is east, positive v is north; z stays up.
priv struct TownBuildingBearing {
  east : WenyuScenePoint
  north : WenyuScenePoint
  deviation : Double
}

///|
/// WGS84 / UTM 50N, matching fit-wenyu-common-osm.mbtx.
fn town_bearing_utm(lon : Double, lat : Double) -> WenyuScenePoint {
  let e = 1.0 / 298.257223563 * (2.0 - 1.0 / 298.257223563)
  let ep = e / (1.0 - e)
  let phi = lat * @math.PI / 180.0
  let cp = @math.cos(phi)
  let sp = @math.sin(phi)
  let tangent = @math.tan(phi)
  let n = 6378137.0 / (1.0 - e * sp * sp).sqrt()
  let t = tangent * tangent
  let c = ep * cp * cp
  let a = cp * (lon - 117.0) * @math.PI / 180.0
  let a2 = a * a
  let a4 = a2 * a2
  let e4 = e * e
  let e6 = e4 * e
  let m = 6378137.0 *
    (
      (1.0 - e / 4.0 - 3.0 * e4 / 64.0 - 5.0 * e6 / 256.0) * phi -
      (3.0 * e / 8.0 + 3.0 * e4 / 32.0 + 45.0 * e6 / 1024.0) *
      @math.sin(2.0 * phi) +
      (15.0 * e4 / 256.0 + 45.0 * e6 / 1024.0) * @math.sin(4.0 * phi) -
      35.0 * e6 / 3072.0 * @math.sin(6.0 * phi)
    )
  {
    x: 500000.0 +
    0.9996 *
    n *
    (
      a +
      (1.0 - t + c) * a * a2 / 6.0 +
      (5.0 - 18.0 * t + t * t + 72.0 * c - 58.0 * ep) * a * a4 / 120.0
    ),
    y: 0.9996 *
    (
      m +
      n *
      tangent *
      (
        a2 / 2.0 +
        (5.0 - t + 9.0 * c + 4.0 * c * c) * a4 / 24.0 +
        (61.0 - 58.0 * t + t * t + 600.0 * c - 330.0 * ep) * a4 * a2 / 720.0
      )
    ),
  }
}

///|
/// Versioned road registration: four-corner affine -> pole-safe 21-point
/// normalized homography -> gentle (0.01,0.01). No riverside shifts.
/// Coefficients: wenyu-rebuilt-road-candidate.json and wenyu-lower-perspective.json.
fn town_bearing_geo_to_ground(lon : Double, lat : Double) -> WenyuScenePoint {
  let p = town_bearing_utm(lon, lat)
  let x = (
      0.021505258512121966 * p.x +
      0.006746213366656356 * p.y -
      39536.72962121634 -
      128.0
    ) /
    100.0
  let y = (
      0.0059070093413763234 * p.x -
      0.01658978691507238 * p.y +
      71085.21861921487 -
      72.0
    ) /
    100.0
  let w = 1.0 - 0.09962258585786689 * x - 0.17632187792159992 * y
  let u = 128.0 +
    100.0 *
    (0.9372475485526696 * x - 0.01966705328725691 * y - 0.05028298367976512) /
    w
  let v = 72.0 +
    100.0 *
    (0.000754741914753292 * x + 1.010927347170685 * y - 0.0501245048387618) /
    w
  let w = 1.0 + 0.01 * ((u - 256.0) / 256.0 - v / 144.0)
  { x: 256.0 + (u - 256.0) / w, y: v / w, }
}

///|
/// Invert locally to evaluate true east/north at each lot, not one global angle.
/// The reviewed map is smooth/pole-safe within this finite town extent.
fn town_bearing_at(x : Double, y : Double) -> TownBuildingBearing {
  let mut lon = 116.43
  let mut lat = 40.12
  for _ in 0..<8 {
    let p = town_bearing_geo_to_ground(lon, lat)
    let e = town_bearing_geo_to_ground(lon + 0.00001, lat)
    let n = town_bearing_geo_to_ground(lon, lat + 0.00001)
    let a = (e.x - p.x) / 0.00001
    let b = (n.x - p.x) / 0.00001
    let c = (e.y - p.y) / 0.00001
    let d = (n.y - p.y) / 0.00001
    let det = a * d - b * c
    lon += (d * (x - p.x) - b * (y - p.y)) / det
    lat += (a * (y - p.y) - c * (x - p.x)) / det
  }
  let p = town_bearing_geo_to_ground(lon, lat)
  // Equal approximate ground distances; one COMMON normalization preserves
  // the calibrated shear/foreshortening between the geographic axes.
  let e = town_bearing_geo_to_ground(
    lon + 0.00001 / @math.cos(lat * @math.PI / 180.0),
    lat,
  )
  let n = town_bearing_geo_to_ground(lon, lat + 0.00001)
  let scale = ((
    (e.x - p.x) * (e.x - p.x) +
    (e.y - p.y) * (e.y - p.y) +
    (n.x - p.x) * (n.x - p.x) +
    (n.y - p.y) * (n.y - p.y)
  ) /
  2.0).sqrt()
  {
    east: { x: (e.x - p.x) / scale, y: (e.y - p.y) / scale, },
    north: { x: (n.x - p.x) / scale, y: (n.y - p.y) / scale, },
    deviation: 0,
  }
}

///|
/// Only accept an actual nearby street axis within 10 geographic degrees of
/// cardinal alignment. Do not clamp arbitrary diagonal roads to a fake 10°.
fn town_bearing_street_deviation(
  b : TownBuildingBearing,
  dx : Double,
  dy : Double,
) -> Double {
  let det = b.east.x * b.north.y - b.north.x * b.east.y
  let east = (b.north.y * dx - b.north.x * dy) / det
  let north = (b.east.x * dy - b.east.y * dx) / det
  let angle = @math.atan2(north, east) * 180.0 / @math.PI
  let deviation = angle - (angle / 90.0).round() * 90.0
  if deviation.abs() <= 10.0 {
    deviation
  } else {
    0.0
  }
}

///|
fn town_bearing_turn(
  b : TownBuildingBearing,
  degrees : Double,
) -> TownBuildingBearing {
  let c = @math.cos(degrees * @math.PI / 180.0)
  let s = @math.sin(degrees * @math.PI / 180.0)
  {
    east: { x: b.east.x * c + b.north.x * s, y: b.east.y * c + b.north.y * s, },
    north: { x: b.north.x * c - b.east.x * s, y: b.north.y * c - b.east.y * s, },
    deviation: degrees,
  }
}

///|
let town_building_bearing_cache : Map[String, TownBuildingBearing] = Map([])

///|
fn town_building_bearing(
  building : IntersectionRoadPreviewBuilding,
) -> TownBuildingBearing {
  let (x, y) = intersection_road_preview_building_center(building)
  let key = "\{building.id}:\{x}:\{y}"
  match town_building_bearing_cache.get(key) {
    Some(b) => return b
    None => ()
  }
  let base = town_bearing_at(x, y)
  let mut best = 100.0
  let mut deviation = 0.0
  // Use complete displayed streets, not the filtered decorative walker paths.
  if town_street_nearest(x, y) is Some(hit) {
    let result = town_bearing_turn(
      base,
      town_bearing_street_deviation(base, hit.dx, hit.dy),
    )
    if town_building_bearing_cache.length() > 256 {
      town_building_bearing_cache.clear()
    }
    town_building_bearing_cache[key] = result
    return result
  }
  for path in wenyu_scene_paths {
    for i in 1..<path.points.length() {
      let a = path.points[i - 1]
      let b = path.points[i]
      let dx = b.x - a.x
      let dy = b.y - a.y
      let len = dx * dx + dy * dy
      if len < 0.04 {
        continue
      }
      let t = (((x - a.x) * dx + (y - a.y) * dy) / len).max(0.0).min(1.0)
      let px = a.x + t * dx - x
      let py = a.y + t * dy - y
      let distance = px * px + py * py
      if distance < best {
        best = distance
        deviation = town_bearing_street_deviation(base, dx, dy)
      }
    }
  }
  let result = town_bearing_turn(base, deviation)
  // Bounded by the displayed lots. New scenes never retain unbounded history.
  if town_building_bearing_cache.length() > 256 {
    town_building_bearing_cache.clear()
  }
  town_building_bearing_cache[key] = result
  result
}

///|
/// Fit the whole oriented lot within the already validated reservation.
/// Buildings do not move and the road/terrain masks are not relaxed.
fn town_bearing_span(
  b : TownBuildingBearing,
  width : Int,
  depth : Int,
) -> Double {
  (width.to_double() / (b.east.x.abs() + b.north.x.abs())).min(
    depth.to_double() / (b.east.y.abs() + b.north.y.abs()),
  )
}

///|
extern "js" fn town_bearing_buildings_requested() -> Bool =
  #| () => Boolean(globalThis.location) && new URLSearchParams(globalThis.location.search || '').get('building-bearing') === 'geo'
