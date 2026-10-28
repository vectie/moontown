///|
test "public QR opens neighborhood without hijacking spatial links" {
  assert_true(neighborhood_route_requested(true, "", "", "", "", ""))
  assert_false(neighborhood_route_requested(false, "", "", "", "", ""))
  assert_true(neighborhood_route_requested(false, "1", "", "", "", ""))
  assert_false(neighborhood_route_requested(true, "0", "", "", "", ""))
  assert_false(neighborhood_route_requested(true, "", "compute", "", "", ""))
  assert_false(neighborhood_route_requested(true, "", "indoor", "", "", ""))
  assert_false(neighborhood_route_requested(true, "", "", "outcomes", "", ""))
  assert_false(neighborhood_route_requested(true, "", "", "", "social", ""))
  assert_false(neighborhood_route_requested(true, "", "", "", "", "dashboard"))
}
