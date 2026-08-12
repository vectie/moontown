///|
test "canvas mega tiles cull the invisible majority of the civic world" {
  let chunks = golden_canvas_visible_tile_chunks(
    256, 144, 1280, 656, 1792.0, 3200.0, 0.42,
  )
  let visible_tiles = golden_canvas_chunk_tile_count(chunks)
  assert_true(chunks.length() > 1)
  assert_true(visible_tiles > 0)
  assert_true(visible_tiles < 256 * 144 * 3 / 5)
}

///|
test "canvas chunk traversal retains tile-level boundaries" {
  let chunks = golden_canvas_visible_tile_chunks(
    256, 144, 1280, 656, 1792.0, 3200.0, 0.42,
  )
  for chunk in chunks {
    assert_true(chunk.min_x >= 0)
    assert_true(chunk.max_x <= 256)
    assert_true(chunk.min_y >= 0)
    assert_true(chunk.max_y <= 144)
    assert_true(chunk.max_x - chunk.min_x <= golden_canvas_tile_chunk_size)
    assert_true(chunk.max_y - chunk.min_y <= golden_canvas_tile_chunk_size)
  }
}

///|
test "canvas chunk traversal handles an entirely off-world camera" {
  let chunks = golden_canvas_visible_tile_chunks(
    256, 144, 1280, 656, -100000.0, -100000.0, 0.42,
  )
  assert_eq(chunks, [])
  assert_eq(golden_canvas_chunk_tile_count(chunks), 0)
}
