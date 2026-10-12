///|
fn imported_zone_content() -> String {
  let value : Json = {
    "type": "FeatureCollection",
    "features": [
      {
        "type": "Feature",
        "id": "district",
        "properties": { "name": "North district" },
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
        "id": "inside",
        "properties": { "name": "Welcome", "category": "reception" },
        "geometry": { "type": "Point", "coordinates": [1, 1] },
      },
      {
        "type": "Feature",
        "properties": { "name": "Courtyard" },
        "geometry": { "type": "Point", "coordinates": [5, 5] },
      },
      {
        "type": "Feature",
        "properties": { "name": "Annex" },
        "geometry": { "type": "Point", "coordinates": [15, 1] },
      },
      {
        "type": "Feature",
        "properties": { "name": "Gallery", "category": "culture" },
        "geometry": { "type": "Point", "coordinates": [9, 9] },
      },
    ],
  }
  value.stringify()
}

///|
test "zone UI selects contained places and downloads source-preserving subset" {
  let state = imported_geo_fixture(imported_zone_content())
  let html = imported_fixture_render(state)
  assert_true(html.contains("Find places in a zone"))
  assert_true(html.contains("fill-rule=\"evenodd\""))
  assert_true(html.contains("<path"))
  assert_true(html.contains("Holes") || html.contains("holes"))
  let zone = imported_outputs_transition(state, GeoEvent(Zone("0"))).0
  assert_eq(zone.geo.zone, Some(0))
  assert_eq(zone.geo.kind, "Point")
  assert_true(imported_fixture_render(zone).contains("2 of 5 source features"))
  assert_true(imported_fixture_render(zone).contains("chosen zone outline"))
  let picked = imported_outputs_transition(zone, GeoEvent(SelectMatching)).0
  assert_eq(picked.geo.selected, [1, 4])
  let search = imported_outputs_transition(picked, GeoEvent(Query("reception"))).0
  assert_true(
    imported_fixture_render(search).contains("1 of 5 source features"),
  )
  assert_eq(search.geo.selected, [1, 4])
  let picked = imported_outputs_transition(search, GeoEvent(SelectMatching)).0
  guard imported_outputs_transition(picked, GeoEvent(Export(false))).1
    is Some(SaveFilteredTable(output, _)) else {
    fail("Zone export missing")
  }
  let result = @imported_output_contract.parse_geojson(output).unwrap()
  assert_eq(result.length(), 1)
  assert_eq(result[0].name, "Welcome")
  assert_true(output.contains("inside"))
  assert_false(output.contains("Courtyard"))
  assert_eq(imported_outputs_transition(picked, GeoEvent(Zone("1"))).0, picked)
  assert_eq(
    imported_outputs_transition(picked, GeoEvent(Zone("999"))).0,
    picked,
  )
  assert_eq(imported_outputs_transition(picked, GeoEvent(Zone("-1"))).0, picked)
  let all = imported_outputs_transition(picked, GeoEvent(Zone(""))).0
  assert_eq(all.geo.zone, None)
  assert_eq(all.geo.selected, [1])
  let polygons = imported_outputs_transition(zone, GeoEvent(Kind("Polygon"))).0
  assert_eq(polygons.geo.zone, None)
  assert_true(
    imported_fixture_render(polygons).contains("1 of 5 source features"),
  )
  let picked = imported_outputs_transition(polygons, GeoEvent(SelectMatching)).0
  guard imported_outputs_transition(picked, GeoEvent(Export(true))).1
    is Some(SaveFilteredTable(csv, _)) else {
    fail("Zone vertices missing")
  }
  assert_true(csv.contains("ring,ring_vertex"))
  assert_eq(
    @imported_output_contract.parse_data_table(csv, ',').unwrap().rows[0][0],
    "North district",
  )
  let reset = imported_outputs_transition(zone, RefreshImportedOutputs).0
  assert_eq(reset.geo.zone, None)
  assert_eq(imported_outputs_transition(reset, GeoEvent(Zone("0"))).0, reset)
}

///|
test "zone names stay inert and empty matching selection remains explicit" {
  let content = imported_zone_content().replace(
    old="North district",
    new="<script>zone</script>",
  )
  let state = imported_geo_fixture(content)
  let html = imported_fixture_render(state)
  assert_true(html.contains("&lt;script&gt;zone&lt;/script&gt;"))
  assert_false(html.contains("<script>zone"))
  let zone = imported_outputs_transition(state, GeoEvent(Zone("0"))).0
  let empty = imported_outputs_transition(zone, GeoEvent(Query("missing"))).0
  let empty = imported_outputs_transition(empty, GeoEvent(SelectMatching)).0
  assert_eq(empty.geo.selected, [])
  assert_true(
    imported_fixture_render(empty).contains("No source features match"),
  )
  assert_eq(imported_outputs_transition(empty, GeoEvent(Export(false))).1, None)
}
