///|
fn places_table(
  text : String,
  delimiter? : Char = ',',
) -> @imported_output_contract.DataTable raise {
  match @imported_output_contract.parse_data_table(text, delimiter) {
    Ok(table) => table
    Err(reason) => fail(reason)
  }
}

///|
test "explicit places mapping preserves all columns and reuses GeoJSON search and export" {
  let table = places_table(
    "label,lat,lon,group,note,note\r\nNorth Gate,40.1,116.2,reception,001,\"Meet, outside\"\r\nGallery,40.2,116.3,arts,002,\"line one\nline two\"\r\n",
  )
  let original = table.rows.copy()
  guard table.places(latitude=1, longitude=2, name=0, category=3)
    is Ok(features) else {
    fail("places")
  }
  assert_eq(features.length(), 2)
  assert_eq(features[0].points, [{ longitude: 116.2, latitude: 40.1, }])
  assert_eq(
    @imported_output_contract.geo_matches(features, "RECEPTION", "Point"),
    [0],
  )
  let selected = @imported_output_contract.geojson_selection(features, [1, 0, 1])
  guard @imported_output_contract.parse_geojson(selected) is Ok(reloaded) else {
    fail("roundtrip")
  }
  assert_eq(features, reloaded)
  assert_true(selected.contains("001"))
  assert_true(selected.contains("Meet, outside"))
  assert_eq(features[0].source, {
    "type": "Feature",
    "id": "table-row-1",
    "geometry": { "type": "Point", "coordinates": [116.2, 40.1] },
    "properties": {
      "name": "North Gate",
      "category": "reception",
      "source_table": {
        "data_row": 1,
        "headers": ["label", "lat", "lon", "group", "note", "note"],
        "cells": [
          "North Gate", "40.1", "116.2", "reception", "001", "Meet, outside",
        ],
      },
    },
  })
  assert_eq(table.rows, original)
  let csv = table.selection_csv([1, 1, -1, 99])
  let restored = places_table(csv)
  assert_eq(restored.headers, table.headers)
  assert_eq(restored.rows, [table.rows[1]])
  assert_eq(places_table(table.selection_csv([])).rows, [])
}

///|
test "places mapping disambiguates duplicate headers and rejects missing or reused columns" {
  let table = places_table("name,x,x,category\nA,1,2,B\n")
  assert_true(
    table.places(latitude=1, longitude=2, name=0, category=3) is Ok(_),
  )
  assert_true(
    table.places(latitude=-1, longitude=2, name=0, category=3) is Err(_),
  )
  assert_true(
    table.places(latitude=1, longitude=4, name=0, category=3) is Err(_),
  )
  assert_true(
    table.places(latitude=1, longitude=1, name=0, category=3) is Err(_),
  )
  assert_true(
    table.places(latitude=1, longitude=2, name=2, category=3) is Err(_),
  )
  let headers_only = places_table("name,lat,lon,category\n")
  assert_eq(
    headers_only.places(latitude=1, longitude=2, name=0, category=3),
    Ok([]),
  )
}

///|
test "places intake accepts zero signed boundaries exponent and surrounding coordinate whitespace" {
  let table = places_table(
    "name\tlat\tlon\tcategory\nZero\t0\t0\t\nSouth\t-90\t-180\tedge\nNorth\t 9e1 \t 1.8e2 \tedge\n",
    delimiter='\t',
  )
  guard table.places(latitude=1, longitude=2, name=0, category=3)
    is Ok(features) else {
    fail("valid coordinates")
  }
  assert_eq(features[0].points, [{ longitude: 0, latitude: 0, }])
  assert_eq(features[1].points, [{ longitude: -180, latitude: -90, }])
  assert_eq(features[2].points, [{ longitude: 180, latitude: 90, }])
  assert_true(features[2].source.stringify().contains(" 9e1 "))
}

///|
test "places intake rejects invalid coordinates atomically with exact data row" {
  for
    value in [
      "", " ", "NaN", "Infinity", "1e999", "90.1", "-90.1", "12north", "40°", "\"40,1\"",
    ] {
    let table = places_table(
      "name,lat,lon,category\nGood,40,116,ok\nBad," + value + ",116,broken\n",
    )
    assert_eq(
      table.places(latitude=1, longitude=2, name=0, category=3),
      Err("Data row 2: latitude must be a number from -90 to 90"),
    )
  }
  for value in ["181", "-181", "NaN", "", "2east"] {
    let table = places_table(
      "name,lat,lon,category\nBad,40," + value + ",broken\n",
    )
    assert_eq(
      table.places(latitude=1, longitude=2, name=0, category=3),
      Err("Data row 1: longitude must be a number from -180 to 180"),
    )
  }
}

///|
test "places bounded input rejects excess rows malformed public tables and oversized derived data" {
  let table : @imported_output_contract.DataTable = {
    headers: ["name", "lat", "lon", "category"],
    rows: Array::make(2001, ["Place", "0", "0", "site"]),
  }
  assert_true(
    table.places(latitude=1, longitude=2, name=0, category=3) is Err(_),
  )
  let malformed = { ..table, rows: [["Short", "0", "0"]], }
  assert_eq(
    malformed.places(latitude=1, longitude=2, name=0, category=3),
    Err("Data row 1: column count differs from the header"),
  )
  let large = {
    ..table,
    headers: ["name", "lat", "lon", "category", "note"],
    rows: Array::make(500, ["Place", "0", "0", "site", "x".repeat(2000)]),
  }
  assert_eq(
    large.places(latitude=1, longitude=2, name=0, category=3),
    Err("Derived places exceed the 1 MiB GeoJSON limit; use a smaller table"),
  )
}

///|
test "places preserves reserved-looking headers empty labels and spreadsheet safety" {
  let table = places_table(
    "name,lat,lon,category,source_table,,name\n=Place,-1,-2,@site,original,empty label,Other\n",
  )
  guard table.places(latitude=1, longitude=2, name=0, category=3)
    is Ok(features) else {
    fail("places")
  }
  assert_true(features[0].source.stringify().contains("original"))
  assert_eq(features[0].name, "=Place")
  let csv = places_table(table.selection_csv([0]))
  assert_eq(csv.headers, table.headers)
  assert_eq(csv.rows[0], [
    "'=Place", "'-1", "'-2", "'@site", "original", "empty label", "Other",
  ])
}
