///|
fn min_int(left : Int, right : Int) -> Int {
  if left < right {
    left
  } else {
    right
  }
}

///|
fn max_int(left : Int, right : Int) -> Int {
  if left > right {
    left
  } else {
    right
  }
}

///|
fn module_road_hub_x() -> Int {
  128
}

///|
fn module_road_hub_y() -> Int {
  82
}

///|
fn module_road_tile(
  grid_x : Int,
  grid_y : Int,
  class_suffix : String,
) -> @rabbita.Html {
  let style = [
    "left: \{iso_tile_left(clamp_visual_grid_x(grid_x), clamp_visual_grid_y(grid_y))}px",
    "top: \{iso_tile_top(clamp_visual_grid_x(grid_x), clamp_visual_grid_y(grid_y))}px",
  ]
  span(
    class="module-road-tile module-road-\{class_suffix}",
    style~,
    no_children(),
  )
}

///|
fn render_module_road_for(civic : WenyuTownModule) -> Array[@rabbita.Html] {
  let tiles : Array[@rabbita.Html] = []
  let hub_x = module_road_hub_x()
  let hub_y = module_road_hub_y()
  let x_start = min_int(civic.entrance_x, hub_x)
  let x_end = max_int(civic.entrance_x, hub_x)
  let y_start = min_int(civic.entrance_y, hub_y)
  let y_end = max_int(civic.entrance_y, hub_y)
  for x in x_start..<=x_end {
    if (x - x_start) % 2 == 0 {
      tiles.push(module_road_tile(x, civic.entrance_y, "local"))
    }
  }
  for y in y_start..<=y_end {
    if (y - y_start) % 2 == 0 {
      tiles.push(module_road_tile(hub_x, y, "local"))
    }
  }
  tiles.push(module_road_tile(civic.entrance_x, civic.entrance_y, "entrance"))
  tiles
}

///|
fn render_wenyu_module_road_layer() -> @rabbita.Html {
  if !standalone_viewport_requested() {
    return div(class="wenyu-road-layer wenyu-road-layer-empty", no_children())
  }
  let children : Array[@rabbita.Html] = [
    module_road_tile(module_road_hub_x(), module_road_hub_y(), "hub"),
  ]
  for civic in wenyu_modules() {
    for tile in render_module_road_for(civic) {
      children.push(tile)
    }
  }
  div(class="wenyu-road-layer", children)
}
