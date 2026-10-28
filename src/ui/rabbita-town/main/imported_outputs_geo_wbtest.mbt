///|
fn imported_geo_fixture(
  content : String,
  filename~ : String = "places.geojson",
  mime~ : String = "application/octet-stream",
) -> ImportedOutputsState raise {
  let selection : @imported_output_contract.Selection = {
    book_handle: "book-" + "1".repeat(64),
    package_sha256: imported_fixture_digest("c"),
    manifest_sha256: imported_fixture_digest("d"),
    artifact_id: "result",
    path: "portable/outputs/result/" + filename,
    digest: "sha256:" + table_test_digest(content),
    size_bytes: @utf8.encode(content).length(),
  }
  let catalog = imported_download_synthetic_catalog(selection).replace(
    old="application/octet-stream",
    new=mime,
  )
  let base = imported_download_pending_from_catalog(catalog, selection).imported_outputs
  imported_outputs_transition(
    base,
    ImportedTextLoaded(
      base.generation,
      selection,
      imported_fixture_reply(selection, content),
    ),
  ).0
}

///|
fn imported_geo_content() -> String {
  let value : Json = {
    "type": "FeatureCollection",
    "features": [
      {
        "type": "Feature",
        "id": "gate-1",
        "properties": {
          "name": "North gate",
          "category": "venue",
          "note": "Keep this evidence",
        },
        "geometry": { "type": "Point", "coordinates": [116.2, 40.1, 21] },
      },
      {
        "type": "Feature",
        "id": "walk-1",
        "properties": { "name": "River walk", "category": "tour" },
        "geometry": {
          "type": "LineString",
          "coordinates": [[116.1, 40.0], [116.2, 40.1]],
        },
      },
    ],
  }
  value.stringify()
}

///|
test "GeoJSON explorer filters selects preserves source and exports local files" {
  let state = imported_geo_fixture(imported_geo_content())
  assert_true(state.geo.features is Some(Ok(_)))
  let html = imported_fixture_render(state)
  assert_true(html.contains("GeoJSON places and routes"))
  assert_true(html.contains("2 of 2 source features"))
  assert_true(html.contains("<svg"))
  assert_true(html.contains("<circle"))
  assert_true(html.contains("<polyline"))
  assert_true(html.contains("dateline wrapping is not modeled"))
  assert_true(html.contains("Download exact file"))
  let place = imported_outputs_transition(state, GeoEvent(Kind("Point"))).0
  let place = imported_outputs_transition(place, GeoEvent(Query("VENUE"))).0
  assert_true(imported_fixture_render(place).contains("1 of 2 source features"))
  let selected = imported_outputs_transition(place, GeoEvent(SelectMatching)).0
  assert_eq(selected.geo.selected, [0])
  guard imported_outputs_transition(selected, GeoEvent(Export(false))).1
    is Some(SaveFilteredTable(raw, name)) else {
    fail("GeoJSON export")
  }
  assert_eq(name, "selected-places.geojson")
  guard @imported_output_contract.parse_geojson(raw) is Ok(features) else {
    fail("Selected GeoJSON")
  }
  assert_eq(features.length(), 1)
  assert_true(raw.contains("gate-1"))
  assert_true(raw.contains("Keep this evidence"))
  assert_true(raw.contains("21"))
  assert_false(raw.contains("River walk"))
  guard imported_outputs_transition(selected, GeoEvent(Export(true))).1
    is Some(SaveFilteredTable(csv, csv_name)) else {
    fail("CSV export")
  }
  assert_eq(csv_name, "selected-places.csv")
  assert_true(csv.contains("North gate"))
  assert_false(csv.contains("River walk"))
  let hidden = imported_outputs_transition(selected, GeoEvent(Query("missing"))).0
  assert_eq(hidden.geo.selected, [0])
  assert_true(
    imported_fixture_render(hidden).contains("No source features match"),
  )
  assert_true(
    imported_outputs_transition(hidden, GeoEvent(Export(false))).1 is Some(_),
  )
  let both = imported_outputs_transition(selected, GeoEvent(Toggle(1))).0
  assert_eq(both.geo.selected, [0, 1])
  assert_eq(
    imported_outputs_transition(both, GeoEvent(Toggle(0))).0.geo.selected,
    [1],
  )
  assert_eq(imported_outputs_transition(both, GeoEvent(Clear)).0.geo.selected, [])
  let raw_view = imported_outputs_transition(selected, GeoEvent(Raw)).0
  assert_true(imported_fixture_render(raw_view).contains("FeatureCollection"))
  assert_false(imported_fixture_render(raw_view).contains("<svg"))
  assert_eq(
    imported_outputs_transition(selected, GeoEvent(Toggle(-1))).0,
    selected,
  )
  assert_eq(
    imported_outputs_transition(selected, GeoEvent(Toggle(2))).0,
    selected,
  )
  assert_eq(
    imported_outputs_transition(selected, GeoEvent(Kind("MultiPolygon"))).0,
    selected,
  )
  assert_eq(imported_outputs_transition(state, GeoEvent(Export(false))).1, None)
}

///|
test "GeoJSON lifecycle resets state and rejects stale or mismatched verified responses" {
  let content = imported_geo_content()
  let state = imported_geo_fixture(content)
  let selected = imported_outputs_transition(state, GeoEvent(SelectMatching)).0
  let key = state.selection.unwrap()
  for
    event in [
      ChooseImportedBook(state.book_handle),
      ChooseImportedOutput(state.artifact_id),
      ChooseImportedFile(key.path),
      RefreshImportedOutputs,
      CloseImportedOutputs,
      OpenImportedOutputs,
    ] {
    let changed = imported_outputs_transition(selected, event).0
    assert_eq(changed.geo, initial_geo())
    assert_eq(
      imported_outputs_transition(changed, GeoEvent(Export(true))).1,
      None,
    )
    let late = imported_outputs_transition(
        changed,
        ImportedTextLoaded(
          state.generation,
          key,
          imported_fixture_reply(key, content),
        ),
      ).0
    assert_eq(late, changed)
  }
  let pending = imported_outputs_transition(
      selected,
      ChooseImportedFile(key.path),
    ).0
  let wrong_content = content.replace(old="North gate", new="South gate")
  let failed = imported_outputs_transition(
      pending,
      ImportedTextLoaded(
        pending.generation,
        key,
        imported_fixture_reply(key, wrong_content),
      ),
    ).0
  assert_true(failed.text is TextUnavailable(_))
  assert_eq(failed.geo, initial_geo())
  let mismatched = { ..key, digest: imported_fixture_digest("a"), }
  let failed = imported_outputs_transition(
      pending,
      ImportedTextLoaded(
        pending.generation,
        key,
        imported_fixture_reply(mismatched, content),
      ),
    ).0
  assert_true(failed.text is TextUnavailable(_))
  assert_eq(failed.geo, initial_geo())
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let (_, opened) = update(
    dispatch,
    ImportedOutputsEvent(OpenImportedOutputs),
    init_model(),
  )
  let model = { ..opened, imported_outputs: selected, }
  let (_, dismissed) = update(dispatch, TogglePhone, model)
  assert_eq(dismissed.imported_outputs.geo, initial_geo())
  let (command, after) = update(
    dispatch,
    ImportedOutputsEvent(GeoEvent(Export(false))),
    dismissed,
  )
  let scheduler = ImportedSurfaceScheduler::{ effects: 0, }
  @cmd.Scheduler::add(scheduler, command)
  assert_eq(scheduler.effects, 0)
  assert_eq(after.imported_outputs.geo, initial_geo())
}

///|
test "GeoJSON MIME recognition raw fallbacks and inert property rendering" {
  let by_mime = imported_geo_fixture(
    imported_geo_content(),
    filename="source.json",
    mime="application/geo+json; charset=utf-8",
  )
  assert_true(by_mime.geo.features is Some(Ok(_)))
  let ordinary = imported_geo_fixture(
    imported_geo_content(),
    filename="source.json",
    mime="application/json",
  )
  assert_eq(ordinary.geo, initial_geo())
  assert_true(imported_fixture_render(ordinary).contains("Verified full text"))
  for
    bad in [
      "broken", "{\"type\":\"FeatureCollection\",\"features\":[{\"type\":\"Feature\",\"geometry\":{\"type\":\"Polygon\",\"coordinates\":[]}}]}",
    ] {
    let malformed = imported_geo_fixture(bad)
    assert_true(malformed.geo.features is Some(Err(_)))
    let html = imported_fixture_render(malformed)
    assert_true(html.contains("GeoJSON explorer unavailable"))
    assert_true(html.contains("Verified raw GeoJSON"))
    assert_true(html.contains("Download exact file"))
    assert_eq(
      imported_outputs_transition(malformed, GeoEvent(Export(false))).1,
      None,
    )
  }
  let unsafe_text = imported_geo_content()
    .replace(old="North gate", new="<script>alert(1)</script>")
    .replace(old="venue", new="javascript:alert(1)")
  let html = imported_fixture_render(imported_geo_fixture(unsafe_text))
  assert_true(html.contains("&lt;script&gt;"))
  assert_false(html.contains("<script>"))
  assert_false(html.contains("href=\"javascript:"))
  assert_false(html.contains("src=\"http"))
  let empty = imported_geo_fixture(
    "{\"type\":\"FeatureCollection\",\"features\":[]}",
  )
  assert_true(
    imported_fixture_render(empty).contains("contains no source features"),
  )
}

///|
test "GeoJSON feature pagination and whole-feature schematic caps keep exports complete" {
  let source : Array[Json] = []
  for index in 0..<130 {
    source.push({
      "type": "Feature",
      "properties": { "name": "Place " + index.to_string() },
      "geometry": { "type": "Point", "coordinates": [116, 40] },
    })
  }
  let collection : Json = {
    "type": "FeatureCollection",
    "features": source.to_json(),
  }
  let state = imported_geo_fixture(collection.stringify())
  let html = imported_fixture_render(state)
  assert_true(html.contains("100 of 130 matching features"))
  assert_true(html.contains("Place 24"))
  assert_false(html.contains("Place 25"))
  let page = imported_outputs_transition(state, GeoEvent(Page(1))).0
  assert_true(imported_fixture_render(page).contains("Place 25"))
  assert_false(imported_fixture_render(page).contains("Place 24"))
  assert_eq(
    imported_outputs_transition(page, GeoEvent(Query("Place"))).0.geo.page,
    0,
  )
  assert_eq(
    imported_outputs_transition(page, GeoEvent(Kind("Point"))).0.geo.page,
    0,
  )
  assert_eq(imported_outputs_transition(page, GeoEvent(Page(99))).0, page)
  assert_eq(imported_outputs_transition(page, GeoEvent(Page(-1))).0, page)
  let selected = imported_outputs_transition(page, GeoEvent(SelectMatching)).0
  assert_eq(selected.geo.selected.length(), 130)
  guard imported_outputs_transition(selected, GeoEvent(Export(false))).1
    is Some(SaveFilteredTable(raw, _)) else {
    fail("All-feature export")
  }
  guard @imported_output_contract.parse_geojson(raw) is Ok(exported) else {
    fail("All-feature parsing")
  }
  assert_eq(exported.length(), 130)
  let many_points : Array[@imported_output_contract.GeoPoint] = []
  for _ in 0..<2001 {
    many_points.push({ longitude: 0.0, latitude: 0.0, })
  }
  let long_line = { ..exported[0], kind: "LineString", points: many_points, }
  assert_eq(geo_schematic_indices([long_line, exported[0]], [0, 1]), [1])
  assert_eq(geo_schematic_indices([long_line], [0]), [])
}
