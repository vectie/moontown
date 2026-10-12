///|
fn join_zones_source() -> String {
  let value : Json = {
    "type": "FeatureCollection",
    "features": [
      {
        "type": "Feature",
        "properties": null,
        "geometry": { "type": "Point", "coordinates": [1, 1] },
      },
      {
        "type": "Feature",
        "id": "same-id",
        "properties": { "name": "=North", "category": "district" },
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
        "id": "same-id",
        "properties": { "name": "東区", "category": "@district" },
        "geometry": {
          "type": "Polygon",
          "coordinates": [[[8, 0], [12, 0], [12, 10], [8, 10], [8, 0]]],
        },
      },
    ],
  }
  value.stringify()
}

///|
fn join_table_source() -> String {
  "name,lat,lon,kind,note,note\r\nInside,1,1,venue,001,\"line one\nline two\"\r\nEdge,5,0,venue,002,edge\r\nHole,5,5,venue,003,hole\r\nOverlap,1,9,venue,004,both\r\nOutside,20,20,venue,005,outside\r\nHole edge,5,3,venue,006,excluded\r\nCorner,10,10,venue,007,both\r\n"
}

///|
fn joined(
  table : String,
  zones : String,
  format : String,
  delimiter? : Char = ',',
) -> String raise {
  match
    @imported_output_contract.table_zones_export(
      @utf8.encode(table),
      @utf8.encode(zones),
      delimiter,
      latitude=1,
      longitude=2,
      name=0,
      category=3,
      format~,
    ) {
    Ok(value) => value
    Err(error) => fail(error)
  }
}

///|
test "separate source join preserves every overlap and unmatched original data row" {
  let csv = joined(join_table_source(), join_zones_source(), "csv")
  let result = @imported_output_contract.parse_data_table(csv, ',').unwrap()
  assert_eq(result.rows.length(), 9)
  assert_eq(result.rows.map(row => row[2]), [
    "1", "2", "3", "4", "4", "5", "6", "7", "7",
  ])
  assert_eq(result.rows.map(row => row[3]), [
    "1", "1", "0", "2", "2", "0", "0", "2", "2",
  ])
  assert_eq(result.rows.map(row => row[4]), [
    "2", "2", "", "2", "3", "", "", "2", "3",
  ])
  assert_eq(result.rows[0][5], "\"same-id\"")
  assert_eq(result.rows[0][6], "'=North")
  assert_eq(result.rows[4][7], "'@district")
  assert_eq(result.rows[0][12], "001")
  assert_eq(result.rows[0][13], "line one\nline two")
  assert_eq(result.headers[12:], ["note", "note"])
  assert_eq(result.rows[2][4:8], ["", "", "", ""])
  assert_eq(csv, joined(join_table_source(), join_zones_source(), "csv"))
}

///|
test "GeoJSON joined places retain ordered source cells and exact input identities" {
  let output = joined(join_table_source(), join_zones_source(), "geojson")
  let value = @json.parse(output)
  guard value
    is {
      "moontown_zone_join": {
        "summary": {
          "places": 7,
          "zones": 2,
          "ignored_non_polygon_features": 1,
          "matched_places": 4,
          "unmatched_places": 3,
          "overlapping_places": 2,
          "memberships": 6,
          ..
        },
        "columns_1based": {
          "latitude": 2,
          "longitude": 3,
          "name": 1,
          "category": 4,
        },
        "table_source": {
          "digest": String(table_digest),
          "size_bytes": Number(table_size),
        },
        "zone_source": { "digest": String(zone_digest), .. },
        ..
      },
      "features": Array(features),
      ..
    } else {
    fail("join metadata")
  }
  assert_eq(table_size, @utf8.encode(join_table_source()).length().to_double())
  assert_true(table_digest.has_prefix("sha256:") && table_digest.length() == 71)
  assert_true(zone_digest.has_prefix("sha256:") && zone_digest != table_digest)
  assert_eq(features.length(), 7)
  guard features[3]
    is {
      "properties": {
        "source_table": { "data_row": 4, .. },
        "zone_memberships": [
          { "source_feature": 2, "id": "same-id", .. },
          { "source_feature": 3, "id": "same-id", .. },
        ],
        ..
      },
      ..
    } else {
    fail("overlap provenance")
  }
  guard features[2] is { "properties": { "zone_memberships": [], .. }, .. } else {
    fail("unmatched retained")
  }
  let reimported = @imported_output_contract.parse_geojson(output).unwrap()
  assert_eq(reimported.length(), 7)
  assert_eq(reimported[0].name, "Inside")
  assert_true(reimported[0].source.stringify().contains("001"))
  assert_eq(output, joined(join_table_source(), join_zones_source(), "geojson"))
}

///|
test "join accepts TSV empty tables and keeps formula strings unchanged in GeoJSON" {
  let output = joined(
    "name\tlat\tlon\tkind\n=Gate\t-1\t-2\t@venue\n",
    join_zones_source(),
    "geojson",
    delimiter='\t',
  )
  let reimported = @imported_output_contract.parse_geojson(output).unwrap()
  assert_eq(reimported[0].name, "=Gate")
  assert_eq(reimported[0].category, "@venue")
  let empty = joined("name,lat,lon,kind\n", join_zones_source(), "geojson")
  guard @json.parse(empty)
    is {
      "features": [],
      "moontown_zone_join": {
        "summary": { "places": 0, "unmatched_places": 0, .. },
        ..
      },
      ..
    } else {
    fail("empty table")
  }
  assert_eq(
    @imported_output_contract.parse_data_table(
      joined("name,lat,lon,kind\n", join_zones_source(), "csv"),
      ',',
    ).unwrap().rows,
    [],
  )
}

///|
test "join rejects ambiguous mapping invalid sources and unsupported zones atomically" {
  let table = @utf8.encode(join_table_source())
  let zones = @utf8.encode(join_zones_source())
  assert_true(
    @imported_output_contract.table_zones_export(
      table,
      zones,
      ',',
      latitude=1,
      longitude=1,
      name=0,
      category=3,
      format="csv",
    )
    is Err(_),
  )
  assert_true(
    @imported_output_contract.table_zones_export(
      table,
      zones,
      ',',
      latitude=-1,
      longitude=2,
      name=0,
      category=3,
      format="csv",
    )
    is Err(_),
  )
  for
    source in [
      "", "{}", "{\"type\":\"FeatureCollection\",\"features\":[]}", "{\"type\":\"FeatureCollection\",\"features\":[{\"type\":\"Feature\",\"properties\":null,\"geometry\":{\"type\":\"Point\",\"coordinates\":[0,0]}}]}",
    ] {
    assert_true(
      @imported_output_contract.table_zones_export(
        table,
        @utf8.encode(source),
        ',',
        latitude=1,
        longitude=2,
        name=0,
        category=3,
        format="csv",
      )
      is Err(_),
    )
  }
  assert_true(
    @imported_output_contract.table_zones_export(
      table,
      zones,
      ',',
      latitude=1,
      longitude=2,
      name=0,
      category=3,
      format="json",
    )
    is Err(_),
  )
  assert_eq(
    @imported_output_contract.table_zones_export(
      b"\xff",
      zones,
      ',',
      latitude=1,
      longitude=2,
      name=0,
      category=3,
      format="csv",
    ),
    Err("Place table must be valid UTF-8"),
  )
  assert_eq(
    @imported_output_contract.table_zones_export(
      table,
      b"\xff",
      ',',
      latitude=1,
      longitude=2,
      name=0,
      category=3,
      format="csv",
    ),
    Err("Zones must be valid UTF-8"),
  )
  assert_true(
    @imported_output_contract.table_zones_export(
      @utf8.encode("name,lat,lon,kind\nBad,NaN,0,place\n"),
      zones,
      ',',
      latitude=1,
      longitude=2,
      name=0,
      category=3,
      format="csv",
    )
    is Err(_),
  )
  assert_true(
    @imported_output_contract.table_zones_export(
      @utf8.encode("x".repeat(1048577)),
      zones,
      ',',
      latitude=1,
      longitude=2,
      name=0,
      category=3,
      format="csv",
    )
    is Err(_),
  )
}

///|
test "join caps overlap amplification and derived output without a partial result" {
  let polygon : Json = {
    "type": "Feature",
    "properties": { "name": "zone" },
    "geometry": {
      "type": "Polygon",
      "coordinates": [[[0, 0], [10, 0], [10, 10], [0, 10], [0, 0]]],
    },
  }
  let many : Json = {
    "type": "FeatureCollection",
    "features": Array::make(21, polygon),
  }
  let table = "name,lat,lon,kind\n" + "A,1,1,B\n".repeat(500)
  assert_eq(
    @imported_output_contract.table_zones_export(
      @utf8.encode(table),
      @utf8.encode(many.stringify()),
      ',',
      latitude=1,
      longitude=2,
      name=0,
      category=3,
      format="csv",
    ),
    Err("Join exceeds 10,000 output associations; narrow the sources"),
  )
  let big_label : Json = {
    "type": "FeatureCollection",
    "features": [
      {
        "type": "Feature",
        "properties": { "name": "n".repeat(10000) },
        "geometry": {
          "type": "Polygon",
          "coordinates": [[[0, 0], [10, 0], [10, 10], [0, 10], [0, 0]]],
        },
      },
    ],
  }
  for format in ["csv", "geojson"] {
    assert_eq(
      @imported_output_contract.table_zones_export(
        @utf8.encode(table),
        @utf8.encode(big_label.stringify()),
        ',',
        latitude=1,
        longitude=2,
        name=0,
        category=3,
        format~,
      ),
      Err("Joined output exceeds 4 MiB; narrow the sources"),
    )
  }
}
