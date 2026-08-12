///|
/// A presentation chunk groups tile traversal only. The semantic world keeps
/// one independently editable cell for every road, tree, and building tile.
priv struct GoldenCanvasTileChunk {
  min_x : Int
  max_x : Int
  min_y : Int
  max_y : Int
} derive(Debug, Eq)

///|
let golden_canvas_tile_chunk_size = 16

///|
let golden_canvas_cull_margin = 160.0

///|
fn golden_canvas_world_at_screen(
  screen_x : Double,
  screen_y : Double,
  viewport_width : Int,
  viewport_height : Int,
  camera_x : Double,
  camera_y : Double,
  zoom : Double,
) -> (Double, Double) {
  let safe_zoom = zoom.max(0.01)
  let projected_difference = (screen_x - viewport_width.to_double() / 2.0) /
    safe_zoom +
    camera_x
  let projected_sum = (screen_y - viewport_height.to_double() / 2.0) / safe_zoom +
    camera_y
  (
    (projected_difference / 32.0 + projected_sum / 16.0) / 2.0,
    (projected_sum / 16.0 - projected_difference / 32.0) / 2.0,
  )
}

///|
fn golden_canvas_visible_tile_chunks(
  cols : Int,
  rows : Int,
  viewport_width : Int,
  viewport_height : Int,
  camera_x : Double,
  camera_y : Double,
  zoom : Double,
) -> Array[GoldenCanvasTileChunk] {
  if cols <= 0 || rows <= 0 {
    return []
  }
  let margin = golden_canvas_cull_margin
  let corners = [
    golden_canvas_world_at_screen(
      -margin,
      -margin,
      viewport_width,
      viewport_height,
      camera_x,
      camera_y,
      zoom,
    ),
    golden_canvas_world_at_screen(
      viewport_width.to_double() + margin,
      -margin,
      viewport_width,
      viewport_height,
      camera_x,
      camera_y,
      zoom,
    ),
    golden_canvas_world_at_screen(
      -margin,
      viewport_height.to_double() + margin,
      viewport_width,
      viewport_height,
      camera_x,
      camera_y,
      zoom,
    ),
    golden_canvas_world_at_screen(
      viewport_width.to_double() + margin,
      viewport_height.to_double() + margin,
      viewport_width,
      viewport_height,
      camera_x,
      camera_y,
      zoom,
    ),
  ]
  let mut minimum_x = corners[0].0
  let mut maximum_x = corners[0].0
  let mut minimum_y = corners[0].1
  let mut maximum_y = corners[0].1
  for point in corners {
    minimum_x = minimum_x.min(point.0)
    maximum_x = maximum_x.max(point.0)
    minimum_y = minimum_y.min(point.1)
    maximum_y = maximum_y.max(point.1)
  }
  let min_x = (minimum_x.floor().to_int() - 2).clamp(min=0, max=cols)
  let max_x = (maximum_x.ceil().to_int() + 3).clamp(min=0, max=cols)
  let min_y = (minimum_y.floor().to_int() - 2).clamp(min=0, max=rows)
  let max_y = (maximum_y.ceil().to_int() + 3).clamp(min=0, max=rows)
  if min_x >= max_x || min_y >= max_y {
    return []
  }
  let chunk_size = golden_canvas_tile_chunk_size
  let first_chunk_x = min_x / chunk_size
  let final_chunk_x = (max_x - 1) / chunk_size
  let first_chunk_y = min_y / chunk_size
  let final_chunk_y = (max_y - 1) / chunk_size
  let chunks : Array[GoldenCanvasTileChunk] = []
  for chunk_y in first_chunk_y..<=final_chunk_y {
    for chunk_x in first_chunk_x..<=final_chunk_x {
      chunks.push({
        min_x: min_x.max(chunk_x * chunk_size),
        max_x: max_x.min((chunk_x + 1) * chunk_size),
        min_y: min_y.max(chunk_y * chunk_size),
        max_y: max_y.min((chunk_y + 1) * chunk_size),
      })
    }
  }
  chunks
}

///|
fn golden_canvas_chunk_tile_count(chunks : Array[GoldenCanvasTileChunk]) -> Int {
  let mut count = 0
  for chunk in chunks {
    count += (chunk.max_x - chunk.min_x) * (chunk.max_y - chunk.min_y)
  }
  count
}
