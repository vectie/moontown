///|
fn map_places_columns(state : ImportedOutputsState) -> ImportedOutputsState {
  let mut result = state
  for role, column in ["1", "2", "0", "3"] {
    result = imported_outputs_transition(
        result,
        PlacesEvent(Column(role, column)),
      ).0
  }
  result
}

///|
fn places_fixture() -> ImportedOutputsState raise {
  imported_table_fixture(
    "Place,North,East,Type,Note,Note\nWelcome Pavilion,40.11,116.41,reception,001,\"Meet, outside\"\nGallery,40.12,116.42,arts,002,desk\nWest Gate,40.10,116.40,reception,003,=TEXT\n",
  )
}

///|
test "table places maps explicit columns and explores filters selects and exports original rows" {
  let initial = places_fixture()
  assert_eq(initial.places.columns, [-1, -1, -1, -1])
  assert_eq(initial.geo.features, None)
  assert_true(imported_fixture_render(initial).contains("Latitude column"))
  assert_true(imported_fixture_render(initial).contains("6: Note"))
  let initial = imported_outputs_transition(
      initial,
      SearchImportedTable("Gallery"),
    ).0
  let mapped = imported_outputs_transition(
      map_places_columns(initial),
      PlacesEvent(Explore),
    ).0
  let html = imported_fixture_render(mapped)
  assert_true(html.contains("Table places explorer"))
  assert_true(html.contains("3 of 3 source features"))
  assert_true(html.contains("<circle"))
  assert_true(html.contains("Download exact file"))
  let filtered = imported_outputs_transition(
      mapped,
      GeoEvent(Query("RECEPTION")),
    ).0
  assert_true(
    imported_fixture_render(filtered).contains("2 of 3 source features"),
  )
  let selected = imported_outputs_transition(filtered, GeoEvent(SelectMatching)).0
  assert_eq(selected.geo.selected, [0, 2])
  guard imported_outputs_transition(selected, GeoEvent(Export(false))).1
    is Some(SaveFilteredTable(json, filename)) else {
    fail("GeoJSON export")
  }
  assert_eq(filename, "selected-places.geojson")
  guard @imported_output_contract.parse_geojson(json) is Ok(features) else {
    fail("GeoJSON")
  }
  assert_eq(features.map(f => f.name), ["Welcome Pavilion", "West Gate"])
  assert_true(json.contains("001"))
  assert_true(json.contains("Meet, outside"))
  assert_true(json.contains("=TEXT"))
  assert_true(json.contains("source_table"))
  guard imported_outputs_transition(selected, GeoEvent(Export(true))).1
    is Some(SaveFilteredTable(csv, _)) else {
    fail("CSV export")
  }
  guard @imported_output_contract.parse_data_table(csv, ',') is Ok(table) else {
    fail("CSV")
  }
  assert_eq(table.headers, ["Place", "North", "East", "Type", "Note", "Note"])
  assert_eq(table.rows.map(r => r[0]), ["Welcome Pavilion", "West Gate"])
  assert_eq(table.rows[1][5], "'=TEXT")
  assert_eq(selected.text, initial.text)
  let raw = imported_outputs_transition(selected, GeoEvent(Raw)).0
  assert_true(imported_fixture_render(raw).contains("Place,North,East,Type"))
  assert_false(
    imported_fixture_render(raw).contains(
      "Coordinate schematic of imported features",
    ),
  )
  let table_view = imported_outputs_transition(
      selected,
      ShowImportedTable(true),
    ).0
  assert_false(table_view.places.show)
  assert_true(imported_fixture_render(table_view).contains("1 of 3 data rows"))
  let remapped = imported_outputs_transition(table_view, PlacesEvent(Explore)).0
  assert_eq(remapped.geo.selected, [])
  assert_eq(remapped.geo.query, "")
}

///|
test "table places errors leave original accessible and stop entire invalid intake" {
  let initial = places_fixture()
  let unset = imported_outputs_transition(initial, PlacesEvent(Explore)).0
  assert_true(
    imported_fixture_render(unset).contains("Choose a column for latitude"),
  )
  assert_eq(unset.geo.features, None)
  let duplicate = imported_outputs_transition(
      map_places_columns(initial),
      PlacesEvent(Column(1, "1")),
    ).0
  let duplicate = imported_outputs_transition(duplicate, PlacesEvent(Explore)).0
  assert_true(duplicate.places.error.contains("distinct columns"))
  let invalid = imported_table_fixture(
    "Name,Lat,Lon,Category\nGood,40,116,site\nBroken,,116,site\n",
  )
  let invalid = imported_outputs_transition(
      map_places_columns(invalid),
      PlacesEvent(Explore),
    ).0
  assert_true(imported_fixture_render(invalid).contains("Data row 2: latitude"))
  assert_true(imported_fixture_render(invalid).contains("Download exact file"))
  assert_false(
    imported_fixture_render(invalid).contains(
      "Coordinate schematic of imported features",
    ),
  )
  assert_eq(
    imported_outputs_transition(invalid, GeoEvent(Export(false))).1,
    None,
  )
  assert_eq(
    imported_outputs_transition(initial, PlacesEvent(Column(4, "0"))).0,
    initial,
  )
  assert_eq(
    imported_outputs_transition(initial, PlacesEvent(Column(0, "99"))).0,
    initial,
  )
}

///|
test "table places TSV zero coordinates source-safe rendering pagination and full selection exports" {
  let rows = Array::make(30, "<Place>\t0\t0\tmarker\t<script>")
  let state = imported_table_fixture(
    "Name\tLat\tLon\tType\t<img>\n" + rows.join("\n"),
    filename="places.tsv",
  )
  let state = imported_outputs_transition(
      map_places_columns(state),
      PlacesEvent(Explore),
    ).0
  let html = imported_fixture_render(state)
  assert_true(html.contains("&lt;Place&gt;"))
  assert_true(html.contains("&lt;img&gt;"))
  assert_false(html.contains("<script>"))
  assert_false(html.contains("<img>"))
  assert_true(html.contains("Showing features 1–25 of 30 matches"))
  let page = imported_outputs_transition(state, GeoEvent(Page(1))).0
  assert_true(
    imported_fixture_render(page).contains(
      "Showing features 26–30 of 30 matches",
    ),
  )
  let selected = imported_outputs_transition(page, GeoEvent(SelectMatching)).0
  assert_eq(selected.geo.selected.length(), 30)
  guard imported_outputs_transition(selected, GeoEvent(Export(false))).1
    is Some(SaveFilteredTable(json, _)) else {
    fail("all pages")
  }
  guard @imported_output_contract.parse_geojson(json) is Ok(features) else {
    fail("export")
  }
  assert_eq(features.length(), 30)
  assert_eq(features[0].points, [{ longitude: 0, latitude: 0, }])
}

///|
test "table places changing mapping or drawer source clears derived state and fences stale replies" {
  let state = imported_outputs_transition(
      map_places_columns(places_fixture()),
      PlacesEvent(Explore),
    ).0
  let selected = imported_outputs_transition(state, GeoEvent(SelectMatching)).0
  let changed = imported_outputs_transition(
      selected,
      PlacesEvent(Column(0, "")),
    ).0
  assert_eq(changed.geo, initial_geo())
  assert_false(changed.places.show)
  assert_eq(
    imported_outputs_transition(changed, GeoEvent(Export(true))).1,
    None,
  )
  let key = selected.selection.unwrap()
  for
    event in [
      ChooseImportedBook(selected.book_handle),
      ChooseImportedOutput(selected.artifact_id),
      ChooseImportedFile(key.path),
      RefreshImportedOutputs,
      CloseImportedOutputs,
      OpenImportedOutputs,
    ] {
    let next = imported_outputs_transition(selected, event).0
    assert_eq(next.places, initial_places())
    assert_eq(next.geo, initial_geo())
    let stale = imported_outputs_transition(
        next,
        ImportedTextLoaded(
          selected.generation,
          key,
          imported_fixture_reply(key, "Name,Lat,Lon,Type\nBad,0,0,bad\n"),
        ),
      ).0
    assert_eq(stale, next)
    assert_eq(
      imported_outputs_transition(next, GeoEvent(Export(false))).1,
      None,
    )
  }
  assert_eq(
    imported_outputs_transition(
      initial_imported_outputs_state(),
      PlacesEvent(Explore),
    ).0,
    initial_imported_outputs_state(),
  )
}
