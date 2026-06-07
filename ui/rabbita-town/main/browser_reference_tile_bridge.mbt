///|
extern "js" fn reference_tile_code_at(grid_x : Int, grid_y : Int) -> String =
  #| (gridX, gridY) => globalThis.__wenyuReferenceLabels?.rows?.[gridY]?.[gridX] || ""
