///|
pub(all) struct GeoPoint {
  longitude : Double
  latitude : Double
} derive(Debug, Eq)

///|
pub(all) struct GeoFeature {
  name : String
  kind : String
  category : String
  points : Array[GeoPoint]
  source : Json
} derive(Debug, Eq)

///|
pub fn geojson_file(path : String, mime : String) -> Bool {
  path.to_lower().has_suffix(".geojson") ||
  mime.split(";").next().unwrap_or("").trim() == "application/geo+json"
}

///|
fn geo_field(value : Json, key : String) -> Json {
  match value {
    Object(o) => o.get(key).unwrap_or(Json::null())
    _ => Json::null()
  }
}

///|
fn geo_text(value : Json, key : String, fallback : String) -> String {
  match geo_field(value, key) {
    String(s) => s
    _ => fallback
  }
}

///|
fn geo_point(value : Json) -> GeoPoint? {
  guard value is Array(coords) && coords.length() >= 2 && coords.length() <= 3 else {
    return None
  }
  guard coords[0] is Number(lon) && coords[1] is Number(lat) else {
    return None
  }
  // Comparisons reject NaN as well as out-of-range and infinite coordinates.
  guard lon >= -180.0 && lon <= 180.0 && lat >= -90.0 && lat <= 90.0 else {
    return None
  }
  if coords.length() == 3 {
    guard coords[2] is Number(alt) && alt - alt == 0.0 else { return None }
  }
  Some({ longitude: lon, latitude: lat, })
}

///|
/// Bounded WGS84 FeatureCollection intake. Reject unsupported geometry instead
/// of quietly dropping features. Preserve complete source features for export.
pub fn parse_geojson(content : String) -> Result[Array[GeoFeature], String] {
  if @utf8.encode(content).length() > 1048576 {
    return Err("GeoJSON exceeds 1 MiB")
  }
  let value = match (try? @json.parse(content)) {
    Ok(j) => j
    Err(_) => return Err("Invalid GeoJSON JSON")
  }
  if geo_text(value, "type", "") != "FeatureCollection" {
    return Err("Expected a GeoJSON FeatureCollection")
  }
  if !(geo_field(value, "crs") is Null) {
    return Err("Legacy CRS is unsupported; supply WGS84 longitude/latitude")
  }
  guard geo_field(value, "features") is Array(features) else {
    return Err("Missing features array")
  }
  if features.length() > 2000 {
    return Err("GeoJSON exceeds 2,000 features")
  }
  let result : Array[GeoFeature] = []
  let mut total_points = 0
  for index, feature in features {
    let prefix = "Feature " + (index + 1).to_string() + ": "
    if geo_text(feature, "type", "") != "Feature" {
      return Err(prefix + "expected Feature")
    }
    if !(geo_field(feature, "crs") is Null) {
      return Err(prefix + "legacy CRS unsupported")
    }
    let geometry = geo_field(feature, "geometry")
    if !(geo_field(geometry, "crs") is Null) {
      return Err(prefix + "legacy CRS unsupported")
    }
    let kind = geo_text(geometry, "type", "")
    let coordinates = geo_field(geometry, "coordinates")
    let points : Array[GeoPoint] = []
    if kind == "Point" {
      match geo_point(coordinates) {
        Some(p) => points.push(p)
        None => return Err(prefix + "invalid Point coordinates")
      }
    } else if kind == "LineString" {
      guard coordinates is Array(coords) && coords.length() >= 2 else {
        return Err(prefix + "LineString needs at least two positions")
      }
      for c in coords {
        match geo_point(c) {
          Some(p) => points.push(p)
          None => return Err(prefix + "invalid LineString position")
        }
      }
    } else if kind == "Polygon" {
      match geo_polygon_rings(coordinates) {
        Ok(rings) =>
          for ring in rings {
            points.append(ring)
          }
        Err(reason) => return Err(prefix + reason)
      }
    } else {
      return Err(prefix + "only Point, LineString and Polygon are supported")
    }
    total_points += points.length()
    if total_points > 20000 {
      return Err("GeoJSON exceeds 20,000 positions")
    }
    let properties = geo_field(feature, "properties")
    if !(properties is (Null | Object(_))) {
      return Err(prefix + "properties must be an object or null")
    }
    result.push({
      name: geo_text(
        properties,
        "name",
        geo_text(properties, "title", "Feature " + (index + 1).to_string()),
      ),
      kind,
      category: geo_text(properties, "category", ""),
      points,
      source: feature,
    })
  }
  Ok(result)
}

///|
pub fn geo_matches(
  features : Array[GeoFeature],
  query : String,
  kind : String,
) -> Array[Int] {
  let needle = query.to_lower()
  let result : Array[Int] = []
  for index, feature in features {
    if (kind.is_empty() || feature.kind == kind) &&
      (
        feature.name.to_lower().contains(needle) ||
        feature.category.to_lower().contains(needle)
      ) {
      result.push(index)
    }
  }
  result
}

///|
/// Selection indices are deduplicated and emitted in source order. Original
/// properties, IDs and third coordinates survive the derived collection.
pub fn geojson_selection(
  features : Array[GeoFeature],
  selected : Array[Int],
) -> String {
  let rows : Array[Json] = []
  for index, feature in features {
    if selected.contains(index) {
      rows.push(feature.source)
    }
  }
  let result : Json = {
    "type": "FeatureCollection",
    "features": rows.to_json(),
  }
  result.stringify(indent=2) + "\n"
}

///|
/// One CSV row per geometry vertex; route order is preserved, not optimized.
pub fn geo_csv(features : Array[GeoFeature], selected : Array[Int]) -> String {
  let zones = selected.any(i => {
    i >= 0 && i < features.length() && features[i].kind == "Polygon"
  })
  let lines = [
    "name,geometry,category,vertex,longitude,latitude" +
    (if zones { ",ring,ring_vertex" } else { "" }),
  ]
  for index, feature in features {
    if !selected.contains(index) {
      continue
    }
    let rings = if feature.kind == "Polygon" {
      geo_rings(feature)
    } else {
      [feature.points]
    }
    let mut vertex = 0
    for ring_index, ring in rings {
      for ring_vertex, point in ring {
        vertex += 1
        let cells = [
          feature.name,
          feature.kind,
          feature.category,
          vertex.to_string(),
          point.longitude.to_string(),
          point.latitude.to_string(),
        ]
        if zones {
          cells.push(
            if feature.kind == "Polygon" {
              (ring_index + 1).to_string()
            } else {
              ""
            },
          )
          cells.push(
            if feature.kind == "Polygon" {
              (ring_vertex + 1).to_string()
            } else {
              ""
            },
          )
        }
        lines.push(cells.map(csv_cell).join(","))
      }
    }
  }
  lines.join("\r\n") + "\r\n"
}
