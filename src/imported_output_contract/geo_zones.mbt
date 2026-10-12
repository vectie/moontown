///|
/// Rings stay in source order: exterior first, followed by excluded holes.
/// Bounded planar intake; topology must be supplied as a valid simple polygon.
fn geo_polygon_rings(value : Json) -> Result[Array[Array[GeoPoint]], String] {
  guard value is Array(source) && !source.is_empty() else {
    return Err("Polygon needs an exterior ring")
  }
  let rings : Array[Array[GeoPoint]] = []
  let mut count = 0
  for raw in source {
    guard raw is Array(coords) && coords.length() >= 4 else {
      return Err("Polygon rings need at least four positions")
    }
    count += coords.length()
    if count > 20000 {
      return Err("Polygon exceeds 20,000 positions")
    }
    let ring : Array[GeoPoint] = []
    for c in coords {
      match geo_point(c) {
        Some(p) => ring.push(p)
        None => return Err("invalid Polygon position")
      }
    }
    if coords[0] != coords[coords.length() - 1] {
      return Err("Polygon rings must close with the identical first position")
    }
    let mut area = 0.0
    let origin = ring[0]
    for i in 1..<ring.length() {
      let a = ring[i - 1]
      let b = ring[i]
      if (a.longitude - b.longitude).abs() > 180.0 {
        return Err(
          "Dateline-crossing Polygon rings are unsupported; split the zone first",
        )
      }
      area += (a.longitude - origin.longitude) * (b.latitude - origin.latitude) -
        (b.longitude - origin.longitude) * (a.latitude - origin.latitude)
    }
    if area == 0.0 {
      return Err("Polygon ring has zero signed area")
    }
    rings.push(ring)
  }
  Ok(rings)
}

///|
/// Access validated Polygon rings without changing the original source feature.
pub fn geo_rings(feature : GeoFeature) -> Array[Array[GeoPoint]] {
  if feature.kind != "Polygon" {
    return []
  }
  match
    geo_polygon_rings(
      geo_field(geo_field(feature.source, "geometry"), "coordinates"),
    ) {
    Ok(rings) => rings
    Err(_) => []
  }
}

///|
/// 0 outside, 1 inside, 2 exactly on an edge. Longitude/latitude plane,
/// not a geodesic projection; no distance or area interpretation is implied.
fn geo_ring_location(point : GeoPoint, ring : Array[GeoPoint]) -> Int {
  let mut inside = false
  for i in 1..<ring.length() {
    let a = ring[i - 1]
    let b = ring[i]
    let cross = (point.longitude - a.longitude) * (b.latitude - a.latitude) -
      (point.latitude - a.latitude) * (b.longitude - a.longitude)
    if cross == 0.0 &&
      point.longitude >= a.longitude.min(b.longitude) &&
      point.longitude <= a.longitude.max(b.longitude) &&
      point.latitude >= a.latitude.min(b.latitude) &&
      point.latitude <= a.latitude.max(b.latitude) {
      return 2
    }
    if (a.latitude > point.latitude) != (b.latitude > point.latitude) {
      let crossing = (b.longitude - a.longitude) *
        (point.latitude - a.latitude) /
        (b.latitude - a.latitude) +
        a.longitude
      if point.longitude < crossing {
        inside = !inside
      }
    }
  }
  if inside {
    1
  } else {
    0
  }
}

///|
/// Return source indices of Point places within one Polygon, in source order.
/// Exterior boundary belongs to the zone; holes and their boundaries do not.
/// Lines and other polygons are not point locations and are not selected.
pub fn geo_places_in_zone(
  features : Array[GeoFeature],
  zone : Int,
) -> Array[Int] {
  if zone < 0 || zone >= features.length() {
    return []
  }
  let rings = geo_rings(features[zone])
  if rings.is_empty() {
    return []
  }
  let result : Array[Int] = []
  for i, feature in features {
    if feature.kind != "Point" || feature.points.is_empty() {
      continue
    }
    let point = feature.points[0]
    if geo_ring_location(point, rings[0]) == 0 {
      continue
    }
    let mut in_hole = false
    for ring in rings[1:] {
      if geo_ring_location(point, ring) != 0 {
        in_hole = true
        break
      }
    }
    if !in_hole {
      result.push(i)
    }
  }
  result
}
