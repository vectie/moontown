///|
/// Join a complete CSV/TSV place table to all polygons in a separate GeoJSON
/// FeatureCollection. Output includes unmatched rows and every overlap, retaining
/// exact input byte digests and 1-based source rows/features. Column inputs are
/// zero-based. This is a planar local exploration, not geodesic/GIS authority.
pub fn table_zones_export(
  table_bytes : Bytes,
  zone_bytes : Bytes,
  delimiter : Char,
  latitude~ : Int,
  longitude~ : Int,
  name~ : Int,
  category~ : Int,
  format~ : String,
) -> Result[String, String] {
  if format != "geojson" && format != "csv" {
    return Err("Choose geojson or csv")
  }
  if table_bytes.length() > 1048576 || zone_bytes.length() > 1048576 {
    return Err("Each source must be at most 1 MiB")
  }
  let table_text = match (try? @utf8.decode(table_bytes)) {
    Ok(text) => text
    Err(_) => return Err("Place table must be valid UTF-8")
  }
  let zone_text = match (try? @utf8.decode(zone_bytes)) {
    Ok(text) => text
    Err(_) => return Err("Zones must be valid UTF-8")
  }
  let table = match parse_data_table(table_text, delimiter) {
    Ok(value) => value
    Err(error) => return Err("Place table: " + error)
  }
  let places = match table.places(latitude~, longitude~, name~, category~) {
    Ok(value) => value
    Err(error) => return Err("Place table: " + error)
  }
  let features = match parse_geojson(zone_text) {
    Ok(value) => value
    Err(error) => return Err("Zones: " + error)
  }
  let zones = geo_matches(features, "", "Polygon")
  if zones.is_empty() {
    return Err("Zones source must contain at least one Polygon")
  }
  let mut zone_points = 0
  for z in zones {
    zone_points += features[z].points.length()
  }
  if places.length() * zone_points > 20000000 {
    return Err(
      "Join exceeds 20 million point/zone-position checks; narrow the sources",
    )
  }
  let memberships : Array[Array[Int]] = places.map(_ => [])
  let mut total_matches = 0
  // Reuse the established outer-edge/hole policy, with one parsed ring set per
  // zone, without merging or rewriting either source FeatureCollection.
  for z in zones {
    let rings = geo_rings(features[z])
    for p, place in places {
      let point = place.points[0]
      if geo_ring_location(point, rings[0]) != 0 &&
        !rings[1:].iter().any(ring => geo_ring_location(point, ring) != 0) {
        memberships[p].push(z)
        total_matches += 1
        if total_matches > 10000 {
          return Err(
            "Join exceeds 10,000 output associations; narrow the sources",
          )
        }
      }
    }
  }
  let unmatched = memberships.filter(xs => xs.is_empty()).length()
  let overlaps = memberships.filter(xs => xs.length() > 1).length()
  if total_matches + unmatched > 10000 {
    return Err("Join exceeds 10,000 output associations; narrow the sources")
  }
  let table_digest = "sha256:" +
    @crypto.bytes_to_hex_string(@crypto.sha256(table_bytes))
  let zone_digest = "sha256:" +
    @crypto.bytes_to_hex_string(@crypto.sha256(zone_bytes))
  if format == "csv" {
    return table_zones_csv(
      table, features, memberships, table_digest, zone_digest,
    )
  }
  let metadata : Json = {
    "contract": "moontown.table-zone-join.v1",
    "table_source": {
      "digest": table_digest,
      "size_bytes": table_bytes.length(),
    },
    "zone_source": { "digest": zone_digest, "size_bytes": zone_bytes.length() },
    "columns_1based": {
      "latitude": latitude + 1,
      "longitude": longitude + 1,
      "name": name + 1,
      "category": category + 1,
    },
    "summary": {
      "places": places.length(),
      "zones": zones.length(),
      "ignored_non_polygon_features": features.length() - zones.length(),
      "matched_places": places.length() - unmatched,
      "unmatched_places": unmatched,
      "overlapping_places": overlaps,
      "memberships": total_matches,
    },
    "membership_policy": "Planar WGS84; exterior boundary included; holes and hole boundaries excluded; every overlap retained",
  }
  let chunks = [
    "{\"type\":\"FeatureCollection\",\"moontown_zone_join\":" +
    metadata.stringify() +
    ",\"features\":[",
  ]
  let mut bytes = @utf8.encode(chunks[0]).length() + 3
  for p, place in places {
    let joined_zones = memberships[p].map(z => {
      table_zone_reference(features[z], z)
    })
    let feature : Json = {
      "type": "Feature",
      "id": geo_field(place.source, "id"),
      "geometry": geo_field(place.source, "geometry"),
      "properties": {
        "name": place.name,
        "category": place.category,
        "source_table": geo_field(
          geo_field(place.source, "properties"),
          "source_table",
        ),
        "zone_memberships": joined_zones,
      },
    }
    let chunk = (if p == 0 { "" } else { "," }) + feature.stringify()
    bytes += @utf8.encode(chunk).length()
    if bytes > 4 * 1048576 {
      return Err("Joined output exceeds 4 MiB; narrow the sources")
    }
    chunks.push(chunk)
  }
  chunks.push("]}\n")
  Ok(chunks.join(""))
}

///|
fn table_zone_reference(zone : GeoFeature, source_index : Int) -> Json {
  {
    "source_feature": source_index + 1,
    "id": geo_field(zone.source, "id"),
    "name": zone.name,
    "category": zone.category,
  }
}
