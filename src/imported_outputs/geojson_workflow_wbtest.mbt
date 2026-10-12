///|
async test "imported GeoJSON discover digest bound text filter export and exact original" {
  let content = "{\"type\":\"FeatureCollection\",\"features\":[{\"type\":\"Feature\",\"id\":\"welcome\",\"properties\":{\"name\":\"Welcome Pavilion\",\"category\":\"reception\"},\"geometry\":{\"type\":\"Point\",\"coordinates\":[116.45,40.08]}},{\"type\":\"Feature\",\"properties\":{\"name\":\"Cafe\",\"category\":\"social\"},\"geometry\":{\"type\":\"Point\",\"coordinates\":[116.46,40.09]}}]}"
  let bytes = @utf8.encode(content)
  let (home, root, selection) = fixture(
    bytes,
    filename="valley.geojson",
    mime="application/geo+json",
  )
  defer @fs.rmdir(home, recursive=true)
  let catalog_path = home + "/missing-catalog.json"
  let catalog = discover(catalog_path, home)
  assert_true(
    @contract.geojson_file(
      selection.path,
      catalog.books[0].outputs[0].mime_type,
    ),
  )
  let response = respond(
    "GET",
    @contract.content_path(selection, mode="text"),
    catalog_path,
    home,
  )
  assert_eq(response.status, 200)
  let reply = @contract.parse_text_reply(@utf8.decode(response.body)).unwrap()
  assert_eq(reply.selection, selection)
  let features = @contract.parse_geojson(reply.content.unwrap()).unwrap()
  let selected = @contract.geo_matches(features, "reception", "Point")
  assert_eq(selected, [0])
  assert_eq(
    @contract.parse_geojson(@contract.geojson_selection(features, selected)).unwrap(),
    [features[0]],
  )
  assert_eq(
    @contract.parse_data_table(@contract.geo_csv(features, selected), ',').unwrap().rows.length(),
    1,
  )
  assert_eq(
    respond(
      "GET",
      @contract.content_path(selection, mode="download"),
      catalog_path,
      home,
    ).body,
    bytes,
  )
  assert_eq(@fs.read_file(root + "/" + selection.path).binary(), bytes)
  assert_false(@fs.exists(catalog_path))
}
