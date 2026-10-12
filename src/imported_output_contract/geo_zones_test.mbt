///|
fn zones_collection() -> Array[@imported_output_contract.GeoFeature] {
  let source : Json = {
    "type": "FeatureCollection",
    "features": [
      {
        "type": "Feature",
        "id": "zone",
        "properties": { "name": "=District", "note": "retain" },
        "geometry": {
          "type": "Polygon",
          "coordinates": [
            [[0, 0], [10, 0], [10, 10], [0, 10], [0, 0]],
            [[3, 3], [7, 3], [7, 7], [3, 7], [3, 3]],
          ],
        },
      },
      {
        "type": "Feature",
        "properties": { "name": "inside" },
        "geometry": { "type": "Point", "coordinates": [1, 1, 12] },
      },
      {
        "type": "Feature",
        "properties": { "name": "edge" },
        "geometry": { "type": "Point", "coordinates": [0, 5] },
      },
      {
        "type": "Feature",
        "properties": { "name": "corner" },
        "geometry": { "type": "Point", "coordinates": [10, 10] },
      },
      {
        "type": "Feature",
        "properties": { "name": "hole" },
        "geometry": { "type": "Point", "coordinates": [5, 5] },
      },
      {
        "type": "Feature",
        "properties": { "name": "hole edge" },
        "geometry": { "type": "Point", "coordinates": [3, 5] },
      },
      {
        "type": "Feature",
        "properties": { "name": "outside" },
        "geometry": { "type": "Point", "coordinates": [11, 1] },
      },
      {
        "type": "Feature",
        "properties": null,
        "geometry": { "type": "LineString", "coordinates": [[1, 1], [2, 2]] },
      },
    ],
  }
  @imported_output_contract.parse_geojson(source.stringify()).unwrap()
}

///|
test "zone query includes outer boundary excludes holes and does not select routes" {
  let features = zones_collection()
  assert_eq(@imported_output_contract.geo_places_in_zone(features, 0), [1, 2, 3])
  assert_eq(@imported_output_contract.geo_matches(features, "", "Polygon"), [0])
  assert_eq(@imported_output_contract.geo_places_in_zone(features, 1), [])
  assert_eq(@imported_output_contract.geo_places_in_zone(features, -1), [])
  assert_eq(@imported_output_contract.geo_places_in_zone(features, 100), [])
  assert_eq(@imported_output_contract.geo_rings(features[0]).length(), 2)
  assert_eq(features[0].points.length(), 10)
  let selected = @imported_output_contract.geo_places_in_zone(features, 0)
  let exported = @imported_output_contract.parse_geojson(
    @imported_output_contract.geojson_selection(features, selected),
  ).unwrap()
  assert_eq(exported, [features[1], features[2], features[3]])
  assert_true(exported[0].source.stringify().contains("12"))
}

///|
test "zone and hole rings survive derived GeoJSON and vertex CSV" {
  let features = zones_collection()
  assert_eq(
    @imported_output_contract.parse_geojson(
      @imported_output_contract.geojson_selection(features, [0]),
    ).unwrap(),
    [features[0]],
  )
  let csv = @imported_output_contract.parse_data_table(
    @imported_output_contract.geo_csv(features, [0, 1]),
    ',',
  ).unwrap()
  assert_eq(csv.headers, [
    "name", "geometry", "category", "vertex", "longitude", "latitude", "ring", "ring_vertex",
  ])
  assert_eq(csv.rows.length(), 11)
  assert_eq(csv.rows[0][0], "'=District")
  assert_eq(csv.rows[0][6], "1")
  assert_eq(csv.rows[5][6], "2")
  assert_eq(csv.rows[5][7], "1")
  assert_eq(csv.rows[9][7], "5")
  assert_eq(csv.rows[10][6], "")
  let point_csv = @imported_output_contract.parse_data_table(
    @imported_output_contract.geo_csv(features, [1]),
    ',',
  ).unwrap()
  assert_eq(point_csv.headers.length(), 6)
}

///|
test "zone intake rejects unclosed short degenerate dateline and bad altitude rings" {
  for
    coordinates in [
      "[]", "[[[0,0],[1,0],[0,0]]]", "[[[0,0],[1,0],[1,1],[0,1]]]", "[[[0,0],[1,0],[2,0],[0,0]]]",
      "[[[179,0],[-179,0],[-179,1],[179,1],[179,0]]]", "[[[0,0,0],[1,0,0],[1,1,0],[0,0,1]]]",
      "[[[0,0],[1,0],[1,91],[0,0]]]", "[[[0,0],[2,0],[2,2],[0,0]],[[1,1],[1,1],[1,1],[1,1]]]",
    ] {
    let content = "{\"type\":\"FeatureCollection\",\"features\":[{\"type\":\"Feature\",\"properties\":null,\"geometry\":{\"type\":\"Polygon\",\"coordinates\":" +
      coordinates +
      "}}]}"
    assert_true(
      @imported_output_contract.parse_geojson(content) is Err(_),
      msg=coordinates,
    )
  }
}

///|
test "concave zones and reversed winding retain the same place membership" {
  let polygon = "[[[0,0],[4,0],[4,1],[1,1],[1,4],[0,4],[0,0]]]"
  let reversed = "[[[0,0],[0,4],[1,4],[1,1],[4,1],[4,0],[0,0]]]"
  for coordinates in [polygon, reversed] {
    let content = "{\"type\":\"FeatureCollection\",\"features\":[{\"type\":\"Feature\",\"properties\":null,\"geometry\":{\"type\":\"Polygon\",\"coordinates\":" +
      coordinates +
      "}},{\"type\":\"Feature\",\"properties\":null,\"geometry\":{\"type\":\"Point\",\"coordinates\":[3,3]}},{\"type\":\"Feature\",\"properties\":null,\"geometry\":{\"type\":\"Point\",\"coordinates\":[0.5,3]}}]}"
    let features = @imported_output_contract.parse_geojson(content).unwrap()
    assert_eq(@imported_output_contract.geo_places_in_zone(features, 0), [2])
  }
}
