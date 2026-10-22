///|
test "gzip negotiation respects explicit refusal and token boundaries" {
  assert_true(accepts_gzip("br, gzip"))
  assert_true(accepts_gzip("gzip;q=0.5, br"))
  assert_false(accepts_gzip("gzip;q=0"))
  assert_false(accepts_gzip("gzip;q=0.0"))
  assert_false(accepts_gzip("notgzip"))
  assert_false(accepts_gzip("gzip;q=garbage"))
}

///|
test "cache scope excludes runtime and private reports" {
  assert_true(cacheable_product_asset("main.js"))
  assert_true(
    cacheable_product_asset("landmark-studio/town-projections/manifest.json"),
  )
  assert_true(cacheable_product_asset("tilemap/wenyu_reference_buildings.json"))
  assert_false(cacheable_product_asset("town.json"))
  assert_false(cacheable_product_asset("secret-compute-room.json"))
  assert_false(cacheable_product_asset("tilemap/modules/moondesk-handoff.json"))
  assert_false(cacheable_product_asset("index.html"))
  assert_false(cacheable_product_asset("main.js.gz"))
}

///|
test "conditional requests accept lists and weak comparison" {
  assert_true(etag_matches("\"old\", W/\"new\"", "\"new\""))
  assert_true(etag_matches("*", "\"new\""))
  assert_false(etag_matches("\"old\"", "\"new\""))
  assert_false(etag_matches("", "\"new\""))
}
