///|
extern "js" fn reference_tile_code_at(grid_x : Int, grid_y : Int) -> String =
  #| (gridX, gridY) => globalThis.__wenyuReferenceLabels?.rows?.[gridY]?.[gridX] || ""

///|
extern "js" fn reference_tile_snapshot_ready() -> Bool =
  #| () => Array.isArray(globalThis.__wenyuReferenceLabels?.rows)

///|
extern "js" fn reference_road_graph_code_at(
  grid_x : Int,
  grid_y : Int,
) -> String =
  #| (gridX, gridY) => globalThis.__wenyuReferenceRoadGraph?.rows?.[gridY]?.[gridX] || ""

///|
extern "js" fn reference_road_graph_snapshot_ready() -> Bool =
  #| () => (
  #|   globalThis.__wenyuReferenceRoadGraph?.schema ===
  #|     "moontown.wenyu_road_graph.v1" &&
  #|   Array.isArray(globalThis.__wenyuReferenceRoadGraph?.rows)
  #| )
