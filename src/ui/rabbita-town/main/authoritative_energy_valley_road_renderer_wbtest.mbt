///|
test "authoritative transport culling rejects offscreen bounds" {
  assert_true(
    authoritative_energy_valley_transport_record_visible(
      0, 0, 1000, 1000, 0.0, 0.0, 1.0, 800, 600, 0.0,
    ),
  )
  assert_false(
    authoritative_energy_valley_transport_record_visible(
      200000, 120000, 210000, 130000, 0.0, 0.0, 1.0, 800, 600, 24.0,
    ),
  )
}

///|
test "transport building masks preserve exact town footprints" {
  let masks = authoritative_energy_valley_transport_building_masks_json([
    {
      place_id: ecosystem_contract_scoped_id("place", "place-a"),
      name: "A",
      style: "civic",
      x: 12,
      y: 34,
      width: 5,
      depth: 6,
      entrance_x: None,
      entrance_y: None,
      floors: 3,
      interior_seed: 1,
      module_key: Some("module-a"),
      authored_id: None,
    },
  ])
  assert_eq(masks, "[[12,34,5,6]]")
}
