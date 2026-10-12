///|
test "GeoJSON source preserved selected features and ordered vertex CSV" {
  let content =
    #|{"type":"FeatureCollection","features":[{"type":"Feature","id":"cafe","properties":{"name":"河畔 Cafe","category":"meeting","url":"javascript:alert(1)","extra":42},"geometry":{"type":"Point","coordinates":[116.4,40.1,8]}},{"type":"Feature","properties":{"name":"=Walk","category":"tour"},"geometry":{"type":"LineString","coordinates":[[116.4,40.1],[116.5,40.2]]}}]}
  let features = @imported_output_contract.parse_geojson(content).unwrap()
  assert_eq(features.length(), 2)
  assert_eq(features[0].name, "河畔 Cafe")
  assert_eq(features[1].points.length(), 2)
  assert_eq(@imported_output_contract.geo_matches(features, "CAFE", "Point"), [
    0,
  ])
  assert_eq(
    @imported_output_contract.geo_matches(features, "tour", "LineString"),
    [1],
  )
  assert_eq(@imported_output_contract.geo_matches(features, "tour", "Point"), [])
  let exported = @imported_output_contract.geojson_selection(features, [
    1, 0, 1, -1, 4,
  ])
  let again = @imported_output_contract.parse_geojson(exported).unwrap()
  assert_eq(again, features)
  let csv = @imported_output_contract.parse_data_table(
    @imported_output_contract.geo_csv(features, [1]),
    ',',
  ).unwrap()
  assert_eq(csv.rows.length(), 2)
  assert_eq(csv.rows[0][0], "'=Walk")
  assert_eq(csv.rows[1][3], "2")
  assert_eq(csv.rows[1][4], "116.5")
}

///|
test "GeoJSON rejects malformed unsupported and invalid coordinate collections" {
  let invalid = [
    "{}", "[]", "not JSON", "{\"type\":\"FeatureCollection\",\"features\":{},\"crs\":{}}",
    "{\"type\":\"FeatureCollection\",\"features\":[null]}",
  ]
  for text in invalid {
    assert_true(@imported_output_contract.parse_geojson(text) is Err(_))
  }
  for
    geometry in [
      "null", "{\"type\":\"Polygon\",\"coordinates\":[]}", "{\"type\":\"Point\",\"coordinates\":[181,40]}",
      "{\"type\":\"Point\",\"coordinates\":[116,-91]}", "{\"type\":\"Point\",\"coordinates\":[116,40,\"height\"]}",
      "{\"type\":\"LineString\",\"coordinates\":[[0,0]]}", "{\"type\":\"LineString\",\"coordinates\":[[0,0],[1]]}",
    ] {
    let text = "{\"type\":\"FeatureCollection\",\"features\":[{\"type\":\"Feature\",\"properties\":null,\"geometry\":" +
      geometry +
      "}]}"
    assert_true(@imported_output_contract.parse_geojson(text) is Err(_))
  }
  let empty = @imported_output_contract.parse_geojson(
    "{\"type\":\"FeatureCollection\",\"features\":[]}",
  ).unwrap()
  assert_eq(empty.length(), 0)
  assert_eq(@imported_output_contract.geo_matches(empty, "", ""), [])
}

///|
test "GeoJSON recognition boundaries fallback names and bounds" {
  assert_true(
    @imported_output_contract.geojson_file(
      "places.GEOJSON", "application/octet-stream",
    ),
  )
  assert_true(
    @imported_output_contract.geojson_file(
      "places.json", "application/geo+json; charset=utf-8",
    ),
  )
  assert_false(
    @imported_output_contract.geojson_file("places.json", "application/json"),
  )
  let features = @imported_output_contract.parse_geojson(
    "{\"type\":\"FeatureCollection\",\"features\":[{\"type\":\"Feature\",\"properties\":null,\"geometry\":{\"type\":\"Point\",\"coordinates\":[-180,90]}}]}",
  ).unwrap()
  assert_eq(features[0].name, "Feature 1")
  assert_eq(features[0].points[0].latitude, 90.0)
  assert_eq(
    @imported_output_contract.parse_geojson(
      @imported_output_contract.geojson_selection(features, []),
    ).unwrap(),
    [],
  )
}

///|
test "GeoJSON input and geometry caps reject oversized data" {
  let point = "{\"type\":\"Feature\",\"properties\":null,\"geometry\":{\"type\":\"Point\",\"coordinates\":[0,0]}}"
  let features = Array::make(2001, point).join(",")
  assert_true(
    @imported_output_contract.parse_geojson(
      "{\"type\":\"FeatureCollection\",\"features\":[" + features + "]}",
    )
    is Err(_),
  )
  let vertices = Array::make(20001, "[0,0]").join(",")
  assert_true(
    @imported_output_contract.parse_geojson(
      "{\"type\":\"FeatureCollection\",\"features\":[{\"type\":\"Feature\",\"properties\":null,\"geometry\":{\"type\":\"LineString\",\"coordinates\":[" +
      vertices +
      "]}}]}",
    )
    is Err(_),
  )
  assert_true(
    @imported_output_contract.parse_geojson(Array::make(1048577, " ").join(""))
    is Err(_),
  )
}
