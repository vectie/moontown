///|
test "generic dashboard does not embed Wenyu district assets" {
  assert_true(
    dynamic_book_asset_keys(0) ==
    ["book-house-coding", "book-house-coding-roof", "keeper-claw"],
  )
  assert_true(
    dynamic_book_asset_keys(1) ==
    ["book-house-finance", "book-house-finance-roof", "keeper-claw"],
  )
}

///|
test "generic dashboard scene layout leaves Wenyu assets to tilemap modules" {
  let layout = default_town_scene_layout()
  assert_false(
    layout.assets.any(fn(asset) {
      asset.key.has_prefix("district-") ||
      asset.path.contains("tilemap/districts/")
    }),
  )
}
