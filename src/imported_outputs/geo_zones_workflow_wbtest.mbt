///|
async test "imported zone HTTP response supports spatial selection without changing source" {
  let content = "{\"type\":\"FeatureCollection\",\"features\":[{\"type\":\"Feature\",\"id\":\"zone\",\"properties\":{\"name\":\"District\"},\"geometry\":{\"type\":\"Polygon\",\"coordinates\":[[[0,0],[4,0],[4,4],[0,4],[0,0]],[[1,1],[2,1],[2,2],[1,2],[1,1]]]}},{\"type\":\"Feature\",\"id\":\"welcome\",\"properties\":{\"name\":\"Welcome\"},\"geometry\":{\"type\":\"Point\",\"coordinates\":[3,3]}},{\"type\":\"Feature\",\"properties\":{\"name\":\"Courtyard\"},\"geometry\":{\"type\":\"Point\",\"coordinates\":[1.5,1.5]}}]}"
  let bytes = @utf8.encode(content)
  let (home, root, selection) = fixture(
    bytes,
    filename="district.geojson",
    mime="application/geo+json",
  )
  defer @fs.rmdir(home, recursive=true)
  let catalog_path = home + "/missing-catalog.json"
  assert_eq(discover(catalog_path, home).books.length(), 1)
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
  let selected = @contract.geo_places_in_zone(features, 0)
  assert_eq(selected, [1])
  assert_eq(
    @contract.parse_geojson(@contract.geojson_selection(features, selected)).unwrap(),
    [features[1]],
  )
  let zone_copy = @contract.parse_geojson(
    @contract.geojson_selection(features, [0]),
  ).unwrap()
  assert_eq(@contract.geo_rings(zone_copy[0]).length(), 2)
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
